"""Check attribution, PCM integrity and immutable input hashes without networking."""
from pathlib import Path
import json,hashlib,wave
root=Path(__file__).resolve().parents[2]
manifest=json.loads((root/'godot/assets/original-moves/manifest.json').read_text(encoding='utf-8'))
assert len(manifest['files'])==40 and len({x['id'] for x in manifest['files']})==40
assert manifest['commit']=='edc3ffb06439b01a1f9ba31272b0bb187712dff0'
assert not manifest['unavailable']
for entry in manifest['files']:
    path=root/'godot'/entry['path'].removeprefix('res://')
    data=path.read_bytes()
    assert len(data)==entry['bytes'] and hashlib.sha256(data).hexdigest()==entry['sha256'],entry['id']
    assert manifest['commit'] in entry['url'] and entry['source'].endswith('.wav')
    with wave.open(str(path)) as sound:
        assert sound.getnchannels()==entry['channels'] and sound.getsampwidth()==2
        assert sound.getframerate()==entry['sampleRate'] and abs(sound.getnframes()/sound.getframerate()-entry['duration'])<0.00001
    assert entry['gainDb']<=-10
    settings=Path(str(path)+'.import').read_text(encoding='utf-8')
    assert 'compress/mode=0' in settings and 'edit/normalize=false' in settings and 'edit/trim=false' in settings
print(json.dumps({'originalSamples':40,'hyperBeamSha256':next(x['sha256'] for x in manifest['files'] if x['id']=='hyper-beam'),'networkUsed':False}))
