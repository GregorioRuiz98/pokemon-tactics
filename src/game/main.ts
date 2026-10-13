// Bootstrap adapted from phaserjs/template-vite-ts (MIT).
import { AUTO, Game, Scale, Scene } from 'phaser';

export function startGame(
  scene: Scene,
  size = { width: 900, height: 520 },
): Game {
  return new Game({
    type: AUTO,
    parent: 'game-container',
    ...size,
    backgroundColor: '#314b40',
    pixelArt: true,
    roundPixels: true,
    scale: { mode: Scale.FIT, autoCenter: Scale.CENTER_BOTH },
    scene: [scene],
    banner: false,
    input: { keyboard: false },
  });
}
