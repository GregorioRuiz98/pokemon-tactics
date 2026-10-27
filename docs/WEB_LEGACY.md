# Prototipo web 0.12.0 — histórico

TypeScript, Phaser y Vite. Independiente de Windows y de su guardado. Se conserva para portfolio, pruebas y procedencia; no trasladar automáticamente sus reglas a la campaña nativa.

## Desarrollo

Node 24, desde raíz:

```sh
npm ci
npm run dev
```

Abrir `http://127.0.0.1:5173/`. `npm test`, `npm run verify:assets` y `npm run build` verifican reglas, recursos y compilación; `npm run preview` sirve en 4173. Pruebas de navegador: servidor activo y Playwright/Edge según el script.

Empieza con tres compañeros aleatorios,28 especies y dos finales excluyentes. Usa PT por movimiento y otra progresión. Windows usa un inicial de Oak y finales consecutivos; [reglas actuales](REGLAS_ACTUALES.md).

Código `src/`, recursos `public/`, pruebas `tests/`. No borrarlos: importadores, hashes y fixtures nativos reutilizan referencias. Guardados web en localStorage; no se sincronizan con Windows.

[README anterior](history/README_2026-10-27.md) · [Arquitectura web](history/ARCHITECTURE_WEB_2026-10-27.md) · [Despliegue histórico](history/DEPLOY_WEB_2026-10-27.md) · [Créditos](../CREDITS.md).
