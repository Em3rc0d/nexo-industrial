# Personas clave — directorio de contactos profesionales públicos (11/11/2026)

## Objetivo

Encontrar personas de Compras, Abastecimiento, Logística y Mantenimiento **dentro de las 1,907 cuentas ya existentes**, sin crear prospectos desde LinkedIn, sin recolectar teléfonos privados ni convertir perfiles en compradores confirmados.

## Primer lote (histórico del trabajo de hoy)

- 11 referencias profesionales distintas vinculadas por **7 RUC**.
- 3 perfiles con atribución corporativa de cargo publicada en 2026.
- 2 perfiles autodeclarados en funciones relacionadas con compras en 2026.
- 2 perfiles públicos con afiliación y contexto funcional, pero cargo formal exacto pendiente.
- 2 perfiles respaldados por presentaciones de eventos profesionales en 2026.
- 2 referencias históricas de Minsur (2023), **no** presentadas como cargos actuales.
- 0 teléfonos laborales directos individuales verificados; 0 emails individuales confirmados en ese primer lote. Publicaciones que comparten correos de **departamento** se conservan como evidencias, pero no se atribuyen como buzones personales.

Fuente canónica: `data/people_enrichment/2026-11-11_mining_people.json`. Cada registro incluye RUC, nombre profesional, rol contextual, estado temporal, evidencia, fecha de revisión y URL pública de LinkedIn cuando existe.

### Roles de alto valor comercial

| RUC | Empresa | Referencias |
|---|---|---|
| 20383045267 | Volcan | Pieri Maguiña (compras/contratos, confirmado 2026), Sebastian Usquiano (compras, autodeclarado) |
| 20508891149 | JRC | Abbie Shirley Fernández Rivera (compras estratégicas, perfil público) |
| 20258699239 | Sotrami | Luis Enrique Zárate Tácunan, José Martín García Alcántara (ambos publican acciones de adquisición, cargo formal por confirmar) |
| 20600020022 | Kolpa | Manuel Grieve Marín (gerente de Logística, fuente de evento 2026) |
| 20510704291 | Minera Bateas | Yanina Delgado (gerente de Logística, confirmación corporativa 2026), Adán Abanto Romero (supervisor de Compras, confirmado por publicación corporativa; perfil LinkedIn hallado en el grupo Fortuna Mining) |
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
- La cantidad de trabajadores ya tiene campo separado `workers_sunat` en `CommercialProfile`, sin inferirlo de LinkedIn. La auditoría directa del asset comercial del 11/11/2026 halló **1,907/1,907 filas con valor numérico**, de ellas **1,904 positivas y 3 con valor 0**. La cifra no certifica vigencia de nómina ni indica cantidad de contactos.
- Las 1,907 referencias de representantes históricos no son estos 11 perfiles y no entran en los indicadores de contactos profesionales actuales.
- Esta es una **integración de código y datos**, no un APK ni una validación ejecutada en Android.

## Gate de publicación

El repositorio no garantiza Flutter SDK ni Android SDK en todos los entornos. Antes de anunciar una APK: `flutter analyze --no-pub`, `flutter test --no-pub`, `python3 tool/validate_dataset.py`, compilar y verificar en dispositivo la ficha de los siete RUC indicados y una empresa sin personas. No ejecutar GitHub Actions para compilar.

**Estado al 11/11/2026:** cambios guardados en `main`; pruebas añadidas pero **no ejecutadas** en este corte (Flutter no disponible en el runner actual).

## Aclaraciones de afiliación

El perfil profesional de Luis Garro aparece bajo **Southern Peaks Mining**; aunque fuentes de eventos de 2026 lo relacionan con la cadena de suministro de Condestable, su afiliación al RUC de Condestable debe corroborarse después de cambios societarios. La nota del registro deja explícita esta incertidumbre. El perfil de Adán Abanto aparece bajo **Fortuna Mining Corp.** (grupo de Bateas), lo que no equivale por sí mismo a un teléfono o correo de la filial.

## Ampliación del 11/11/2026 — segunda tanda (integrada en asset de código)

