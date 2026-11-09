#!/usr/bin/env python3
"""Stream the official SUNAT archive; retain only RUCs in the existing portfolio."""
import argparse,hashlib,json,zipfile
from pathlib import Path
SOURCE='https://www2.sunat.gob.pe/padron_reducido_ruc.zip'
def main():
 p=argparse.ArgumentParser();p.add_argument('--archive',type=Path,required=True);p.add_argument('--input',type=Path,required=True);p.add_argument('--cache',type=Path,required=True);p.add_argument('--as-of',required=True);a=p.parse_args()
 accounts=json.loads(a.input.read_text());wanted={str(x['ruc']) for x in accounts};found=set();cache=a.cache/'ruc';cache.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(a.archive) as z:
  names=[n for n in z.namelist() if n.lower().endswith('.txt')]
  if len(names)!=1:raise ValueError('Expected one SUNAT TXT file')
  with z.open(names[0]) as raw:
   header=raw.readline().decode('latin1').strip().split('|')
   if header[0]!='RUC' or len(header)<15:raise ValueError('Unexpected SUNAT schema')
   for line in raw:
    ruc=line.split(b'|',1)[0].decode('ascii',errors='ignore')
    if ruc not in wanted:continue
    c=line.decode('latin1').rstrip().split('|');c=[v.strip() if v.strip() not in ['-','--','0','0000'] else '' for v in c];fields=dict(zip(header,c))
    parts=[fields.get('TIPO DE VÍA',''),fields.get('NOMBRE DE VÍA','')]
    for key,label in [('NÚMERO','NRO'),('INTERIOR','INT'),('LOTE','LOTE'),('DEPARTAMENTO','DPTO'),('MANZANA','MZA'),('KILÓMETRO','KM')]:
     if fields.get(key):parts.extend([label,fields[key]])
    parts.extend([fields.get('CÓDIGO DE ZONA',''),fields.get('TIPO DE ZONA','')])
    result={'ruc':ruc,'razon_social':c[1],'estado':c[2],'condicion':c[3],'ubigeo':c[4],'direccion':' '.join(x for x in parts if x),'source':'SUNAT','source_url':SOURCE,'as_of':a.as_of,'address_fields':fields}
    (cache/(ruc+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2));found.add(ruc)
    if found==wanted:break
 digest=hashlib.file_digest(a.archive.open('rb'),'sha256').hexdigest()
 summary={'matched':len(found),'missing':sorted(wanted-found),'source':SOURCE,'as_of':a.as_of,'archive_sha256':digest}
 (a.cache/'sunat_import_summary.json').write_text(json.dumps(summary,indent=2));print(json.dumps(summary,indent=2))
if __name__=='__main__':main()
