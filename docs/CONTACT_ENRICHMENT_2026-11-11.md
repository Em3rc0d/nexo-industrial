# Contactos publicados — primer bloque Callao y Lima Sur

## Alcance y resultado

Se priorizaron las primeras 24 cuentas sin teléfono/email del master, pertenecientes a la provincia del Callao o a distritos de Lima Sur, ordenadas por score descendente y RUC. Había 219 cuentas pendientes de teléfono/email en esa selección territorial al inicio.

- 13 cuentas con nuevos canales publicados de teléfono o email.
- 2 cuentas adicionales con página/formulario empresarial sin teléfono/email promovido (IOLSA y portal de grupo Limagas).
- 9 cuentas requieren otra fuente o corroboración; no se inventaron emails ni se trasladaron canales de empresas homónimas.

| Métrica global | Antes | Después |
|---|---:|---:|
| Cuentas | 1,907 | 1,907 |
| Teléfono | 254 | 267 |
| Email | 145 | 157 |
| Teléfono o email | 257 | 270 |
| Teléfono, email o página de contacto revisada | 257 | 272 |
| Sin teléfono ni email | 1,650 | 1,637 |

El denominador siempre es el master de cuentas existente. Las dos páginas web no se cuentan como teléfonos/emails y la referencia de representante no se cuenta como canal. El primer bloque no completa las 1,650 cuentas originales.

## Evidencia y clasificación

`data/contact_enrichment/2026-11-11_callao_sur.json` conserva cada RUC, valores publicados, URL fuente, enlace de identidad cuando corresponde, fecha 11/11/2026, finalidad del canal y notas. Se consultaron webs empresariales; para RAMPERU, una publicación de la página corporativa en LinkedIn que invita explícitamente a enviar información comercial de proveedores a cnoriega@ramperu.pe y publica el número empresarial. La invitación menciona insumos y equipos mineros, no una necesidad confirmada de pintura.

No se enviaron correos, mensajes ni formularios. No se comprobó entrega de correo, operatividad telefónica o capacidad de decisión del destinatario. No se usaron Maps/Places para descubrir clientes nuevos ni servicios de pago.

Se descartaron de la promoción: reclutamiento, emergencias, privacidad y fidelización cuando no eran canales empresariales generales. Zeta Gas conserva el teléfono de oficinas, sin presentar su correo de premios como compras. Mega Gas/Costagas se vinculó por RUC explícito en términos oficiales y dirección exacta; su correo se publica también en el apartado general de atención. Limagas usa un portal empresarial compartido del grupo y así se etiqueta, sin asignar el teléfono de emergencias ni el de gas doméstico a la entidad de gas natural.

Las referencias antiguas de DEIMETSA, SERTESA, NOV y AISTEC se dejan para corroboración; no se promociona su vigencia a partir de un número de directorio. Las limitaciones de acceso y los casos sin canal suficiente quedan registrados en `reviews`.

## Persistencia y uso

- `tool/recover_commercial_overlay.py` reconstruye primero la base histórica y sus referencias; después aplica los lotes aceptados de enriquecimiento por RUC. Solo completa teléfonos/emails vacíos y conserva las fuentes.
- El overlay comercial productivo incluye los 15 registros de este bloque, sus canales y metadatos.
- La ficha añade botón para abrir la página de contacto cuando existe, muestra fecha de consulta y finalidad del canal. Las páginas web no se abren ni envían formularios automáticamente.
- `pending.json.gz` contiene la cola de 1,637 RUC sin teléfono/email, ordenada por score, con distrito/provincia y estado de revisión. `progress.json` registra el corte y los totales; no representa trabajo de fondo.
- No se modificaron coordenadas ni se añadieron cuentas fuera del master.

La implementación se prepara como 1.0.4+7. La APK 1.0.3+6 ya entregada no contiene este lote nuevo. Una APK nueva solo podrá anunciarse después de compilarla y contrastar sus assets.

## Validación ejecutada