Se investigaron **14 referencias profesionales adicionales de 10 RUC** existentes. El archivo unido cargado por Flutter pasa a **25 perfiles distintos de 15 RUC**, con identidad de RUC cotejada contra las 1,907 referencias del master. El lote original está respaldado separadamente en `data/people_enrichment/2026-11-11_additional_people.json`, con 3 exclusiones documentadas; la fuente consumida por la app sigue siendo `data/people_enrichment/2026-11-11_mining_people.json`, ahora actualizada con los 25.

| RUC | Cuenta en Nexo | Referencias nuevas |
|---|---|---|
| 20132367800 | Minera Aurífera Retamas (MARSA) | Pablo Mimbela — subgerente de Logística, 2026 |
| 20100079501 | Buenaventura | Fernando Ortiz de Zevallos — gerente de Logística; Rossi Montalvo — directora de Compra de Servicios y Contratos, 2026 |
| 20506675457 | Minera Chinalco | Oscar Torres Koda — Supply Chain, perfil público y actividad 2026 |
| 20107290177 | Minera Colquisiri | Juan José Herrera — gerente general confirmado 2026; Juan Romero Belón — operaciones, vigencia exacta por confirmar |
| 20536126440 | Minera Veta Dorada | Víctor Arias Manchego — publicación de proveedores anterior; Gianmarco Benites — compras/logística; Erick Castillo — Supply Chain, directorio (verificar) |
| 20383045267 | Volcan | Neil Mendoza — gerente de Mantenimiento, publicación corporativa 2026 |
| 20514608041 | Chungar | Marco Villalobos — superintendente Mantenimiento Mecánico, referencia corporativa anterior (histórico) |
| 20492744833 | Nexa El Porvenir | Miguel Aguirre — compras/contratos CAPEX **del grupo Nexa**, no atribuido a esta filial en concreto |
| 20546191541 | Pan American Silver Huarón | Karla Lazo — Compradora Senior **del grupo Pan American Silver**, no atribuida a Huarón específicamente |
| 20508891149 | JRC | Alanna Rivas — vinculada públicamente a JRC; experiencia previa en Compras de Volcan, función actual en JRC no comprobada |

Se detectó **un correo profesional autodeclarado para recibir portafolios y presentaciones de proveedores** en una publicación anterior de Víctor Arias (`victor.arias@vetadorada.pe`), sin evidencia de entrega o vigencia al 11/11/2026. Se conserva **exclusivamente** como correo de proveedor publicado previamente, no como buzón personal verificado del comprador, no se suma a la cobertura de `CompanyContact`. Ningún teléfono de empleado ha sido promovido.

**Exclusiones:** Roxana Auccalla tiene publicaciones antiguas de adquisición en JRC, pero el perfil actual la vincula a Sonepar; Jean Salcedo publicó salida de Volcan; Javier Bernal de Lincuna quedó excluido porque el RUC 20458538701 no figura en el master actual (no se agregan empresas desde LinkedIn).

### Lógica de visualización ampliada

`ProfessionalContact` incluye `associationScope` y `workEmail`, acceso `workEmailUri` validado, etiquetas visibles de relaciones del grupo y correo publicado, con aviso de vigencia no comprobada. La sección Personas clave ya consumía el asset independiente y ahora muestra esta información separada de los teléfonos/emails empresariales. `test/public_professionals_test.dart` fue actualizado para 25 perfiles, 15 RUC, no duplicados, vinculación de filial vs grupo y correo con validación de formato.

**Estado de build:** commits guardados en `main`, pero no se ejecutó `flutter analyze`/`flutter test` ni se generó APK en este corte porque Flutter/Dart no están instalados en el entorno de ejecución actual. No se declara cobertura de 25 perfiles en ninguna APK instalada hasta reconstrucción local y pruebas.

**Limitación de negocio:** un perfil de compras no equivale a un canal directo operativo ni a una intención de compra de recubrimientos Aurora/Sigma. Los cargos de mantenimiento pueden servir para identificar prescriptores técnicos y los de compras para descubrir el proceso de homologación y cotización.

