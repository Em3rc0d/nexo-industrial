# Recuperación de contactos — 10 de noviembre de 2026

## Datos recuperados

Se inspeccionaron masters del snapshot, sus tablas de prioridad, el JSON original pegado, assets de versiones previas del código y la APK 0.1.1. Los masters más recientes conservados contienen los mismos 251 teléfonos y 142 emails del overlay inicial. Los masters originales/prioridades y assets previos contenían 11 teléfonos y 10 emails. No apareció un master con teléfono/email para todas las cuentas.

En el historial Git se encontró el archivo `transfer/elruc_person_compact.b64` del commit `180813cd707a42f0df19ca8ea990bcbf0e516aa4`, eliminado del árbol actual. Sus cinco partes y el archivo concatenado son idénticos. El contenido es gzip+JSON con 1,907 pares RUC/referencia de representante y cargo. Los 1,907 RUC son únicos e idénticos al master productivo. Se conserva el gzip original en `data/contact_recovery/registry_references_180813c.json.gz`, con hash y commit de origen en el manifiesto. La recuperación se aplica al reconstruir el overlay, de forma determinista.

Estas referencias se atribuyen al archivo histórico ElRUC, sin revalidación individual de vigencia. Incluyen 24 nombres que parecen entidades jurídicas; no deben contarse como 1,907 personas ni como compradores. La ficha muestra esta información separada de teléfono/email, con la advertencia correspondiente. La muestra STRACON, RUC 20610105620, coincide con la referencia pública ElRUC consultada: Tamayo Ortega John Edwin (Gerente General); esto no valida las otras referencias ni las convierte en decisores de compra.

Del directorio anterior de 84 prospectos se identificaron cinco coincidencias únicas de razón social normalizada contra cuentas existentes. Se recuperaron tres con canales y URL pública original: CIM Estructuras, Arcam Granallados y Tecnotal. Los teléfonos/emails se contrastaron con sus webs. Las otras dos se dejaron pendientes porque carecen de URL pública original suficiente. No se trasladaron contactos mediante fuzzy matching ni se crearon nuevas cuentas.

## Cobertura

| Dato | Antes | Después |
|---|---:|---:|
| Cuentas | 1,907 | 1,907 |
| Teléfono | 251 | 254 |
| Email | 142 | 145 |
| Teléfono o email | 254 | 257 |
| Nombre de contacto del master | 11 | 11 |
| Referencia histórica representante/cargo | 0 | 1,907 |
| Sin teléfono ni email | 1,653 | 1,650 |

Los correos publicados pueden abrir la app de correo mediante botones `mailto`, uno por dirección, sin enviar mensajes automáticamente. Un representante sin canal no cuenta como contacto directo.

## Fuentes específicas de los tres canales recuperados

- CIM: https://cimestructuras.pe/ — teléfono 907 001 269 y ventas@cimestructuras.pe.
- Arcam: https://arcamgranallados.com.pe/nosotros/ — teléfono 998 239 111 y comercial@arcamgranallados.com.pe.
- Tecnotal: https://tecnotal.com.pe/contact/ — teléfono 226 1166 y comercial@tecnotal.com.pe.

La identidad se vinculó por razón social única, actividad publicada y los datos del directorio; no se sustituyó el domicilio fiscal ni se promovió la sede comercial a HQ. Los datos del directorio fueron revisados originalmente el 05/11/2026 y sus canales se contrastaron de nuevo durante esta recuperación. No se confirma entrega de email, vigencia operativa del teléfono o identidad del comprador por el hecho de estar publicado.

## Validación

- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub`: 12/12 aprobadas.
- Reconstrucción repetida del overlay: bytes idénticos.
- Validador de dataset y auditoría de snapshot: aprobados.
- Cambios geográficos: ninguno; sigue 370 navegación directa / 1,537 búsquedas.

La versión 1.0.3+6 incluye la recuperación y los botones de correo. No se han probado aún los botones en un teléfono real. Se conserva el perfil de build de memoria reducida y firma Android Debug de las releases anteriores.

## APK generada

Archivo `Nexo-Industrial-1.0.3-build6.apk`; 58,112,097 bytes; SHA-256 `727496c60dcbaccf4d6c3a94531941f258383b42142b04a371de78374f80a5b7`. Firma y alineación de 16 KB aprobadas. CRC íntegro y los tres assets coinciden byte a byte con las fuentes. El propio APK contiene los totales de la tabla.
