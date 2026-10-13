import * as Phaser from 'phaser';
import type { AnimationName, PokemonSpecies } from '../data/catalog';

type Callbacks = {
  select: (id: number) => void;
  progress: (fraction: number) => void;
  ready: (missing: string[]) => void;
};

export class CampScene extends Phaser.Scene {
  private readonly units = new Map<number, Phaser.GameObjects.Sprite>();
  private readonly rings = new Map<number, Phaser.GameObjects.Ellipse>();
  private selected = 1;
  private direction = 0;
  private animation: AnimationName = 'Idle';
  private paused = false;
  private loaded = false;
  private readonly missing: string[] = [];

  constructor(private readonly catalog: PokemonSpecies[], private readonly callbacks: Callbacks) {
    super('Camp');
  }

  preload(): void {
    this.load.on('progress', (value: number) => this.callbacks.progress(value));
    this.load.on('loaderror', (file: Phaser.Loader.File) => this.missing.push(file.key));
    for (const pokemon of this.catalog) {
      for (const name of ['Idle', 'Walk'] as const) {
        const animation = pokemon.animations[name];
        this.load.spritesheet(`${pokemon.id}-${name}`, `${import.meta.env.BASE_URL}${animation.path}`, {
          frameWidth: animation.width, frameHeight: animation.height,
        });
      }
    }
  }

  create(): void {
    this.drawCamp();
    this.catalog.forEach((pokemon, index) => {
      const x = 165 + (index % 3) * 285;
      const y = index < 3 ? 190 : 395;
      this.add.ellipse(x, y + 9, 156, 64, 0x0b1d1d, 0.25);
      this.add.ellipse(x, y, 156, 64, 0x88947a);
      this.add.ellipse(x, y - 4, 144, 56, 0xa6af90);
      const ring = this.add.ellipse(x, y - 4, 164, 70).setStrokeStyle(3, 0xf1c879).setVisible(false);
      this.rings.set(pokemon.id, ring);
      this.add.ellipse(x, y - 2, 36, 15, 0x20302d, 0.3);
      this.add.text(x, y + 51, `${String(pokemon.id).padStart(3, '0')}  ${pokemon.name}`, {
        fontFamily: 'Pixelify Sans', fontSize: '19px', color: '#e7ede0',
      }).setOrigin(0.5);
      for (const name of ['Idle', 'Walk'] as const) {
        const data = pokemon.animations[name];
        const texture = `${pokemon.id}-${name}`;
        if (!this.textures.exists(texture)) continue;
        for (let direction = 0; direction < 8; direction++) {
          this.anims.create({
            key: `${texture}-${direction}`,
            frames: data.durations.map((duration, frame) => ({
              key: texture, frame: direction * data.columns + frame,
              // PMD durations use 60 ticks per second. Frame duration adds to the base frame time.
              duration: duration * 1000 / 60 - 1,
            })),
            frameRate: 1000, repeat: -1,
          });
        }
      }
      const texture = `${pokemon.id}-Idle`;
      if (this.textures.exists(texture)) {
        const sprite = this.add.sprite(x, y - 5, texture).setScale(3);
        this.units.set(pokemon.id, sprite);
      } else {
        this.add.text(x, y - 14, '?', { color: '#fff0c7', fontSize: '32px' }).setOrigin(0.5);
      }
      this.add.zone(x, y - 12, 200, 165).setInteractive({ useHandCursor: true })
        .on('pointerdown', () => this.callbacks.select(pokemon.id));
    });
    this.loaded = true;
    this.refresh();
    this.callbacks.ready(this.missing);
  }

  private drawCamp(): void {
    const graphics = this.add.graphics();
    graphics.fillStyle(0x314b40).fillRect(0, 0, 900, 520);
    graphics.fillStyle(0x3a5547).fillRoundedRect(40, 55, 820, 420, 90);
    graphics.lineStyle(1, 0xadc6a2, 0.12).strokeRoundedRect(55, 70, 790, 390, 80);
    // Small deterministic details: a static assembly clearing, not a tactical map.
    for (let i = 0; i < 95; i++) {
      const x = (i * 173 + 31) % 900;
      const y = (i * 97 + 11) % 520;
      graphics.fillStyle(i % 3 ? 0x4d6950 : 0x72815a, 0.6);
      graphics.fillRect(x, y, 3, 6).fillRect(x + 5, y - 3, 3, 9);
    }
    graphics.lineStyle(18, 0xb9b293, 0.08).lineBetween(30, 283, 870, 283);
    graphics.lineStyle(1, 0xe1d6a8, 0.14).lineBetween(60, 283, 840, 283);
    this.add.text(28, 22, 'KANTO / ZONA DE REUNIÓN', {
      fontFamily: 'monospace', fontSize: '12px', color: '#b7c7b0', letterSpacing: 2,
    });
    this.add.text(870, 487, 'N ↑', { fontFamily: 'monospace', fontSize: '13px', color: '#b7c7b0' }).setOrigin(1, 0);
  }

  configure(id: number, animation: AnimationName, direction: number, paused: boolean): void {
    this.selected = id;
    this.animation = animation;
    this.direction = direction;
    this.paused = paused;
    if (this.loaded) this.refresh();
  }

  private refresh(): void {
    for (const pokemon of this.catalog) {
      this.rings.get(pokemon.id)?.setVisible(pokemon.id === this.selected);
      const sprite = this.units.get(pokemon.id);
      if (!sprite) continue;
      const requested = pokemon.id === this.selected ? this.animation : 'Idle';
      const name = this.textures.exists(`${pokemon.id}-${requested}`) ? requested : 'Idle';
      const direction = pokemon.id === this.selected ? this.direction : 0;
      const data = pokemon.animations[name];
      sprite.setOrigin(data.anchorX / data.width, data.anchorY / data.height);
      sprite.play(`${pokemon.id}-${name}-${direction}`, true);
      if (this.paused) sprite.anims.pause();
      else sprite.anims.resume();
    }
  }
}
