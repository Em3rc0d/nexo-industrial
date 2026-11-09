#!/usr/bin/env python3
import argparse, json, math, re, unicodedata
from collections import defaultdict, Counter
from datetime import datetime, timezone
from pathlib import Path
import osmium
from rapidfuzz.fuzz import token_set_ratio

STOP={'S','A','SA','SAC','SAA','SRL','EIRL','PERU','DEL','DE','LA','LAS','LOS','EL','Y','SOCIEDAD','ANONIMA','ANONIMO','CERRADA','ABIERTA','COMPANIA','COMPAÑIA','CORPORACION','CORPORACIÓN','SUCURSAL','EMPRESA','GRUPO','CONSORCIO','SERVICIOS','INVERSIONES'}
STREET_STOP={'AV','AVENIDA','JR','JIRON','JIRÓN','CAL','CALLE','CL','PSJE','PJE','PASAJE','PROLONGACION','PROLONGACIÓN','CAR','CARRETERA','AUTOPISTA','VIA','VÍA','DE','DEL','LA','LAS','LOS','EL'}
def norm(s):
 s=''.join(c for c in unicodedata.normalize('NFD',str(s or '').upper()) if not unicodedata.combining(c));s=re.sub(r'[^A-Z0-9 ]+',' ',s);return re.sub(r'\s+',' ',s).strip()
def norm_street(s):return ' '.join(w for w in norm(s).split() if w not in STREET_STOP)
def norm_name(s):return ' '.join(w for w in norm(s).split() if w not in STOP and len(w)>1)
def number_key(s):
 s=norm(s).replace(' ','')
 if not s or s in {'SN','S/N','SNN'}:return None
 m=re.match(r'^0*([0-9]+)([A-Z]?)$',s);return (str(int(m.group(1)))+m.group(2)) if m else None
def num_value(s):
 k=number_key(s)
 if not k:return None
 m=re.match(r'^(\d+)',k);return int(m.group(1)) if m else None
def hav(a,b,c,d):
 r=math.pi/180;x=math.sin((c-a)*r/2)**2+math.cos(a*r)*math.cos(c*r)*math.sin((d-b)*r/2)**2;return 6371*2*math.asin(min(1,math.sqrt(x)))
def center_node(n):
 try:return float(n.location.lat),float(n.location.lon)
 except Exception:return None
def center_way(w):
 pts=[]
 for n in w.nodes:
  try:
   if n.location.valid():pts.append((float(n.location.lat),float(n.location.lon)))
  except Exception:pass
 if not pts:return None
 return sum(x for x,_ in pts)/len(pts),sum(y for _,y in pts)/len(pts)
def osm_url(kind,oid):return f'https://www.openstreetmap.org/{kind}/{oid}'
class DeepHandler(osmium.SimpleHandler):
 def __init__(self,rows):
  super().__init__();self.rows=rows;self.targets={};self.by_number=defaultdict(list);self.target_streets=set();self.token_index=defaultdict(set);self.address_candidates=defaultdict(list);self.name_candidates=defaultdict(list);self.street_points=defaultdict(list);self.road_segments=defaultdict(list)
  for i,r in enumerate(rows):
   g=r.get('geography',{})
   if g.get('navigation_eligible'):continue
   f=r.get('sunat',{}).get('address_fields',{}) or {};street=' '.join(x for x in [f.get('TIPO DE VÍA',''),f.get('NOMBRE DE VÍA','')] if x).strip();st=norm_street(street);nk=number_key(f.get('NÚMERO'));ref=g.get('district_reference') or g
   try:refpt=(float(ref['latitude']),float(ref['longitude']))
   except Exception:continue
   nm=norm_name(r.get('name') or r.get('sunat',{}).get('razon_social'));self.targets[i]={'street':st,'number':nk,'number_value':num_value(nk),'ref':refpt,'name':nm}
   if nk and st:self.by_number[nk].append(i);self.target_streets.add(st)
   if nm:
    for t in [t for t in nm.split() if len(t)>=5]:self.token_index[t].add(i)
 def _process(self,tags,pt,kind,oid):
  if not pt:return
  lat,lon=pt
  if not (-19.5<lat<0.5 and -82.5<lon<-67.5):return
  street=norm_street(tags.get('addr:street') or tags.get('addr:place') or '');nk=number_key(tags.get('addr:housenumber'))
  if street and nk:
   nv=num_value(nk)
   if street in self.target_streets and nv is not None:self.street_points[street].append((nv,lat,lon,kind,oid,nk))
   for i in self.by_number.get(nk,[]):
    t=self.targets[i];sim=token_set_ratio(t['street'],street) if street else 0
    if sim<72:continue
    dist=hav(*t['ref'],lat,lon)
    if dist>35:continue
    self.address_candidates[i].append((sim-min(20,dist*.8),sim,dist,lat,lon,kind,oid,tags.get('addr:street',''),tags.get('addr:housenumber','')))
  nm=norm_name(tags.get('name') or tags.get('operator') or tags.get('brand') or '')
  if nm:
   cand=set()
   for t in [t for t in nm.split() if len(t)>=5]:cand.update(self.token_index.get(t,()))
   for i in cand:
    t=self.targets[i];sim=token_set_ratio(t['name'],nm)
    if sim<82:continue
    dist=hav(*t['ref'],lat,lon)
    if dist>30:continue
    ov=set(t['name'].split())&set(nm.split());longov=[x for x in ov if len(x)>=5]
    if len(longov)<min(2,max(1,len([x for x in t['name'].split() if len(x)>=5]))):continue
    self.name_candidates[i].append((sim-min(18,dist*.5),sim,dist,lat,lon,kind,oid,tags.get('name') or tags.get('operator') or tags.get('brand') or ''))
  if kind=='way' and tags.get('highway') and tags.get('name'):
   st=norm_street(tags.get('name'))
   if st in self.target_streets:self.road_segments[st].append((lat,lon,oid))
 def node(self,n):self._process(n.tags,center_node(n),'node',n.id)
 def way(self,w):self._process(w.tags,center_way(w),'way',w.id)
