# Publicación preparada; despliegue aplazado

El usuario ha decidido preparar la versión y publicar después. No se ha contratado alojamiento, comprado dominio, publicado una URL ni cambiado la visibilidad privada del repositorio. Falta elegir proveedor, dominio/presupuesto y contacto público del creador. HTTPS y funcionamiento en una URL pública siguen pendientes de esa decisión.

## Compilación estática

```sh
npm ci
npm test
npm run verify:assets
npm run build
npm run release:prepare
npm run verify:build
npm run preview
```

Node 24 en desarrollo; el servidor de destino solo necesita servir archivos estáticos. La carpeta `dist` contiene juego, catálogo, sprites, sonido, fuente, créditos, licencias y páginas legal/privacidad. No requiere backend, base de datos, API keys o variables secretas. `release-manifest.json` registra versión, commit, estado del árbol, inventario y SHA-256 de los archivos.

Se entrega un ZIP de la versión preparada y otro de la 0.11.0 como reversión. Descomprimir y subir **el contenido** a la carpeta web elegida, con `index.html` en su raíz. No subir `node_modules`, repositorio, herramientas ni claves. Mantener las licencias y créditos del paquete. No funciona abriendo `index.html` por `file://`: usar servidor HTTP/HTTPS.

`base: './'` permite una raíz o subcarpeta, por ejemplo `/juego/`. Las vistas usan parámetros de consulta, sin rutas de servidor adicionales. No hace falta una regla SPA que reescriba los recursos inexistentes hacia HTML.

## Configuración del alojamiento

- Habilitar HTTPS con el dominio definitivo y servir tipos MIME correctos para JS, CSS, JSON, PNG, WAV, fuentes y WebM si se publica material del portfolio.
- Evitar caché larga para `index.html`, `release.json`, `release-manifest.json`, `data/*`, créditos y textos legales. Las referencias de sprites no llevan hash en su nombre; tampoco deben permanecer inmutables entre versiones.
- Los archivos de `assets/` que Vite nombra con hash pueden usar caché prolongada; no extender esa regla automáticamente a los sprites con rutas estables.
- Conservar una carpeta o ZIP de cada compilación. Sustituir la versión completa de forma atómica o cambiar el directorio publicado para evitar mezclar catálogo y sprites de entregas distintas.
- Completar contacto y proveedor real en `legal.html`/`privacy.html` antes de publicar. Si se incorpora analítica, cuentas, pagos o servicios, revisar esos textos y la implementación.

## Comprobación antes y después de publicar

En navegador limpio: abrir menú, empezar, comprar/reclutar, combatir y recargar. Verificar sprites, sonidos con volumen, teclado, móvil y textos legales. La comprobación automatizada completa puede apuntar a una URL con `TACTICS_URL` y `npm run test:browser:release`; juega en contextos nuevos y no toca la partida del navegador del creador. Validar ambos finales y revisar consola/peticiones fallidas.

La compilación preparada se ha comprobado localmente en raíz y subcarpeta. No se presenta como una comprobación de HTTPS, DNS o un proveedor público. Edge/Chromium es el navegador comprobado; Firefox/Safari y pruebas con jugadores quedan pendientes.

## Guardados y reversión

La partida y volumen viven en localStorage del origen. `localhost:5173`, `127.0.0.1:4173` y un dominio público tienen datos independientes. No se sincronizan ni se transfieren automáticamente.

Esquema 3, edición 14 de campaña. Las migraciones de esquemas 1/2 conservan copia local; las partidas previas continúan sus reglas. Las versiones 0.11.0 y 0.12.0 comparten formato y reglas, por lo que se puede restaurar la compilación 0.11.0 sin reiniciar sus partidas. Para una versión futura incompatible, no degradar el formato de guardado automáticamente: preservar/exportar los datos y documentar la migración.

Para revertir, volver a servir el contenido completo del ZIP 0.11.0, invalidar caché de HTML/datos/sprites y comprobar una partida conservada. El repositorio también mantiene `codex/sprint-11`. El ZIP anterior se compiló desde el commit `8843aaf455793645f9ff0d244d18b8b5d177440e`; SHA-256 del archivo: `7D1695033DF523AE83DF63F031356C2A514D926173DACBB8AE6B2A9089DA62ED`.
