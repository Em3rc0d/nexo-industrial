# Geolocalización de cuentas

## Datos y evidencia

El archivo canónico es `assets/data/companies.production.json` (1,907 RUC únicos).
Los domicilios se cruzan por RUC con el padrón reducido oficial de SUNAT:
https://www.sunat.gob.pe/descargaPRR/mrc137_padron_reducido.html

El padrón identifica domicilio fiscal. No demuestra que allí opere una planta,
que se atienda al público ni que esté la persona responsable de compras.
Se conservan dirección original, ubigeo, fecha, fuente y referencia distrital.

## Precisión

| Estado | Uso |
| --- | --- |
| `district_reference` | Solo referencia territorial. Sin distancia de visita ni navegación. |
| `address_geocoded` | Coincidencia automática de número, calle y distrito. Domicilio fiscal; central por confirmar. |
| `uncertain` | No apto para navegación ni ranking de cercanía. |

Solo `address_geocoded` validado o ubicaciones verificadas expresamente pueden
habilitar `nearby_ranking_eligible` y `navigation_eligible`.

## Fallback en Google Maps

Cuando `navigation_eligible=false`, la app no navega hacia el centro distrital.
En su lugar abre una búsqueda externa mediante Google Maps URLs con esta
composición:

```text
razón social + domicilio fiscal + distrito + provincia + departamento + Perú
```

La búsqueda usa `https://www.google.com/maps/search/?api=1&query=...` y se
construye con `Uri` para codificar correctamente espacios y caracteres
especiales. No requiere Google Maps SDK ni una API key dentro de Nexo.

El resultado de Google Maps es solo asistencia al vendedor. Nexo no captura ni
promueve automáticamente la coordenada devuelta como ubicación verificada; para
eso sigue aplicando el proceso de auditoría geográfica del dataset.

## Validación de resultados

El geocoder exige:

1. Resultado a nivel de dirección (no centroide de calle/distrito).
2. Número de puerta coincidente; admite ceros iniciales equivalentes.
3. Calle coincidente y distrito correspondiente al ubigeo fiscal.
4. País Perú, coordenadas válidas y coherencia territorial.
5. Coincidencia única. Si hay varios negocios en el mismo número, solo se
   prefiere la huella del edificio cuando contiene todos esos resultados.

El resultado conserva identificador OSM, dirección devuelta, fecha de proceso,
fuente y regla de validación. No se trata como verificación en campo.
Los resultados ambiguos, sin número o sin cobertura quedan pendientes.

## Ejecución puntual

```bash
python -m pip install -r tool/requirements-geocoding.txt
# Descargar el ZIP oficial desde el enlace de SUNAT y cruzar por RUC.
python tool/import_sunat_padron.py \
  --archive /ruta/de/trabajo/padron_reducido_ruc.zip \
  --input assets/data/companies.production.json \
  --cache /ruta/de/trabajo/geocoding-cache \
  --as-of AAAA-MM-DD
python tool/geocode_accounts.py \
  --input assets/data/companies.production.json \
  --output /ruta/de/trabajo/companies.geocoded.json \
  --cache /ruta/de/trabajo/geocoding-cache
python -m unittest discover -s tool -p 'test_geocode_verified.py'
```

La caché RUC puede precargarse desde el padrón oficial, evitando consultas
individuales. Los resultados del geocoder se cachean por consulta y se reusan
al reanudar. El JSON de salida y su resumen se escriben por lotes de diez.
Revisar el resumen antes de reemplazar el asset canónico.

## Nominatim

Este pipeline es una tarea puntual sobre la cartera existente; no descubre
clientes ni integra un servicio de búsqueda genérico en la app.
Política: https://operations.osmfoundation.org/policies/nominatim/

Una sola máquina y un hilo de geocodificación, User-Agent identificable,
intervalo mínimo 1.15 s entre solicitudes y caché obligatoria. Se detiene ante
HTTP 403/429. No reintentar repetidamente ni programarlo como tarea recurrente.
Para uso recurrente debe elegirse una instancia propia o proveedor autorizado.
Atribución: © OpenStreetMap contributors, ODbL.

## Catastro municipal complementario

Se cruzan solo las direcciones existentes por distrito, código de vía y número.
Fuentes públicas de descarga interoperable:

- Instituto Catastral de Lima, puertas y ejes de vía (Cercado de Lima):
  https://www.geoidep.gob.pe/catalogo-nacional-de-servicios-web/servicio-de-descarga-wfs
- Numeración municipal de Miraflores, publicada en IDEMIL:
  https://www.idemil.gob.pe/geoportal/rest/services/Hosted/SHP_Municipalidad_de_Miraflores___Lima_08_07_2024/FeatureServer

Para puertas representadas por segmentos cortos, se registra el promedio de sus
vértices y la extensión medida de la geometría. No se aceptan grupos de geometrías
con separación superior a 30 m. Las discrepancias mayores a 100 m con OSM quedan
pendientes, sin navegación. No se deduce una empresa a partir de un dueño de predio.

```bash
python tool/audit_geocodes.py --input /ruta/resultado.json \
  --output /ruta/auditado.json --cache /ruta/geocoding-cache
python tool/enrich_municipal.py --input /ruta/auditado.json \
  --output /ruta/final.json --cache /ruta/municipal-cache
```

Resultado de esta corrida: **274 ubicaciones utilizables, 1,633 pendientes**.
Las 1,907 cuentas tienen domicilio fiscal por RUC. El detalle de estados y fuentes
está en `GEOLOCATION_RESULT.json`. Esto no equivale a geocodificación exacta al 100%.
