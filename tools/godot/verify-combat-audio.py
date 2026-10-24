"""Check the local, generated combat sound bank without playing or changing it."""
from pathlib import Path
import array
import hashlib
import json
import math
import wave

root = Path(__file__).resolve().parents[2]
manifest = json.loads((root / 'godot/assets/combat/manifest.json').read_text(encoding='utf-8'))
records = []
assert len(manifest['files']) == 26
assert len({item['id'] for item in manifest['files']}) == 26
for source in manifest['source']['files']:
    assert hashlib.sha256((root / 'tools/vendor/jsfxr' / source['file']).read_bytes()).hexdigest() == source['sha256']
for item in manifest['files']:
    path = root / 'godot' / item['path'].removeprefix('res://')
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], path
    with wave.open(str(path)) as wav:
        assert (wav.getsampwidth(), wav.getnchannels(), wav.getframerate()) == (2, 1, 44100), path
        samples = array.array('h', wav.readframes(wav.getnframes()))
        duration = len(samples) / wav.getframerate()
    peak = max(abs(value) for value in samples) / 32768
    rms = math.sqrt(sum((value / 32768) ** 2 for value in samples) / len(samples))
    assert 0.04 < duration < 0.8 and 0.001 < rms and 0 < peak <= 0.201, path
    assert samples[0] == 0 and samples[-1] == 0, path
    settings = path.with_suffix('.wav.import')
    if settings.exists():
        assert 'edit/normalize=false' in settings.read_text(encoding='utf-8'), path
    records.append({'id': item['id'], 'duration': round(duration, 4), 'peak': round(peak, 4), 'rms': round(rms, 4)})
print(json.dumps({'sounds': len(records), 'passed': True, 'files': records}))
