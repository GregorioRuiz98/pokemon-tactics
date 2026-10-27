"""Explicit, pinned import of unmodified Pokemon UI sprites; default is offline verification."""
from pathlib import Path
import hashlib
import json
import struct
import sys
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'godot/assets/ui-symbols'
COMMIT = 'c5aaa610ff2acdf7fd8e2dccd181bca8be9fcb3e'
REPO = 'https://github.com/msikma/pokesprite'
TYPES = 'normal fire water electric grass ice fighting poison ground flying psychic bug rock ghost dragon dark steel fairy'.split()


def verify():
    manifest = json.loads((DEST / 'manifest.json').read_text(encoding='utf-8'))
    assert manifest['commit'] == COMMIT
    assert len(manifest['files']) == 24
    for entry in manifest['files']:
        data = (DEST / entry['target']).read_bytes()
        assert hashlib.sha256(data).hexdigest() == entry['sha256'], entry['target']
        if entry['target'].endswith('.png'):
            assert data[:8] == b'\x89PNG\r\n\x1a\n'
            assert list(struct.unpack('>II', data[16:24])) == entry['size']
    print(json.dumps({'verified': len(manifest['files']), 'icons': 21, 'commit': COMMIT}))


if '--download' in sys.argv:
    sources = [(f'misc/types/gen8/{kind}.png', f'types/{kind}.png') for kind in TYPES]
    sources += [(f'misc/seals/gen8/move-{kind}.png', f'categories/{kind}.png') for kind in ['physical', 'special', 'status']]
    sources += [(name, f'source/{name}') for name in ['license.md', 'contributors.md', 'readme.md']]
    files = []
    for source, target in sources:
        url = f'https://raw.githubusercontent.com/msikma/pokesprite/{COMMIT}/{source}'
        request = urllib.request.Request(url, headers={'User-Agent': 'PokemonTactics-explicit-asset-import'})
        data = urllib.request.urlopen(request, timeout=30).read()
        path = DEST / target
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        entry = {'source': source, 'target': target, 'url': url, 'sha256': hashlib.sha256(data).hexdigest()}
        if target.endswith('.png'):
            assert data[:8] == b'\x89PNG\r\n\x1a\n'
            entry['size'] = list(struct.unpack('>II', data[16:24]))
        files.append(entry)
    (DEST / 'manifest.json').write_text(json.dumps({'repository': REPO, 'commit': COMMIT, 'files': files}, indent=2)+'\n', encoding='utf-8')
    (DEST / 'CREDITS.md').write_text('''# Iconos de tipos y categorías

21 PNG originales, sin modificar, procedentes de PokéSprite, mantenido por
msikma y sus colaboradores: https://github.com/msikma/pokesprite
Commit: c5aaa610ff2acdf7fd8e2dccd181bca8be9fcb3e.

Tipos y categorías de movimiento de octava generación. Derechos de las imágenes:
Nintendo / Creatures Inc. / GAME FREAK inc. No se presentan como recursos CC0 ni
como imágenes bajo MIT. La licencia MIT del repositorio se refiere al código y
otro contenido; se conserva el aviso original en source/license.md y los créditos
en source/contributors.md y source/readme.md. Este proyecto de fans no está
afiliado a los titulares. Importación explícita; el juego no consulta la red.
Rutas originales, dimensiones y SHA-256 individuales: manifest.json.
''', encoding='utf-8')
verify()
