# Arquitectura

## Objetivo

Mantener Nexo simple, local-first y desacoplado de proveedores de mapas para el descubrimiento comercial.

## Capas

### Domain
Company representa una cuenta canónica. internalPotential existe solo para ordenar y destacar; no se renderiza como score.

### Data
El MVP carga un JSON demo. La siguiente fuente debe ser el export canónico del dataset maestro sin cambiar la UI.

### Ranking
Combina potencial interno, distancia y confianza de ubicación. Es una heurística explicable, no una predicción infalible.

### Map
Mantiene ubicación real, separa seguimiento de exploración, recorta candidatos por radio, clusteriza markers y resalta unas pocas oportunidades.

### Activity
SQLite on-device. Solo persiste acciones registradas explícitamente.

## Escalado a ~1,900 cuentas

1,900 registros son manejables para cálculo local, pero no para representación visual directa.

Por eso:
- el ranking evalúa el dataset;
- el mapa recorta por radio contextual;
- se limita el conjunto renderizado;
- markers normales se clusterizan;
- solo pocas oportunidades superiores se dibujan individualmente.

Si el dataset crece a decenas de miles, mover el filtrado espacial a SQLite/R-tree.

## Mapas

El MVP usa flutter_map y tiles de OpenStreetMap para desarrollo. El descubrimiento de clientes nunca depende del mapa.

Para producción con tráfico significativo, usar una infraestructura de tiles que cumpla la política del proveedor o una alternativa autoalojada.

## Sin backend obligatorio

Dataset, ranking, búsqueda e historial local deben funcionar sin backend. Una sincronización futura puede añadirse como capa opcional.
