// Bootstrap adapted from phaserjs/template-vite-ts (MIT).
import { AUTO, Game, Scale } from 'phaser';
import { CampScene } from './CampScene';

export function startGame(scene: CampScene): Game {
  return new Game({
    type: AUTO, parent: 'game-container', width: 900, height: 520,
    backgroundColor: '#314b40', pixelArt: true, roundPixels: true,
    scale: { mode: Scale.FIT, autoCenter: Scale.CENTER_BOTH },
    scene: [scene], banner: false,
    input: { keyboard: false },
  });
}
