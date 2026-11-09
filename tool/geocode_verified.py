#!/usr/bin/env python3
"""One-time cached fiscal-address enrichment; never promote district/street centroids."""
import argparse,csv,io,json,re,time,unicodedata,threading,math
from pathlib import Path
from datetime import datetime,timezone
from concurrent.futures import ThreadPoolExecutor,as_completed
import requests
UA='NexoIndustrial/0.1 (one-time fiscal-address geocoding; https://github.com/Em3rc0d/nexo-industrial)'
GEO_URL='https://nominatim.openstreetmap.org/search'
UBIGEO_URL='https://raw.githubusercontent.com/jmcastagnetto/ubigeo-peru-aumentado/main/ubigeo_distrito.csv'
def norm(s):
 return re.sub(r'[^A-Z0-9 ]',' ',''.join(c for c in unicodedata.normalize('NFD',str(s or '').upper()) if not unicodedata.combining(c))).strip()
def tokens(s):
 return set(norm(s).split())-{'AV','AVENIDA','JR','JIRON','CALLE','CL','CAL','DE','DEL','LA','LAS','LOS','EL','PERU'}
def clean_address(address):
 s=norm(address)
 s=re.sub(r'\b(?:INT|INTERIOR|DPTO|DEPARTAMENTO|OF|OFICINA|PISO|URB|URBANIZACION|ETAPA)\b.*','',s).strip()
 s=re.sub(r'\b(?:NRO|NUMERO|NUM|N)\s*(\d+[A-Z]?)\b',r'\1',s)
 for pattern,replacement in [(r'^AV\s+','Avenida '),(r'^JR\s+','Jiron '),(r'^JRN\s+','Jiron '),(r'^(?:CL|CAL)\s+','Calle '),(r'^(?:PSJE|PJE)\s+','Pasaje ')]:s=re.sub(pattern,replacement,s)
 return re.sub(r'\s+',' ',s).strip()
def house_number(address):
 m=re.search(r'\b(?:NRO|NUMERO|NUM)\.?\s*([0-9]+[A-Z]?)\b',str(address).upper())
 return m.group(1) if m else None
def distance_km(a,b,c,d):
 r=math.pi/180;v=math.sin((c-a)*r/2)**2+math.cos(a*r)*math.cos(c*r)*math.sin((d-b)*r/2)**2
 return 6371*2*math.asin(min(1,math.sqrt(v)))
def validate_candidate(candidate,raw_address,geo):
 addr=candidate.get('address') or {}; number=house_number(raw_address)
 if candidate.get('place_rank',0)<30:return False,'not_address_level'
 if addr.get('country_code')!='pe':return False,'wrong_country'
 if not number or re.sub(r'^0+(?=\d)','',norm(addr.get('house_number')).replace(' ',''))!=re.sub(r'^0+(?=\d)','',norm(number).replace(' ','')):return False,'house_number_not_confirmed'
 road=addr.get('road') or addr.get('pedestrian') or addr.get('residential') or ''
 source=tokens(clean_address(raw_address))-set(norm(number).split()); target=tokens(road)
 if not target or len(source&target)/max(1,len(target))<0.6:return False,'street_mismatch'
 display=norm(candidate.get('display_name')); district=norm(geo.get('district'))
 aliases={'LURIGANCHO':'LURIGANCHO CHOSICA','CERCADO DE LIMA':'LIMA','CALLERIA':'PUCALLPA','CERCADO DE AREQUIPA':'AREQUIPA'}
 district_ok=district in display or aliases.get(district,'__NONE__') in display
 if not district_ok:return False,'district_mismatch'
 for key in ['province','department']:
  expected=norm(geo.get(key))
  if expected and expected not in display:return False,'administrative_mismatch'
 lat=float(candidate['lat']);lon=float(candidate['lon'])
 if not (-19<lat<1 and -82<lon<-68):return False,'outside_peru'
 if geo.get('latitude') is not None and distance_km(float(geo['latitude']),float(geo['longitude']),lat,lon)>100:return False,'far_from_expected_district'
 return True,'house_number_and_street_match'
def query_for_record(row):
 geo=row['geography'];raw=row.get('fiscal_address') or row.get('address_hq_verified') or ''
 fields=row.get('sunat',{}).get('address_fields',{})
 query_address=' '.join([fields.get('TIPO DE VÍA',''),fields.get('NOMBRE DE VÍA',''),'NRO',fields.get('NÚMERO','')]) if fields.get('NOMBRE DE VÍA') and fields.get('NÚMERO') else raw
 return ', '.join([clean_address(query_address),geo['district'],geo['province'],geo['department'],'Peru'])
def select_candidate(accepted):
 if len(accepted)<=1:return accepted
 buildings=[c for c in accepted if c.get('category')=='building']
 if len(buildings)==1:
  b=buildings[0];bb=list(map(float,b['boundingbox']))
  if all(bb[0]<=float(c['lat'])<=bb[1] and bb[2]<=float(c['lon'])<=bb[3] for c in accepted):return [b]
 if all(distance_km(float(a['lat']),float(a['lon']),float(b['lat']),float(b['lon']))<=0.015 for a in accepted for b in accepted):return [accepted[0]]
 return accepted
def write(path,payload):
 tmp=path.with_suffix(path.suffix+'.tmp');tmp.write_text(json.dumps(payload,ensure_ascii=False,indent=2));tmp.replace(path)
local=threading.local()
def session():
 if not hasattr(local,'session'):
  local.session=requests.Session();local.session.headers.update({'User-Agent':UA,'Accept':'application/json'})
 return local.session
