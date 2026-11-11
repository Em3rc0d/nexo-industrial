# Personas clave — piloto de contactos profesionales públicos (11/11/2026)

## Objetivo

Encontrar personas de Compras, Abastecimiento, Logística y Mantenimiento **dentro de las 1,907 cuentas ya existentes**, sin crear prospectos desde LinkedIn, sin recolectar teléfonos privados ni convertir perfiles en compradores confirmados.

## Alcance completado

- 11 referencias profesionales distintas vinculadas por **7 RUC**.
- 3 perfiles con atribución corporativa de cargo publicada en 2026.
- 2 perfiles autodeclarados en funciones relacionadas con compras en 2026.
- 2 perfiles públicos con afiliación y contexto funcional, pero cargo formal exacto pendiente.
- 2 perfiles respaldados por presentaciones de eventos profesionales en 2026.
- 2 referencias históricas de Minsur (2023), **no** presentadas como cargos actuales.
- 0 teléfonos laborales directos individuales verificados; 0 emails individuales confirmados. Publicaciones que comparten correos de **departamento** se conservan como evidencias, pero no se atribuyen como buzones personales.

Fuente canónica: `data/people_enrichment/2026-11-11_mining_people.json`. Cada registro incluye RUC, nombre profesional, rol contextual, estado temporal, evidencia, fecha de revisión y URL pública de LinkedIn cuando existe.

### Roles de alto valor comercial

| RUC | Empresa | Referencias |
|---|---|---|
| 20383045267 | Volcan | Pieri Maguiña (compras/contratos, confirmado 2026), Sebastian Usquiano (compras, autodeclarado) |
| 20508891149 | JRC | Abbie Shirley Fernández Rivera (compras estratégicas, perfil público) |
| 20258699239 | Sotrami | Luis Enrique Zárate Tácunan, José Martín García Alcántara (ambos publican acciones de adquisición, cargo formal por confirmar) |
| 20600020022 | Kolpa | Manuel Grieve Marín (gerente de Logística, fuente de evento 2026) |
| 20510704291 | Minera Bateas | Yanina Delgado (gerente de Logística, confirmación corporativa 2026), Adán Abanto Romero (supervisor de Compras, confirmado por publicación corporativa; sin perfil LinkedIn individual encontrado) |
| 20100056802 | Condestable | Luis Garro (vicepresidente de Cadena de Suministros, conferencia profesional 2026) |
| 20100136741 | Minsur | Ralph Alosilla-Velazco y Mario Obando (roles publicados en conferencia 2023, vigencia pendiente) |

La razón social/RUC proviene exclusivamente de la cartera Nexo; el vínculo profesional se sustenta por una publicación de la empresa, un perfil que identifica a la compañía o un evento sectorial. Cuando se presenta solamente una publicación personal, no se presume autoridad para comprar pinturas.

## Integración técnica

1. `pubspec.yaml` incluye el JSON como asset en el APK.
2. `AssetCompanyRepository` carga el asset, comprueba que cada RUC pertenece a la cartera comercial y rechaza identidad duplicada por nombre/RUC.
3. `ProfessionalContact` en `company.dart` modela el contexto, `verificationLabel`, `isHistorical` y el enlace externo HTTPS a LinkedIn (host restringido a LinkedIn).
4. `company_detail_screen.dart` muestra la sección **Personas clave · fuentes públicas** únicamente cuando hay perfiles; los datos de teléfono/email comercial se mantienen en su sección independiente.
5. `test/public_professionals_test.dart` añade pruebas de unión RUC, distinción histórica, URL segura y no inflación de contactos.

## Límites y evaluación

- La fecha de revisión del registro no convierte un cargo de 2023 en uno vigente.
- Para nombres con cargo confirmado en 2026, la vigencia sigue siendo verificable al contactar, porque cualquier relación laboral puede cambiar.
- Un email de compras publicado en un post se registra como **buzón de área** y nunca se atribuye a una persona sin evidencia.
- Se excluyen teléfonos personales, WhatsApp privados, correos deducidos por patrón, scraping masivo de LinkedIn, contactos de reclutamiento y datos obtenidos bajo autenticación restringida.
- LinkedIn puede indicar tamaño estimado de empresa o cantidad de perfiles asociados; **no** equivale a trabajadores SUNAT, nómina activa ni teléfonos verificables.
- La cantidad de trabajadores ya tiene campo separado `workers_sunat` en `CommercialProfile`, sin inferirlo de LinkedIn.
- Las 1,907 referencias de representantes históricos no son estos 11 perfiles y no entran en los indicadores de contactos profesionales actuales.
- Esta es una **integración de código y datos**, no un APK ni una validación ejecutada en Android.

## Gate de publicación

El repositorio no garantiza Flutter SDK ni Android SDK en todos los entornos. Antes de anunciar una APK: `flutter analyze --no-pub`, `flutter test --no-pub`, `python3 tool/validate_dataset.py`, compilar y verificar en dispositivo la ficha de los siete RUC indicados y una empresa sin personas. No ejecutar GitHub Actions para compilar.

**Estado al 11/11/2026:** cambios guardados en `main`; pruebas añadidas pero **no ejecutadas** en este corte (Flutter no disponible en el runner actual).