def best_unique(cands,sep_m=80):
 if not cands:return None
 c=sorted(cands,reverse=True,key=lambda x:x[0]);top=c[0]
 if len(c)==1:return top
 if hav(top[3],top[4],c[1][3],c[1][4])*1000<=sep_m:return top
 if top[0]-c[1][0]>=8:return top
 return None
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--input',type=Path,required=True);ap.add_argument('--pbf',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);ap.add_argument('--report',type=Path,required=True);a=ap.parse_args();rows=json.loads(a.input.read_text());h=DeepHandler(rows);h.apply_file(str(a.pbf),locations=True,idx='flex_mem');now=datetime.now(timezone.utc).isoformat();added=Counter();unresolved=[]
 for i,t in h.targets.items():
  r=rows[i];g=r['geography'];c=best_unique(h.address_candidates.get(i,[]))
  if c:
   score,sim,dist,lat,lon,kind,oid,street,hn=c;g.update(latitude=lat,longitude=lon,precision='address_geocoded',nearby_ranking_eligible=True,navigation_eligible=True,source=osm_url(kind,oid),geocoding_status='osm_offline_address_match',geocoder='OpenStreetMap PBF offline',geocoded_at=now,matched_address=f'{street} {hn}'.strip(),validation=f'house_number_exact_street_similarity_{sim:.0f}_district_distance_{dist:.2f}km',site_type='fiscal_address_not_operational_site_verified',osm_type=kind,osm_id=oid);added['address']+=1;continue
  c=best_unique(h.name_candidates.get(i,[]),sep_m=120)
  if c:
   score,sim,dist,lat,lon,kind,oid,name=c;g.update(latitude=lat,longitude=lon,precision='company_poi_geocoded',nearby_ranking_eligible=True,navigation_eligible=True,source=osm_url(kind,oid),geocoding_status='osm_offline_company_poi_match',geocoder='OpenStreetMap PBF offline',geocoded_at=now,matched_address=name,validation=f'company_name_similarity_{sim:.0f}_district_distance_{dist:.2f}km',site_type='company_poi_near_fiscal_district',osm_type=kind,osm_id=oid);added['company_poi']+=1;continue
  nv=t.get('number_value');st=t.get('street');pts=h.street_points.get(st,[])
  if nv is not None and len(pts)>=2:
   lower=sorted([p for p in pts if p[0]<=nv],key=lambda p:(nv-p[0],hav(*t['ref'],p[1],p[2])));upper=sorted([p for p in pts if p[0]>=nv],key=lambda p:(p[0]-nv,hav(*t['ref'],p[1],p[2])))
   if lower and upper and lower[0][0]!=upper[0][0]:
    lo,hi=lower[0],upper[0]
    if hav(lo[1],lo[2],hi[1],hi[2])<=2 and hav(*t['ref'],lo[1],lo[2])<=35 and hav(*t['ref'],hi[1],hi[2])<=35:
     frac=(nv-lo[0])/(hi[0]-lo[0]);lat=lo[1]+frac*(hi[1]-lo[1]);lon=lo[2]+frac*(hi[2]-lo[2]);g.update(latitude=lat,longitude=lon,precision='address_interpolated',nearby_ranking_eligible=True,navigation_eligible=False,source='https://www.openstreetmap.org/',geocoding_status='osm_offline_address_interpolated',geocoder='OpenStreetMap PBF offline',geocoded_at=now,validation=f'interpolated_between_house_numbers_{lo[0]}_{hi[0]}',site_type='fiscal_address_approximate');added['interpolated']+=1;continue
  segs=h.road_segments.get(st,[]) if st else []
  if segs:
   seg=min(segs,key=lambda p:hav(*t['ref'],p[0],p[1]))
   if hav(*t['ref'],seg[0],seg[1])<=35:g.update(latitude=seg[0],longitude=seg[1],precision='street_reference',nearby_ranking_eligible=False,navigation_eligible=False,source=osm_url('way',seg[2]),geocoding_status='osm_offline_street_reference',geocoder='OpenStreetMap PBF offline',geocoded_at=now,validation='street_name_match_nearest_segment_to_district_reference',site_type='street_reference_not_exact_address');added['street_reference']+=1;continue
  unresolved.append(r['ruc'])
 counts=Counter(r.get('geography',{}).get('precision') for r in rows);nav=sum(bool(r.get('geography',{}).get('navigation_eligible')) for r in rows);report={'total':len(rows),'unique_rucs':len({str(r['ruc']) for r in rows}),'previous_navigation_eligible':len(rows)-len(h.targets),'added':dict(added),'navigation_eligible_after':nav,'pending_navigation_exact':len(rows)-nav,'precision':dict(counts),'unresolved_rucs':unresolved,'generated_at':now,'osm_source':'https://download.geofabrik.de/south-america/peru-latest.osm.pbf'};a.output.write_text(json.dumps(rows,ensure_ascii=False,indent=2));a.report.write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps({k:v for k,v in report.items() if k!='unresolved_rucs'},ensure_ascii=False,indent=2))
if __name__=='__main__':main()
