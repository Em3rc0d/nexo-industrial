#!/usr/bin/env python3
"""Cross existing SUNAT addresses with openly published municipal door geometries."""
import argparse,json,re,math,hashlib,time
from pathlib import Path
from datetime import datetime,timezone
from collections import defaultdict,Counter
import requests
from geocode_verified import norm,distance_km,write
MIR='https://www.idemil.gob.pe/geoportal/rest/services/Hosted/SHP_Municipalidad_de_Miraflores___Lima_08_07_2024/FeatureServer'
ICL='https://ide.icl.gob.pe:8443/geoserver/IDEP/'
TYPES={'AV':'AVENIDA','JR':'JIRON','JRN':'JIRON','CA':'CALLE','CL':'CALLE','CAL':'CALLE','PAS':'PASAJE','PSJE':'PASAJE','PJE':'PASAJE','PJ':'PASAJE','ML':'MALECON','MAL':'MALECON'}
def street_key(name,kind=''):
 words=norm(name).split();kind=TYPES.get(norm(kind),norm(kind))
 if words and (words[0] in TYPES or words[0] in TYPES.values()):kind=TYPES.get(words.pop(0),norm(name).split()[0])
 words=[{'GRAL':'GENERAL','CMDTE':'COMANDANTE','CRNL':'CORONEL','TTE':'TENIENTE'}.get(w,w) for w in words]
 return kind,' '.join(w for w in words if w not in ['DE','DEL','LA','LAS','LOS','EL'])
def code(v):
 v=str(v or '').strip();return str(int(v)) if v.isdigit() else v
class Sources:
 def __init__(self,path):
  self.path=path;path.mkdir(parents=True,exist_ok=True);self.s=requests.Session();self.s.headers['User-Agent']='NexoIndustrial/0.1 (existing fiscal-address matching; github.com/Em3rc0d/nexo-industrial)'
 def get(self,name,url,params):
  key=hashlib.sha256(json.dumps([url,params],sort_keys=True).encode()).hexdigest()[:16]
  p=self.path/(name.replace('.json','')+'-'+key+'.json')
  if p.exists():return json.loads(p.read_text())
  r=self.s.get(url,params=params,timeout=40);r.raise_for_status();d=r.json()
  if d.get('error') or 'ExceptionReport' in r.text:raise ValueError(str(d)[:200])
  write(p,d);return d
 def arcgis(self,name,layer,fields,where='1=1',geometry=False):
  out=[];offset=0
  while True:
   d=self.get(f'{name}-{offset}.json',MIR+'/'+str(layer)+'/query',{'f':'json','where':where,'outFields':fields,'returnGeometry':str(geometry).lower(),'outSR':4326,'resultOffset':offset,'resultRecordCount':2000,'orderByFields':'fid'})
   out.extend(d.get('features',[]))
   if not d.get('exceededTransferLimit'):break
   if not d.get('features'):raise ValueError('Empty municipal page')
   offset+=len(d['features'])
  return out
 def wfs(self,name,layer,filters=None):
  out=[];offset=0
  while True:
   params={'service':'WFS','version':'2.0.0','request':'GetFeature','typeNames':'IDEP:'+layer,'count':500,'startIndex':offset,'outputFormat':'application/json','srsName':'EPSG:4326'}
   if layer=='idep_tg_eje_via':params['propertyName']='cod_via,nombre'
   if filters:params['CQL_FILTER']=filters
   for attempt in range(3):
    try:
     d=self.get(name+'-'+str(offset),ICL+layer+'/wfs',params);break
    except requests.RequestException:
     if attempt==2:raise
     time.sleep(5*(attempt+1))
   fs=d.get('features',[]);out.extend(fs);offset+=len(fs)
   matched=d.get('numberMatched')
   if len(fs)<500 or (isinstance(matched,int) and offset>=matched):break
  return out

def prepare(rows,sources):
 targets={u:[r for r in rows if r['geography']['ubigeo']==u] for u in ['150101','150122']}
 mir_streets=sources.arcgis('miraflores-streets',1,'fid,cod_via,nomenclatu,tipo_abrev')
 try:icl_streets=sources.wfs('icl-streets.json','idep_tg_eje_via')
 except requests.RequestException as e:
  print('ICL_UNAVAILABLE',str(e)[:180],flush=True);icl_streets=[]
 maps={}
 for ubi,streets in [('150122',mir_streets),('150101',icl_streets)]:
  m=defaultdict(set)
  for f in streets:
   at=f.get('attributes') or f.get('properties');name=at.get('nomenclatu') or at.get('nombre');m[street_key(name,at.get('tipo_abrev',''))].add(code(at['cod_via']))
  maps[ubi]=m
 needed_by_ubi={}
 for ubi,rs in targets.items():
  needed={}
  for r in rs:
   fields=r['sunat'].get('address_fields',{});number=norm(fields.get('NÚMERO')).replace(' ','');key=street_key(fields.get('NOMBRE DE VÍA',''),fields.get('TIPO DE VÍA',''));codes=maps[ubi].get(key,set())
   if len(codes)==1 and re.fullmatch(r'\d+[A-Z]?',number):needed[r['ruc']]=(next(iter(codes)),code(number))
  needed_by_ubi[ubi]=needed
 result={}
 for ubi,needed in needed_by_ubi.items():
  if not needed:result[ubi]=[];continue
  numbers=sorted({n for _,n in needed.values()});codes=sorted({c for c,_ in needed.values()})
  def sql(values):return ','.join("'"+v.replace("'","''")+"'" for v in values)
  if ubi=='150122':fs=sources.arcgis('miraflores-doors',0,'fid,cod_via,nro_puerta,cod_lote,cod_manzan,letra_puer,SHAPE__Length',where='nro_puerta IN ('+sql(numbers)+')',geometry=True)
  else:
   try:fs=sources.wfs('icl-doors.json','idep_tg_puerta',"cod_via IN ("+sql([c.zfill(5) for c in codes])+") AND num_puerta IN ("+sql(numbers)+")")
   except requests.RequestException as e:
    print('ICL_DOORS_UNAVAILABLE',str(e)[:180],flush=True);fs=[]
  result[ubi]=fs
 return needed_by_ubi,result

