"""Explicit merchant-only import from the project's pinned SpriteCollab commit."""
from pathlib import Path
import hashlib
import io
import json
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from import_resources import fetch
from vendor.pokesurvivor_sprites import parse_animdata, resolve
from PIL import Image

lock = json.loads((ROOT/'tools/sources.lock.json').read_text(encoding='utf-8'))['sprites']
destination = ROOT/'godot/assets/merchant'
destination.mkdir(parents=True, exist_ok=True)
files = []


def put(name, source):
    data = fetch(source)
    (destination/name).write_bytes(data)
    files.append({'target': 'assets/merchant/'+name, 'source': source, 'sha256': hashlib.sha256(data).hexdigest(), 'modification': 'None'})
    return data


xml = put('AnimData.xml', lock['raw']+'/sprite/0352/AnimData.xml')
animations, _ = parse_animdata(xml.decode('utf-8-sig'))
source, geometry = resolve(animations, 'Idle')
assert source and geometry and geometry['n'] > 0
sheet = put('Idle.png', lock['raw']+f'/sprite/0352/{source}-Anim.png')
image = Image.open(io.BytesIO(sheet))
assert image.width >= geometry['w']*geometry['n'] and image.height >= geometry['h']
put('sprite-credits.txt', lock['raw']+'/sprite/0352/credits.txt')
put('Normal.png', lock['raw']+'/portrait/0352/Normal.png')
put('portrait-credits.txt', lock['raw']+'/portrait/0352/credits.txt')
boxes = [image.convert('RGBA').crop((i*geometry['w'], 0, (i+1)*geometry['w'], geometry['h'])).getbbox() for i in range(geometry['n'])]
boxes = [b for b in boxes if b]
bounds = [min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes)]
manifest = {'speciesId': 352, 'role': 'Merchant only; never added to the Kanto roster', 'repository': lock['repository'], 'commit': lock['commit'], 'license': 'CC BY-NC 4.0; individual attribution in accompanying credits', 'animation': geometry, 'bounds': bounds, 'files': files}
(destination/'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'files': len(files), 'sheet': image.size, 'animation': geometry}))
