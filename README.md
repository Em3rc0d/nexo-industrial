# Nexo Industrial

Radar comercial geográfico para encontrar, priorizar y activar oportunidades industriales en campo.

> Estado: MVP en construcción. El repositorio se inicializó para implementar la experiencia mobile-first discutida: **Mapa → Oportunidad → Ficha comercial → Empresas cercanas**.

La aplicación evita depender de Google Maps SDK para el descubrimiento de clientes. El dataset maestro propio es la fuente canónica de cuentas; el mapa es una capa de visualización y navegación.

La implementación base usa Flutter y OpenStreetMap mediante `flutter_map`. Consulta `docs/` para arquitectura, alcance, UX y contrato de datos.
