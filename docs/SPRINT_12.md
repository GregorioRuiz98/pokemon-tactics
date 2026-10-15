# Sprint 12

Versión 0.12.0.

Preparación de publicación completada según la decisión del usuario de publicar después. Compilación estática autocontenida, manifiesto de archivos con SHA-256, versión y commit; textos legal/privacidad ajustados al funcionamiento local, sin cuentas ni Firebase. Guía de alojamiento, caché, HTTPS, guardados y reversión. ZIP anterior 0.11.0 preparado para volver a una compilación compatible. No se ha seleccionado alojamiento, comprado dominio, publicado URL ni cambiado visibilidad privada. Contacto y proveedor deben concretarse antes de publicar; HTTPS público, Firefox/Safari y feedback externo pendientes. La prueba de producción completa ambos destinos desde nueva partida y recarga en combate; la instalación en /juego/ carga ambas arenas y todos los recursos comprobados. Se rechazan ediciones futuras desconocidas del guardado.

Comprobaciones ejecutadas: 93 pruebas de reglas/datos, tipos y compilación; 146 hashes de procedencia y cuatro CSV de PokéAPI. Dos campañas completas aprobadas en producción local; cinco comprobaciones de instalación limpia/subcarpeta, enlaces legal/privacidad, móvil y WAV; inventario y procedencia de 175 archivos verificados. Evidencia en docs/qa/sprint-12. Advertencia conocida del tamaño de Phaser. Sin pruebas externas con personas; el equilibrio requiere feedback del creador.

Entrega dentro del encargo conjunto del 15 de octubre. Publicación aplazada por el usuario.

## Paquetes y límites finales

La entrega está preparada para uso local y despliegue posterior, no publicada. Paquete final en `outputs/releases/pokemon-tactics-0.12.0.zip`; reversión en `outputs/releases/pokemon-tactics-0.11.0.zip`, fuera del árbol Git. `SHA256SUMS.txt` acompaña los archivos. El manifiesto dentro del paquete final registra el commit de origen y que la compilación sigue sin publicarse.

Las pruebas automáticas y las capturas no sustituyen pruebas humanas. El contacto del creador y proveedor en los textos deben completarse cuando se elija el sitio. No se afirma HTTPS o DNS verificados. Permanecen el aviso de tamaño de Phaser, compatibilidad con otros navegadores por comprobar y equilibrio sujeto a feedback. Ninguno impide probar en local ambos finales con la implementación entregada.
