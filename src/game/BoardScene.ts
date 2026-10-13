import * as Phaser from 'phaser';
import type { PokemonSpecies, AnimationName } from '../data/catalog';
import { facingFrom, TRAINING_BOARD } from '../rules/movement';
import type { Unit, Point, Board } from '../rules/movement';

const center = (p: Point) => ({ x: p.x * 64 + 32, y: p.y * 64 + 43 });
export class BoardScene extends Phaser.Scene {
  private sprites = new Map<
    number,
    Phaser.GameObjects.Sprite | Phaser.GameObjects.Text
  >();
  private missing: string[] = [];
  private loaded = false;
  private paused = false;
  private positions: Unit[] = [];
  constructor(
    private readonly catalog: PokemonSpecies[],
    private readonly callbacks: {
      progress: (value: number) => void;
      ready: (missing: string[]) => void;
    },
    private readonly board: Board = TRAINING_BOARD,
  ) {
    super('Board');
  }
  preload(): void {
    this.load.on('progress', (value: number) => this.callbacks.progress(value));
    this.load.on('loaderror', (file: Phaser.Loader.File) =>
      this.missing.push(file.key),
    );
    for (const pokemon of this.catalog)
      for (const name of ['Idle', 'Walk'] as const) {
        const data = pokemon.animations[name];
        this.load.spritesheet(
          `${pokemon.id}-${name}`,
          `${import.meta.env.BASE_URL}${data.path}`,
          { frameWidth: data.width, frameHeight: data.height },
        );
      }
  }
  create(): void {
    const g = this.add.graphics();
    this.board.forEach((row, y) =>
      row.forEach((tile, x) => {
        const px = x * 64,
          py = y * 64;
        const color =
          tile === 2
            ? 0x59605b
            : tile === 3
              ? 0x386d7c
              : tile === 1
                ? 0x496546
                : (x + y) % 2
                  ? 0x8b9673
                  : 0x949e7c;
        g.fillStyle(color).fillRect(px, py, 64, 64);
        g.lineStyle(1, 0x172827, 0.22).strokeRect(px, py, 64, 64);
        if (tile === 2) {
          g.fillStyle(0x303e3a).fillRoundedRect(px + 8, py + 18, 48, 38, 8);
          g.fillStyle(0x858a79).fillRoundedRect(px + 10, py + 10, 42, 35, 9);
          g.lineStyle(2, 0xb2b39b, 0.6).lineBetween(
            px + 18,
            py + 17,
            px + 36,
            py + 15,
          );
        } else if (tile === 3) {
          g.lineStyle(2, 0x9ac4bc, 0.45);
          for (let i = 0; i < 3; i++)
            g.lineBetween(
              px + 10 + (i % 2) * 12,
              py + 16 + i * 16,
              px + 34 + (i % 2) * 12,
              py + 16 + i * 16,
            );
        } else {
          g.lineStyle(2, tile === 1 ? 0x93ac69 : 0x647952, 0.65);
          for (let i = 0; i < (tile === 1 ? 9 : 3); i++) {
            const tx = px + 10 + ((i * 19 + x * 7) % 44),
              ty = py + 14 + ((i * 13 + y * 5) % 40);
            g.lineBetween(tx - 3, ty - 5, tx, ty).lineBetween(
              tx,
              ty,
              tx + 3,
              ty - 7,
            );
          }
        }
      }),
    );
    for (const pokemon of this.catalog) {
      for (const name of ['Idle', 'Walk'] as const) {
        const data = pokemon.animations[name],
          texture = `${pokemon.id}-${name}`;
        if (!this.textures.exists(texture)) continue;
        for (let direction = 0; direction < 8; direction++)
          this.anims.create({
            key: `${texture}-${direction}`,
            frames: data.durations.map((duration, frame) => ({
              key: texture,
              frame: direction * data.columns + frame,
              duration: (duration * 1000) / 60 - 1,
            })),
            frameRate: 1000,
            repeat: -1,
          });
      }
      const sprite = this.textures.exists(`${pokemon.id}-Idle`)
        ? this.add.sprite(0, 0, `${pokemon.id}-Idle`).setScale(2)
        : this.add
            .text(0, 0, '?', { fontSize: '26px', color: '#172827' })
            .setOrigin(0.5, 1);
      this.sprites.set(pokemon.id, sprite);
    }
    this.loaded = true;
    this.sync(this.positions);
    this.callbacks.ready(this.missing);
  }
  private pose(id: number, name: AnimationName, direction: number): void {
    const sprite = this.sprites.get(id);
    if (!(sprite instanceof Phaser.GameObjects.Sprite)) return;
    const actual = this.textures.exists(`${id}-${name}`) ? name : 'Idle';
    const data = this.catalog.find((p) => p.id === id)!.animations[actual];
    sprite.setOrigin(data.anchorX / data.width, data.anchorY / data.height);
    sprite.play(`${id}-${actual}-${direction}`, true);
    if (this.paused) sprite.anims.pause();
    else sprite.anims.resume();
  }
  sync(units: Unit[]): void {
    this.positions = units;
    if (!this.loaded) return;
    const visible = new Set(units.map((unit) => unit.id));
    for (const [id, sprite] of this.sprites) sprite.setVisible(visible.has(id));
    for (const unit of units) {
      const p = center(unit);
      this.sprites
        .get(unit.id)
        ?.setPosition(p.x, p.y)
        .setDepth(unit.y + 1);
      this.pose(unit.id, 'Idle', unit.facing);
    }
  }
  setPaused(value: boolean): void {
    this.paused = value;
    if (value) this.tweens.pauseAll();
    else this.tweens.resumeAll();
    for (const sprite of this.sprites.values())
      if (sprite instanceof Phaser.GameObjects.Sprite) {
        if (value) sprite.anims.pause();
        else sprite.anims.resume();
      }
  }
  async move(id: number, path: Point[], instant: boolean): Promise<void> {
    const sprite = this.sprites.get(id);
    if (!sprite || instant) return;
    for (let i = 1; i < path.length; i++) {
      this.pose(id, 'Walk', facingFrom(path[i - 1], path[i]));
      sprite.setDepth(Math.max(path[i].y, path[i - 1].y) + 1);
      await new Promise<void>((resolve) =>
        this.tweens.add({
          targets: sprite,
          ...center(path[i]),
          duration: 145,
          ease: 'Linear',
          onComplete: () => resolve(),
        }),
      );
    }
  }
  async hit(id: number, instant: boolean): Promise<void> {
    const sprite = this.sprites.get(id);
    if (!sprite || instant) return;
    await new Promise<void>((resolve) =>
      this.tweens.add({
        targets: sprite,
        alpha: 0.3,
        duration: 90,
        yoyo: true,
        repeat: 1,
        onComplete: () => {
          sprite.setAlpha(1);
          resolve();
        },
      }),
    );
  }
}