## Tercera tanda — investigación pública exclusivamente pasiva (11/11/2026)

Se incorporaron **8 referencias profesionales** de **6 RUC no cubiertos antes** al archivo de datos que consume Flutter, pasando de 25 personas / 15 RUC a **33 personas / 21 RUC**. Fuente de auditoría aislada: `data/people_enrichment/2026-11-11_readonly_pass3.json`; fuente integrada: `data/people_enrichment/2026-11-11_mining_people.json`.

| RUC | Empresa existente | Referencias |
|---|---|---|
| 20136150473 | Consorcio Minero Horizonte | Miguel Ponce Beoutis, jefe corporativo de Desarrollo de Proveedores, y Wendy Vanessa Ramirez Souza, equipo de Desarrollo de Proveedores (ambos autodeclarados 2026) |
| 20509551767 | Catalina Huanca | Oscar Urcia, Head de Procurement/Supply Chain según SUPPLYMIN 2026, y David Macedo, jefe de Compras según MINDER 2025 (cargo hoy pendiente de reconfirmar) |
| 20100163552 | Minera Raura | Miriam Ramos Charri, representante en encuentro de proveedores 2026; cargo específico y autoridad decisora por confirmar |
| 20514165972 | SFP Drilling | Alex La Rosa Egoavil, perfil público con experiencia en Supply Chain/Compras, puesto exacto sin comprobar |
| 20538428524 | Las Bambas | Hector Janampa, rol profesional de Supply autodeclarado en 2026, sin jefatura concreta afirmada |
| 20192779333 | Compañía Minera Ares / Hochschild Perú | Sebastian Baldeon, practicante de Procurement/Logística según publicación de incorporación 2026, **no decisor** y enlace individual provisional |

Los seis RUC pertenecen a las 1,907 referencias del master verificadas por archivo histórico (no se crearon cuentas). Se rechazó presentar a **Luis Felipe Bellido Calmet** como contacto vigente de Raura debido a publicación reciente en que comunica su salida. Se revisaron sin promover como compradores a Liseth Marycielo Sanchez Paucar (AKD, comercio exterior sin función de compra demostrada) y Carlos Noriega (RAMPERU, asesoría legal; no inferir titularidad del correo de proveedores por coincidencia de apellido).

### Hallazgo corporativo complementario

Consorcio Minero Horizonte publica en `https://cmh.com.pe/contactenos/` teléfono **+51 1 618 1000** y correo **contacto@cmh.com.pe**; el enlace oficial lleva al portal `https://ebiz.pe/proveedores-cmh/`, que explica el alta para nuevos proveedores y operaciones B2M para proveedores activos. Registro de evidencia: `data/contact_enrichment/2026-11-11_cmh_public_contact.json`. El portal eBIZ no se utilizó para registrarse ni contactar a nadie, y sus teléfonos de soporte **no** se atribuyen a compras de CMH. El sitio corporativo muestra una denominación societaria distinta a la del RUC, por lo que se conserva la discrepancia y se coteja la misma dirección de Jr. Crane 102. No aumentar cobertura telefónica/email hasta contrastar con asset previo y reconstruir.

### Garantía de no contacto

Solo se consultaron páginas y publicaciones públicas. **0 emails enviados; 0 mensajes de LinkedIn, WhatsApp o redes; 0 solicitudes de conexión; 0 llamadas; 0 formularios enviados; 0 registros de proveedor**. Los correos en fuentes de reclutamiento se descartaron. No se hizo scraping autenticado ni se recolectaron números personales.

### Estado de implementación

Se actualizó el asset JSON integrado de Flutter, las pruebas de conteo (33 perfiles, 21 RUC), el lote nuevo, la auditoría y las notas de alcance. No se ejecutaron pruebas Dart/Flutter ni se generó APK en esta sesión: el entorno actual no tiene Flutter ni Dart. La APK instalada conserva sus datos anteriores; los lotes públicos nuevos permanecen en repositorio hasta el gate de build y validación.
