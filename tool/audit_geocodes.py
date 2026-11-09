#!/usr/bin/env python3
"""Re-evaluate cached geocodes offline; no additional provider requests."""
import argparse,hashlib,json
from pathlib import Path
from datetime import datetime,timezone
from collections import Counter
from geocode_verified import house_number,query_for_record,validate_candidate,select_candidate,write
DISTRICT_SOURCE='https://github.com/jmcastagnetto/ubigeo-peru-aumentado/blob/main/ubigeo_distrito.csv'
def main():
 p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--cache',type=Path,required=True);a=p.parse_args();rows=json.loads(a.input.read_text());counts=Counter()
 if len(rows)!=1907 or len({r['ruc'] for r in rows})!=1907:raise ValueError('Portfolio must contain 1907 unique RUCs')
 for row in rows:
  geo=row['geography'];reference=geo.get('district_reference') or {k:geo[k] for k in ['latitude','longitude','ubigeo','district','province','department']};geo['district_reference']=reference
  raw=row.get('fiscal_address') or row.get('address_hq_verified') or '';query=query_for_record(row);path=a.cache/'nominatim'/(hashlib.sha256(query.encode()).hexdigest()+'.json');accepted=[]
  if not house_number(raw):status='manual_review_no_street_number'
  elif not path.exists():status='not_queried'
  else:
   candidates=json.loads(path.read_text());accepted=select_candidate([c for c in candidates if validate_candidate(c,raw,reference)[0]])
   status='automatic_address_match' if len(accepted)==1 else ('manual_review_ambiguous' if accepted else 'no_address_level_match')
  if len(accepted)==1:
   c=accepted[0];geo.update(latitude=float(c['lat']),longitude=float(c['lon']),precision='address_geocoded',nearby_ranking_eligible=True,navigation_eligible=True,source='https://www.openstreetmap.org/'+c['osm_type']+'/'+str(c['osm_id']),geocoding_status=status,geocoder='nominatim',geocoded_at=datetime.now(timezone.utc).isoformat(),matched_address=c['display_name'],osm_type=c['osm_type'],osm_id=c['osm_id'],validation='house_number_and_street_and_district_and_administration',site_type='fiscal_address_not_operational_site_verified')
  else:
   geo.update(latitude=reference['latitude'],longitude=reference['longitude'],precision='district_reference',nearby_ranking_eligible=False,navigation_eligible=False,source=DISTRICT_SOURCE,geocoding_status=status)
   for key in ['geocoder','matched_address','osm_type','osm_id','validation','site_type','geocoded_at']:geo.pop(key,None)
  counts[status]+=1
  if row.get('fiscal_address'):counts['addresses_enriched']+=1
  assert geo['navigation_eligible']==(geo['precision']=='address_geocoded')
 summary={'total_accounts':len(rows),'unique_rucs':len({r['ruc'] for r in rows}),'fiscal_addresses':counts['addresses_enriched'],'address_geocoded':counts['automatic_address_match'],'pending_exact_location':len(rows)-counts['automatic_address_match'],'statuses':dict(counts),'audited_at':datetime.now(timezone.utc).isoformat(),'address_source':'SUNAT padrón reducido 2026-11-09','geocoder_source':'OpenStreetMap / Nominatim','note':'Automatic fiscal-address match; operational site not verified in person.'}
 write(a.output,rows);write(a.output.with_suffix('.summary.json'),summary);print(json.dumps(summary,ensure_ascii=False,indent=2))
if __name__=='__main__':main()
