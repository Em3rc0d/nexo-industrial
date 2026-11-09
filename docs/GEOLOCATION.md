# Geolocalización de cuentas

## Estado productivo

Nexo contiene **1,907 cuentas y 1,907 RUC únicos**. Todas tienen latitud y longitud.

La cobertura auditada del 9 de noviembre de 2026 es:

| Calidad | Cuentas | Uso |
| --- | ---: | --- |
| `exact_address` | 334 | Dirección precisa; navegación permitida cuando la auditoría lo autoriza. |
| `address_reference` | 36 | Referencia de dirección sólida; navegación permitida. |
| `interpolated_address` | 137 | Punto aproximado por numeración; cercanía penalizada, sin navegación directa. |
| `street_reference` | 551 | Referencia de vía; solo contexto visual. |
| `district_reference` | 849 | Referencia territorial; solo contexto visual. |

**370 cuentas** están habilitadas para navegación directa.

## Arquitectura de datos

El domicilio fiscal y los atributos comerciales permanecen en:

`assets/data/companies.production.json`

La auditoría geográfica se conserva separada en:

`assets/data/companies.geolocation.overlay.json`

La app cruza ambas capas por RUC al cargar. Esto permite actualizar geolocalización sin alterar la fuente comercial canónica.

## Domicilio fiscal

SUNAT identifica domicilio fiscal. No demuestra que allí opere una planta, un almacén, una sede visitable ni la persona responsable de compras.

Por eso Nexo diferencia “dirección georreferenciada” de “sede operativa confirmada”.

## Ranking

La distancia solo participa cuando la evidencia lo permite:

- exacta: peso completo;
- referencia de dirección: casi completo;
- interpolada: peso reducido;
- calle/distrito: no compiten por cercanía.

Así se evita que un centroide distrital gane artificialmente frente a una dirección real.

## Google Maps fallback

Cuando `navigation_eligible=true`, “Cómo llegar” abre:

`https://www.google.com/maps/dir/?api=1&destination=LAT,LON`

Cuando `navigation_eligible=false`, “Buscar en Maps” abre:

`https://www.google.com/maps/search/?api=1&query=...`

Query:

`razón social + domicilio fiscal + distrito + provincia + departamento + Perú`

No requiere Google Maps SDK ni API key. El resultado externo no se promueve automáticamente a evidencia verificada.

## Principio de seguridad de datos

**100% de cobertura geográfica no significa 100% de exactitud de puerta.**

Nunca se promueve una referencia distrital, una vía o una interpolación como ubicación exacta solo para completar un contador.
