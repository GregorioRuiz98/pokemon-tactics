# Godot — instrucciones vigentes

Aplican las [instrucciones raíz](../AGENTS.md). Leer [desarrollo](README.md), [arquitectura](../docs/ARCHITECTURE.md) y [estado](../docs/PLAN_SPRINTS.md).

- Godot 4.7.2 estándar/GDScript, Windows x 86_64 offline. Entrada `scenes/campaign.tscn`; laboratorio separado `scenes/laboratory.tscn`. Sin plugins obligatorios.
- Versión canónica en `project.godot`. 1.0.0-rc.4 usa campaña 30/capítulo 34/combate 25; los guardados anteriores conservan su edición. Un cambio documental no exige cambiar reglas ni repetir toda la campaña.
- No sobrescribir motores, datos, pruebas ni recursos publicados. El motor actual extiende revisiones previas y las despacha por edición; no son código muerto. Reglas distintas requieren nueva edición/migración.
- QA en perfiles aislados, nunca en `%APPDATA%/PokemonTacticsLab` real. Partida, laboratorio y perfil separados. Preservar diario, checksum, copia, concurrencia y originales inválidos/futuros. No convertir combates antiguos silenciosamente.
- Guardar órdenes aceptadas antes de animar; sin azar en consultas, sonidos o UI. La previa genera sobre una copia y reutiliza la instantánea, sin guardar ni alterar la aventura.
- UI integrada, movimiento directo y cuatro técnicas+básico. Rectificar solo movimiento antes de actuar/terminar. Menú blanco, amarillo solo en hover, foco visible y alto contraste alternativo. No restaurar amenazas/T.
- Contenedores nativos, texto ampliado, teclado/ratón, Escape y retorno de foco. No tapar casillas o Comenzar. Probar ventana pequeña y texto 150% al cambiar diseño.
- Recursos originales, créditos y manifiestos conservados. No reimportar para reemplazar hashes publicados. Sin descargas al jugar.
- Scripts pertinentes de `../package.json`. Cambios Godot: lint/validación y pruebas útiles; distinguir 65 avisos históricos de nuevas incidencias. Los ensayos automáticos no acreditan diversión, lector audible ni hardware externo.
- Exportación desde la raíz, `GODOT_BIN` y plantillas 4.7.2. Paquetes en `../releases` respecto al repo; QA en `../../work`. No EXE/ZIP/cachés/claves en Git.
- Cierre: diff, evidencia y commit/push privado autorizado; sin publicación ni mensajes a terceros.

[Instrucciones históricas](../docs/history/AGENTS_GODOT_2026-10-27.md): las cifras de muestras antiguas no son requisitos vigentes.