def points(feature,ubi):
 if ubi=='150101':
  c=feature['geometry']['coordinates'];return [(float(c[1]),float(c[0]))]
 return [(float(c[1]),float(c[0])) for path in feature['geometry'].get('paths',[]) for c in path]
def main():
 p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path);p.add_argument('--cache',type=Path,required=True);p.add_argument('--download-only',action='store_true');a=p.parse_args();rows=json.loads(a.input.read_text());sources=Sources(a.cache);needed,features=prepare(rows,sources)
 print('MUNICIPAL_CANDIDATES', {k:len(v) for k,v in needed.items()}, 'features',{k:len(v) for k,v in features.items()},flush=True)
 if a.download_only:return
 if not a.output:p.error('--output required')
 idx={}
 for ubi,fs in features.items():
  group=defaultdict(list)
  for f in fs:
   at=f.get('attributes') or f.get('properties');n=at.get('nro_puerta') if ubi=='150122' else at.get('num_puerta');group[(code(at['cod_via']),code(n))].append(f)
  idx[ubi]=group
 added=0;overlap=0;conflicts=[]
 for row in rows:
  geo=row['geography'];ubi=geo['ubigeo'];key=needed.get(ubi,{}).get(row['ruc'])
  if not key:continue
  fs=idx[ubi].get(key,[]);ps=[p for f in fs for p in points(f,ubi)]
  if not ps:continue
  span=max(distance_km(*x,*y) for x in ps for y in ps)
  if span>0.03:continue
  lat=sum(x[0] for x in ps)/len(ps);lon=sum(x[1] for x in ps)/len(ps)
  ref=geo.get('district_reference',geo)
  if distance_km(float(ref['latitude']),float(ref['longitude']),lat,lon)>20:continue
  if geo.get('navigation_eligible') and distance_km(float(geo['latitude']),float(geo['longitude']),lat,lon)>0.1:
   conflicts.append(row['ruc'])
   geo['source_conflict']={'previous_point':[geo['latitude'],geo['longitude']],'previous_source':geo['source'],'municipal_point':[lat,lon],'municipal_source':MIR+'/0' if ubi=='150122' else ICL+'idep_tg_puerta/wfs'}
   geo.update(latitude=ref['latitude'],longitude=ref['longitude'],precision='district_reference',nearby_ranking_eligible=False,navigation_eligible=False,geocoding_status='manual_review_source_conflict')
   continue
  if geo.get('navigation_eligible'):overlap+=1
  else:added+=1
  url=MIR+'/0' if ubi=='150122' else ICL+'idep_tg_puerta/wfs'
  geo.update(latitude=lat,longitude=lon,precision='address_geocoded',nearby_ranking_eligible=True,navigation_eligible=True,source=url,geocoding_status='municipal_address_match',geocoder='Municipalidad de Miraflores / IDEMIL' if ubi=='150122' else 'Instituto Catastral de Lima',geocoded_at=datetime.now(timezone.utc).isoformat(),validation='municipal_street_code_and_door_number_and_district',site_type='fiscal_address_not_operational_site_verified',matched_address=row['fiscal_address'],municipal_evidence={'feature_ids':[f.get('id') or f.get('attributes',{}).get('fid') for f in fs],'street_code':key[0],'door_number':key[1],'geometry_span_m':round(span*1000,2),'method':'door_segment_vertex_mean' if ubi=='150122' else 'official_door_point','source_url':url})
 counts=Counter(r['geography'].get('geocoding_status','not_queried') for r in rows);accepted=sum(r['geography'].get('navigation_eligible',False) for r in rows)
 summary={'total_accounts':len(rows),'unique_rucs':len({r['ruc'] for r in rows}),'fiscal_addresses':sum(bool(r.get('fiscal_address')) for r in rows),'address_geocoded':accepted,'pending_exact_location':len(rows)-accepted,'municipal_added':added,'municipal_overlap':overlap,'municipal_conflicts_not_promoted':conflicts,'statuses':dict(counts),'audited_at':datetime.now(timezone.utc).isoformat()}
 write(a.output,rows);write(a.output.with_suffix('.summary.json'),summary);print(json.dumps(summary,ensure_ascii=False,indent=2),flush=True)
if __name__=='__main__':main()