Flutter 3.47.9 / Dart 3.13.7, con CI/BOT y telemetría desactivada. `flutter analyze --no-pub`: sin incidencias. `flutter test --no-pub`: 14/14 aprobadas. El validador de datos y la auditoría de snapshot pasan. La reconstrucción repetida del overlay es byte a byte idéntica; los 15 RUC aceptados están presentes y no se aplican los 9 casos pendientes. La prueba nueva comprueba el formulario sin teléfono/email de IOLSA, la finalidad de proveedores de RAMPERU y la exclusión del email de premios de Zeta Gas.

No se compiló una nueva APK en este corte ni se probó la interacción en dispositivo. La prioridad de esta entrega es dejar el enriquecimiento guardado en el master y Git antes de otro build.

## Ampliación de investigación del 11/11/2026 (lotes segundo y tercero)

Se agregaron los lotes de **investigación**, sin modificar aún el `assets/data/companies.commercial.overlay.json.gz` ni regenerar APK:

- `data/contact_enrichment/2026-11-11_lima_mineria.json`: 10 RUC con registros aceptados (8 con teléfono, 4 con email, 9 con cualquiera, 1 con portal exclusivo), 6 revisiones sin promoción.
- `data/contact_enrichment/2026-11-11_mineria_y_servicios.json`: 7 RUC con registros aceptados (6 con teléfono, 3 con email, 7 con cualquiera), 3 revisiones sin promoción.

**Cobertura proyectada, condicionada a reconstrucción y validación del asset:** 1,907 cuentas, 281 con teléfono (267+14), 164 con email (157+7), 286 con teléfono o email (270+16), y 289 con teléfono, email o formulario/página revisada (272+17). Quedarían **1,621** sin teléfono ni email. Ninguno de estos incrementos se debe informar como cobertura efectiva de la APK 1.0.3+6 o del asset comercial actual hasta verificar la reconstrucción.

**50 cuentas revisadas acumuladas** (24 primera tanda + 16 segunda + 10 tercera): 29 nuevas con teléfono y/o correo, 3 adicionales con formulario/portal sin esos dos datos, 18 restantes en revisión o pendientes de corroboración. Al contar canales por RUC, números compartidos de grupo se registran como `shared_group_switchboard_not_direct_subsidiary`; NO implican contacto individual/directo ni compradores comprobados.

Destacados del nuevo trabajo:
- JRC: `compras@jrcing.com.pe`, invitación pública empresarial a proveedores (no implica necesidad actual de pintura).
- Minera Sotrami: `compras1@sotrami.com.pe` en publicación pública de compra de equipos, además del canal general.
- Minsur y Antapaccay: portales oficiales de proveedores, no pedidos de cotización comprobados.
- Miski Mayo: `contacto@miskimayo.com` y una referencia de responsable de suministros publicada en directorio marzo 2025; cargo y operatividad al 2026 no corroborados.
- Pan American Silver Huarón y Shahuindo: solo central compartida del grupo; no líneas independientes del comprador.
- Shouxin: solo se hallaron canales de denuncias/reclutamiento, rechazados como contactos comerciales.

### Gate para incorporar al producto

1. Reconstruir overlay con `python3 tool/recover_commercial_overlay.py` y verificar 1,907 RUC únicos, 281 teléfonos, 164 correos y 286 cuentas con cualquiera (si no han cambiado otras fuentes).
2. Actualizar aserciones de cobertura en `test/production_dataset_test.dart` (actualmente esperan los totales anteriores) y manifest `assets/data/production/manifest.json` **solo después** de validar los resultados reales.
3. Ejecutar `python3 tool/validate_dataset.py`, `flutter analyze --no-pub`, `flutter test --no-pub`; comprobar reconstrucción determinista y persistir el asset comprimido, manifest y pruebas en el mismo commit. La app instalada requiere nueva compilación para consumir los datos.
4. No enviar emails, formularios ni mensajes automáticamente. No elevar correo de reclutamiento/denuncias, números enmascarados ni representantes históricos a canales comerciales.

El barrido se basó exclusivamente en RUC existentes de la cola; se preservaron fuentes, finalidad, notas de vínculo por RUC y fecha de revisión. Los registros aceptados significan **canal publicado**, no entrega de correo comprobada ni titular de compras identificado.
