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