def fetch_ruc(record,cache):
 ruc=str(record['ruc']);file=cache/(ruc+'.json')
 if file.exists():return ruc,json.loads(file.read_text())
 for attempt in range(3):
  try:
   response=session().get('https://openruc.com/api/ruc/'+ruc,timeout=25)
   if response.status_code==429:time.sleep(30);continue
   if response.status_code==404:result={'error':'not_found'}
   else:
    response.raise_for_status();result=response.json()
   if result.get('ruc') and str(result['ruc'])!=ruc:result={'error':'ruc_mismatch'}
   write(file,result);return ruc,result
  except requests.RequestException as e:
   if attempt==2:return ruc,{'error':str(e)[:150]}
   time.sleep(2*(attempt+1))
 return ruc,{'error':'rate_limited'}
def main():
 p=argparse.ArgumentParser();p.add_argument('--input',required=True,type=Path);p.add_argument('--output',required=True,type=Path);p.add_argument('--cache',required=True,type=Path);p.add_argument('--limit',type=int,default=0);args=p.parse_args()
 args.cache.mkdir(parents=True,exist_ok=True);rc=args.cache/'ruc';rc.mkdir(exist_ok=True);gc=args.cache/'nominatim';gc.mkdir(exist_ok=True)
 records=json.loads(args.input.read_text());records=records[:args.limit] if args.limit else records
 ubif=args.cache/'ubigeo.csv'
 if not ubif.exists():
  r=session().get(UBIGEO_URL,timeout=30);r.raise_for_status();ubif.write_text(r.text)
 ubis={r['inei']:r for r in csv.DictReader(io.StringIO(ubif.read_text()))}
 by_ruc={str(r['ruc']):r for r in records};stats={'total':len(records),'addresses':0,'attempted':0,'accepted':0,'pending':0,'errors':0}
 print('ENRICHING',len(records),flush=True)
 with ThreadPoolExecutor(max_workers=6) as pool:
  futures=[pool.submit(fetch_ruc,r,rc) for r in records]
  for i,f in enumerate(as_completed(futures),1):
   ruc,result=f.result();row=by_ruc[ruc];row['sunat']=result
   if result.get('direccion'):
    stats['addresses']+=1;row['fiscal_address']=result['direccion'];row['fiscal_address_source']=result.get('source_url','https://openruc.com/api/ruc/'+ruc);row['fiscal_address_as_of']=result.get('as_of')
    ubi=ubis.get(str(result.get('ubigeo')))
    if ubi:
     g=row['geography'];g['ubigeo']=ubi['inei'];g['department']=ubi['departamento'];g['province']=ubi['provincia'];g['district']=ubi['distrito'];g['latitude']=float(ubi['latitude']);g['longitude']=float(ubi['longitude'])
   else:stats['errors']+=1
   if i%50==0 or i==len(records):write(args.output,records);write(args.output.with_suffix('.summary.json'),stats);print('ADDRESSES',i,stats['addresses'],'errors',stats['errors'],flush=True)
 s=requests.Session();s.headers.update({'User-Agent':UA,'Accept':'application/json'});last=0
 for i,row in enumerate(records,1):
  raw=row.get('fiscal_address') or row.get('address_hq_verified') or '';geo=row['geography'];geo['district_reference']={k:geo[k] for k in ['latitude','longitude','ubigeo','district','province','department']}
  if not house_number(raw):geo['geocoding_status']='manual_review_no_street_number';stats['pending']+=1
  else:
   query=query_for_record(row)
   import hashlib
   cf=gc/(hashlib.sha256(query.encode()).hexdigest()+'.json')
   try:
    if cf.exists():candidates=json.loads(cf.read_text())
    else:
     time.sleep(max(0,1.15-(time.monotonic()-last)));last=time.monotonic()
     response=s.get(GEO_URL,params={'q':query,'format':'jsonv2','addressdetails':1,'countrycodes':'pe','limit':3},timeout=25)
     if response.status_code in [403,429]:
      geo['geocoding_status']='provider_rate_limited';write(args.output,records);print('PROVIDER_STOP',response.status_code,flush=True);break
     response.raise_for_status();candidates=response.json();write(cf,candidates)
    stats['attempted']+=1;accepted=[]
    for c in candidates:
     ok,reason=validate_candidate(c,raw,geo)
     if ok:accepted.append(c)
    accepted=select_candidate(accepted)
    if len(accepted)==1:
     c=accepted[0];geo.update(latitude=float(c['lat']),longitude=float(c['lon']),precision='address_geocoded',nearby_ranking_eligible=True,navigation_eligible=True,source='https://www.openstreetmap.org/'+c['osm_type']+'/'+str(c['osm_id']),geocoding_status='automatic_address_match',geocoder='nominatim',geocoded_at=datetime.now(timezone.utc).isoformat(),matched_address=c['display_name'],osm_type=c['osm_type'],osm_id=c['osm_id'],validation='house_number_and_street_and_district',site_type='fiscal_address_not_operational_site_verified');stats['accepted']+=1
    else:
     geo['geocoding_status']='manual_review_ambiguous' if len(accepted)>1 else 'no_address_level_match';stats['pending']+=1
   except (requests.RequestException,ValueError,KeyError) as e:geo['geocoding_status']='provider_error';geo['geocoding_error']=str(e)[:150];stats['errors']+=1
  if i%10==0 or i==len(records):
   write(args.output,records);write(args.output.with_suffix('.summary.json'),stats);print('GEOCODE',i,stats,flush=True)
 write(args.output,records);write(args.output.with_suffix('.summary.json'),stats);print('DONE',stats,flush=True)
if __name__=='__main__':main()
