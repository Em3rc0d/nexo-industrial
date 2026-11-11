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

## Cuarto bloque adicional y cierre del corte de investigación

Se guardó `data/contact_enrichment/2026-11-11_mineria_proveedores_grupos.json`: cuatro RUC adicionales con teléfono (+4) y tres con email (+3) entre Raura, Minera Bateas, Nexa El Porvenir y Empresa Administradora Cerro. Un caso La Arena mantiene solamente un canal comunitario no comercial, por lo que no se promocionó a teléfono/email de ventas.

**Corte FINAL DE INVESTIGACIÓN de esta sesión (no aplicado aún al asset):** 55 RUC revisados en los cuatro lotes del día; 33 con nuevo teléfono o email, 3 adicionales solo con portal/formulario y 19 pendientes de corroboración. Si y solo si la reconstrucción resulta correcta, serían **285 con teléfono, 167 con email, 290 con cualquiera, 293 incluyendo formularios**, frente a **1,617 sin teléfono ni email** de 1,907 cuentas. Números de centrales corporativas compartidas por filiales se cuentan por RUC, no como líneas telefónicas distintas.

El conteo auditado de los tres lotes agregados se encuentra en `data/contact_enrichment/staged_status_2026-11-11.json`. Cualquier dato anterior del capítulo se refiere al avance parcial del 11/11; estos totales finales **son únicamente proyección de investigación** y **no** reemplazan los totales que muestra la APK ni el manifest productivo. Para actualizar la aplicación es imprescindible el gate de reconstrucción y pruebas mencionado arriba.

## Ampliación pasiva — contratistas, plantas mineras y terminal portuario (11/11/2026)

Se guardaron dos lotes nuevos SIN contacto con ningún prospecto:

- `data/contact_enrichment/2026-11-11_contratistas_directos_y_portales.json` — 11 RUC revisados: **3** con nuevo teléfono Y email (Tecnomin Data 20221259581, Explo Drilling Perú 20527775851 y Servicios Energéticos Ambientales/SEA 20525998577), **2** solo con página/portal oficial (Minera Los Quenuales 20332907990 → portal de proveedores Alpayana; Minera OREX 20602044239 → web de contacto), y **6** otros revisados sin promover canales inseguros/antiguos o exclusividad de reclutamiento.
- `data/contact_enrichment/2026-11-11_paita_y_paltarumi.json` — **2** RUC adicionales con canal publicado: TPE Paita 20522473571 (comunicado oficial del 26/02/2026: +51 956 362 790 y customer.service@euroandino.com.pe, ATENCIÓN AL CLIENTE/comercial, NO compras de suministros) y Paltarumi 20548379840 (info@paltarumi.com.pe, general, sin teléfono corroborado).
- `data/contact_enrichment/2026-11-11_cmh_public_contact.json` — CMH 20136150473, evidencia de portal eBIZ y teléfono/email corporativo; **no incrementa** cobertura porque el asset vigente ya contenía tanto teléfono como correo exactos.

Fuentes oficiales, vínculo por identidad/RUC, propósito de canal, discrepancias y nivel de vigencia están en cada registro individual. En el primer lote nuevo, una dirección de Tecnomin Data salió del directorio de proveedores IIMP 2026; hay discrepancias en el número del predio entre web y directorio. En SEA, el sitio muestra `contacto@sea.pe` en inicio/pie y otro dominio en el cuerpo: únicamente el correo `.pe` corroborado se promovió. Los Queñuales tiene ahora portal de proveedores de Alpayana (adquirente desde 2022); se excluyeron directorios telefónicos de la propiedad anterior. OREX conserva solamente página de contacto; no se usó correo de terceros de órdenes de compra.

Para Paita se documenta explícitamente que **Franklin Urteaga Medina dejó de trabajar allí** en febrero de 2026; no se presenta como contacto actual. Se excluyeron correos de reclamos y permisos de acceso porque no son compras.

### Cobertura conciliada: investigación, NO APK

De **1,907 RUC** del master, tras todos los siete lotes del 11/11:

