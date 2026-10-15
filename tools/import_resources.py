"""Import only sprint-0 resources, using pinned SpriteCollab and MIT PokéSurvivor helpers.

Run with Python 3.12+ and Pillow. Responses are cached; normal builds are offline.
"""
import hashlib
import io
import json
import pathlib
import time
import argparse
import urllib.request
from PIL import Image
from vendor.pokesurvivor_sprites import parse_animdata, resolve, ground_anchor

ROOT = pathlib.Path(__file__).resolve().parents[1]
LOCK = json.loads((ROOT / 'tools/sources.lock.json').read_text())
SPECIES = [1, 4, 7, 25, 12, 74, 2, 3, 5, 6, 8, 9, 26, 75, 76, 81, 43, 23, 109, 63, 96, 144, 145, 146, 150, 151]
CACHE = ROOT / 'tools/cache'
MANIFEST = []

def fetch(url):
    cache = CACHE / hashlib.sha256(url.encode()).hexdigest()
    if cache.exists():
        return cache.read_bytes()
    for attempt in range(3):
        try:
            request = urllib.request.Request(url, headers={'User-Agent': 'pokemon-tactics-sprint0'})
            with urllib.request.urlopen(request, timeout=35) as response:
                data = response.read()
            cache.parent.mkdir(parents=True, exist_ok=True)
            cache.write_bytes(data)
            return data
        except OSError:
            if attempt == 2:
                raise
            time.sleep(attempt + 1)

def write(relative, data, source, license_name, authors=None, modification='None'):
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    MANIFEST.append({'path': relative, 'source': source, 'license': license_name,
                     'authors': authors or [], 'modification': modification,
                     'sha256': hashlib.sha256(data).hexdigest()})

def formatted(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode('utf-8')

def main():
    names_raw = fetch(f"{LOCK['sprites']['raw']}/credit_names.txt").decode('utf-8-sig')
    names = {}
    for line in names_raw.splitlines()[1:]:
        parts = line.split('\t')
        if len(parts) >= 2:
            names[parts[1].strip()] = parts[0].strip() or parts[1].strip()
    species = []
    for dex in SPECIES:
        api = f'https://pokeapi.co/api/v2/pokemon/{dex}'
        species_api = f'https://pokeapi.co/api/v2/pokemon-species/{dex}'
        pokemon = json.loads(fetch(api))
        details = json.loads(fetch(species_api))
        assert dex in [144, 145, 146, 150, 151] or (not details['is_legendary'] and not details['is_mythical'])
        base = f"{LOCK['sprites']['raw']}/sprite/{dex:04d}"
        credits = fetch(f'{base}/credits.txt')
        authors = sorted({names.get(line.split('\t')[1], line.split('\t')[1])
                          for line in credits.decode('utf-8-sig').splitlines() if '\t' in line})
        xml = fetch(f'{base}/AnimData.xml')
        anims, _ = parse_animdata(xml.decode('utf-8-sig'))
        write(f'public/assets/pokemon/{dex}/credits.txt', credits, f'{base}/credits.txt',
              'SpriteCollab CC BY-NC 4.0; underlying rights retained', authors)
        write(f'public/assets/pokemon/{dex}/AnimData.xml', xml, f'{base}/AnimData.xml',
              'SpriteCollab CC BY-NC 4.0', authors)
        metadata = {}
        for animation in ['Idle', 'Walk']:
            source_name, geometry = resolve(anims, animation)
            if not geometry:
                raise ValueError(f'Missing animation: {dex} {animation}')
            url = f'{base}/{source_name}-Anim.png'
            png = fetch(url)
            shadow_url = f'{base}/{source_name}-Shadow.png'
            shadow = fetch(shadow_url)
            width, height = Image.open(io.BytesIO(png)).size
            assert width % geometry['w'] == 0 and height % geometry['h'] == 0
            columns, rows = width // geometry['w'], height // geometry['h']
            assert rows == 8 and columns >= geometry['n'] > 0
            anchor = ground_anchor(shadow, geometry['w'], geometry['h'])
            if anchor is None:
                raise ValueError(f'Missing ground anchor: {dex} {animation}')
            relative = f'public/assets/pokemon/{dex}/{animation}.png'
            write(relative, png, url, 'SpriteCollab CC BY-NC 4.0', authors)
            metadata[animation] = {'width': geometry['w'], 'height': geometry['h'],
                'columns': columns, 'rows': rows, 'frames': geometry['n'],
                'durations': geometry['d'], 'anchorX': anchor[0], 'anchorY': anchor[1],
                'path': relative.removeprefix('public/')}
            if animation == 'Idle':
                thumbnail = Image.open(io.BytesIO(png)).crop((0, 0, geometry['w'], geometry['h']))
                output = io.BytesIO()
                thumbnail.save(output, format='PNG')
                write(f'public/assets/pokemon/{dex}/thumbnail.png', output.getvalue(), url,
                      'SpriteCollab CC BY-NC 4.0', authors, 'First down-facing frame cropped; no recoloring')
        name = next((n['name'] for n in details['names'] if n['language']['name'] == 'es'), pokemon['name'].title())
        species.append({'id': dex, 'name': name,
            'types': [t['type']['name'] for t in sorted(pokemon['types'], key=lambda t: t['slot'])],
            'baseStats': {s['stat']['name']: s['base_stat'] for s in pokemon['stats']},
            'legendary': details['is_legendary'], 'mythical': details['is_mythical'],
            'animations': metadata, 'authors': authors,
            'sources': [api, species_api]})
        print(f'{name}: data, Idle, Walk and credits ready', flush=True)
    write('public/data/pokemon.json', formatted(species), 'https://pokeapi.co/api/v2 + SpriteCollab',
          'Data/characters retain their original rights', modification='Selected fields and animation metadata')
    # Include resources bootstrapped earlier, with pinned upstream locations.
    extras = [
        ('public/assets/fonts/PixelifySans.ttf', 'fonts', 'ofl/pixelifysans/PixelifySans%5Bwght%5D.ttf', 'SIL OFL 1.1'),
        ('tools/vendor/pokesurvivor_sprites.py', 'pokesurvivor', 'tools/fetch_sprites.py', 'MIT'),
    ]
    for path, key, remote, license_name in extras:
        MANIFEST.append({'path': path, 'source': f"{LOCK[key]['raw']}/{remote}", 'license': license_name,
                         'modification': 'None', 'sha256': hashlib.sha256((ROOT/path).read_bytes()).hexdigest()})
    (ROOT/'public/data/provenance.json').write_bytes(formatted({'repositories': LOCK, 'files': MANIFEST}))
    (ROOT/'public/data/credits.json').write_bytes(formatted([{'name': s['name'], 'id': s['id'], 'authors': s['authors']} for s in species]))

if __name__ == '__main__':
    main()
