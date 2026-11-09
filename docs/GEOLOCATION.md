# Geolocalización de las 1,907 cuentas

## Dos niveles distintos

Nexo no debe confundir cobertura territorial con una sede exacta.

### `district_reference`

Coordenada administrativa de referencia del distrito/ubigeo.

Sirve para:
- cobertura territorial;
- filtros regionales;
- clusters amplios;
- detectar en qué distrito existen cuentas.

No sirve para:
- afirmar “está a 350 m”;
- ordenar oportunidades a pie;
- “Cómo llegar”;
- presentar el punto como planta, central o puerta.

### `address_geocoded`

Coordenada obtenida a partir del domicilio fiscal y validada contra el
distrito/provincia/departamento esperado.

Puede habilitar:
- distancia;
- ranking “cerca de ti”;
- navegación.

Aun así, domicilio fiscal **no equivale necesariamente a planta o sede comercial**.
Las cuentas críticas deben validarse antes de una visita.

## Pipeline

El dataset comercial real NO debe subirse a este repositorio público.

1. Partir del maestro privado con los 1,907 RUC.
2. Asignar referencia distrital/ubigeo a todas las cuentas.
3. Enriquecer el domicilio fiscal con OpenRUC:
   - `GET https://openruc.com/api/ruc/{ruc}`
   - sin API key;
   - datos derivados de SUNAT.
4. Geocodificar el domicilio mediante un proveedor configurable.
5. Validar que el resultado sea consistente con distrito/provincia/departamento.
6. Mantener fallback distrital si no existe un match confiable.
7. Revisar visualmente cuentas de mayor prioridad antes de habilitar navegación.

Script:

```bash
python tool/geocode_accounts.py \
  --input /ruta/privada/nexo_companies_1907_georef.json \
  --output /ruta/privada/nexo_companies_1907_address_geocoded.json
```

Lo anterior enriquece domicilio SUNAT sin llamar un geocoder.

## Nominatim público: solo para una corrida deliberada

La política oficial de OSMF establece un máximo absoluto de 1 request/segundo,
User-Agent identificable, una sola máquina/hilo y caché para tareas bulk.
Además, el servicio público no debe convertirse en dependencia de producción.

Política:
https://operations.osmfoundation.org/policies/nominatim/

Para una corrida puntual:

```bash
NEXO_GEOCODER_USER_AGENT="NexoIndustrial/0.1 (internal one-time geocoding)" \
python tool/geocode_accounts.py \
  --input /ruta/privada/nexo_companies_1907_georef.json \
  --output /ruta/privada/nexo_companies_1907_address_geocoded.json \
  --provider nominatim \
  --i-accept-osmf-policy
```

El script:
- es single-thread;
- espera al menos 1.1 s entre peticiones;
- cachea respuestas;
- nunca repite una query ya cacheada;
- conserva el fallback distrital si la coincidencia no es consistente.

Para geocodificación recurrente o comercial debe usarse una instancia propia o
un proveedor cuya política permita ese volumen.

## Gate para APK operativo

No llamar “listo para campo” al dataset hasta cumplir:

- 1,907/1,907 con coordenada territorial: obligatorio;
- direcciones SUNAT enriquecidas por RUC;
- geocodificación de dirección para el máximo de cuentas posible;
- revisión manual de las oportunidades S+/S prioritarias;
- `nearby_ranking_eligible=true` únicamente cuando la precisión sea suficiente;
- `navigation_eligible=true` únicamente cuando la ubicación sea defendible.

El mapa puede mostrar referencias territoriales, pero **no calcular cercanía
peatonal sobre puntos distritales**.