| Métrica | Aplicado al asset vigente | Proyección al reconstruir y validar |
|---|---:|---:|
| Cuentas con teléfono | 267 | **289** |
| Cuentas con email | 157 | **172** |
| Cuentas con teléfono o email | 270 | **295** |
| Cuentas con teléfono, email o página/portal revisado | 272 | **300** |
| Cuentas sin teléfono ni email | 1,637 | **1,612** |

**69 RUC revisados**, 44 filas aceptadas en 7 lotes (sin RUC duplicado en `records`), de las cuales 38 aportaron un nuevo teléfono/email a RUC antes sin canal, 5 aportaron solo portal/página, y 1 ya tenía ambos canales (CMH); otros 25 quedaron sin promoción de canal. Los porcentajes no representan correos entregados, líneas atendidas ni compradores confirmados.

Auditoría y cálculos: `data/contact_enrichment/staged_status_2026-11-11.json`. La reconstrucción por `tool/recover_commercial_overlay.py` y la actualización de manifest/test quedan **pendientes**. Los contadores `progress.json` históricos corresponden al primer corte de 24 RUC y no deben confundirse con la última proyección. No se compila APK en este corte.

**Actividad de comunicación cero:** sin llamadas, emails, WhatsApp, DM, conexiones LinkedIn, formularios ni registros de proveedores. Todo fue consulta de webs públicas y escritura de evidencia al GitHub del proyecto.

## Último corte — Construplan / Mincotrall / AK Drilling (11/11/2026)

Se añadió `data/contact_enrichment/2026-11-11_construplan_mincotrall_akd.json`, con **dos registros aceptados y una revisión deduplicada** (AKD), sustentados en fuentes empresariales y Cámara de Comercio Canadá-Perú:

- **Construplan (20609408261)**: `+51 1 680 6229` de cámara de comercio con RUC exacto, y `gustavo.pena@construplan.com.pe` publicado en la delegación oficial PDAC 2026 por su **Business Development Manager**. Se conserva en notas que **no es un comprador verificado** de materiales; teléfono personal comercial de directorio solo en campo adicional de evidencia, jamás como teléfono de adquisiciones.
- **Mincotrall (20390962348)**: `+51 1 480 1658`, `contacto@mincotrall.com.pe`; la web corporativa confirma oficina de Lince, compañía contratista de explotación/desarrollo minero. Exclusión del teléfono de WhatsApp de `/postula/`, específico para reclutamiento.
- **AK Drilling International (20470234599)**: la revisión confirma que su página corporativa publica `+51 1 251 3380`, `global@akdint.com`. Comprobación del overlay comprimido original: **ambos canales ya estaban**. El correo es del grupo internacional y no una dirección específica de Compras en Perú.

El overlay comercial original también fue inspeccionado individualmente: Construplan y Mincotrall no tenían teléfono/email; Paita y Paltarumi tampoco. CMH y AKD ya tenían ambos. Por tanto, entre las **8 tandas del 11/11**, **72 RUC revisados**: **40** aportaron teléfono o email a un RUC que carecía de ambos, **5** aportaron solo web/portal, **2** ya estaban cubiertos (CMH y AKD), y **25** continuaron sin canal promovible. Hay **46 registros aceptados únicos** entre los ocho lotes, más **26 revisiones** (25 casos sin canal promovible y AKD ya incorporada en el primer lote). No hay RUC duplicados entre las filas aceptadas.

| Cobertura | Asset anterior (comprobado) | Proyección con todas las tandas (SIN reconstruir) |
|---|---:|---:|
| Teléfono | 267 | **291** |
| Email | 157 | **174** |
| Teléfono o email | 270 | **297** |
| Teléfono/email o portal web | 272 | **302** |
| Sin teléfono ni email | 1,637 | **1,610** |

Las cifras anteriores del documento corresponden a cortes parciales anteriores; **este último corte sustituye sus proyecciones**, no el conteo real que tiene la APK. La fuente autoritativa del corte de investigación es `data/contact_enrichment/staged_status_2026-11-11.json`.

**Sigue prohibido enviar mensajes, correos, llamadas, solicitudes LinkedIn, formularios o registros de proveedores.** No se ha hecho ninguna de esas acciones. No se ha reconstruido el asset comercial, ejecutado Flutter ni compilado APK.

## Integración de fuente — parche comercial offline, sin nueva APK (11/11/2026)

Los ocho lotes aceptados están representados por el **asset comprimido previo** (15 RUC de Callao/Sur ya aplicados) y el nuevo **parche comercial incremental** `assets/data/companies.contact.patch.json` (31 RUC de los lotes posteriores, disjuntos del primer lote). El cargador de Flutter une ambos en memoria por RUC, rellena solo teléfonos/emails vacíos y preserva los originales, incorpora la fuente y el propósito del canal, y rechaza RUC desconocidos, duplicados o fuentes inválidas. La integración no crea nuevas cuentas ni cambia geolocalizaciones.

`pubspec.yaml` empaqueta ambos assets, `test/production_dataset_test.dart` y `test/public_professionals_test.dart` incorporan expectativas de **291** teléfonos, **174** correos, **297** con algún canal y **302** incluyendo web/portal. `assets/data/production/manifest.json` conserva `base_commercial_contact_coverage` con 270 y define `contact_coverage` del merge con 297 esperados.

Un auditor reproducible solo local, sin conexión de red ni contacto a terceros: `python3 tool/validate_contact_patch.py`. Revisa integridad de 1,907 cuentas, 31 filas del parche, 46 RUC aceptados entre ocho lotes, 33 personas públicas y cifras finales. **El auditor todavía no se ha ejecutado contra un clon local en esta sesión.** No hay Flutter/Dart instalado aquí, de modo que tampoco hay `flutter analyze`, `flutter test`, compilación ni APK nueva. El próximo gate sigue siendo verificar localmente y compilar sin GitHub Actions. 

## Ronda final — EVS + South American Drilling (11/11/2026)

Se agregó el lote `data/contact_enrichment/2026-11-11_evs_sadrilling.json`: **2 RUC aceptados de cuentas antes sin canal y 3 revisiones rechazadas**, sin contactar a nadie.

- **EVS Contratistas Mineros S.A.C. (20539424743)**: `+51 1 704 8970` y `elmer.sotasor@evs.com.pe` desde el pie de página del sitio corporativo `https://evs.com.pe/contacto/`. El mismo sitio también muestra `+51 1 7240747` en el cuerpo de la página: se conservó la discrepancia y se seleccionó únicamente el número repetido en el pie y portada. No es número directo de compras.
- **South American Drilling S.A.C. (20536925245)**: `consultas@sadrilling.com` en la página `https://www.sadrilling.com/contactos`, identidad RUC confirmada con registro SUNAT. No se atribuyó un teléfono no publicado ni un cargo de comprador al email general.
- No se promovieron email de privacidad de postulantes de Shouxin, datos de una factura del 2019 de otra cuenta ni una cuenta Global Fuel sin teléfono/email empresarial público corroborable.

El parche Flutter offline pasó de **31 a 33 RUC aceptados** y mantiene 1,907 cuentas sin modificaciones geográficas. El archivo `assets/data/production/manifest.json`, tests y el auditor `tool/validate_contact_patch.py` ya esperan **292 teléfonos, 176 emails, 299 empresas con ambos o alguno de estos canales y 304 incluyendo página/portal**. Baseline comprimido intacto: 267/157/270/272. Hay **77 RUC revisados** en nueve lotes: 48 filas aceptadas por RUC sin duplicados, 29 revisiones sin promoción; 33 del parche incremental y 15 en el primer lote incluido en gzip.

**Control de calidad:** la fusión de los 31 primeros del parche se comprobó directamente contra los 1,907 RUC del asset comprimido, obteniendo 297 empresas con teléfono/email. Los dos registros EVS y South American Drilling se añadieron posteriormente; las cifras de 299/304 son las expectativas actualizadas, pendientes de ejecutar el auditor local/Flutter antes de tratarlas como resultados probados de APK. No se envió ninguna comunicación a empresas o personas.
