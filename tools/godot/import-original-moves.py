"""Explicit import of pinned, unmodified Pokémon move samples. Never runs in game."""
from pathlib import Path
from urllib.request import urlopen, Request
from urllib.parse import quote
from concurrent.futures import ThreadPoolExecutor
import hashlib, json, wave, io

ROOT = Path(__file__).resolve().parents[2]
REPO = 'AxelLoquendo/PokeDot-Engine'
COMMIT = 'edc3ffb06439b01a1f9ba31272b0bb187712dff0'
MOVES = {
    'hyper-beam':'Hyper Beam', 'ice-beam':'Ice Beam', 'solar-beam':'Solar Beam1',
    'thunderbolt':'Thunderbolt1', 'thunder':'Thunder', 'psychic':'Psychic',
    'flamethrower':'Flamethrower', 'fire-blast':'Fire Blast', 'surf':'Surf',
    'hydro-pump':'Hydro Pump', 'earthquake':'Earthquake', 'explosion':'Explosion',
    'blizzard':'Blizzard', 'aurora-beam':'Aurora Beam', 'bubble-beam':'Bubblebeam',
    'bubble':'Bubble', 'barrier':'Barrier', 'teleport':'Teleport', 'recover':'Recover',
    'smokescreen':'Smokescreen', 'vine-whip':'Vine Whip', 'razor-leaf':'Razor Leaf1',
    'dragon-rage':'Dragon Rage', 'shadow-ball':'Shadow Ball1', 'swords-dance':'Swords Dance1',
    'sing':'Sing', 'metronome':'Metronome', 'whirlwind':'Whirlwind', 'roar':'Roar',
    'fire-spin':'Fire Spin', 'confusion':'Confusion', 'water-gun':'Water Gun',
    'thunder-wave':'Thunder Wave', 'thunder-shock':'Thundershock', 'gust':'Gust',
    'mist':'Mist', 'haze':'Haze', 'poison-gas':'Poison Gas', 'dig':'Dig1', 'fly':'Fly1',
}
DEST = ROOT/'godot/assets/original-moves'

def fetch(pair):
    identity, name = pair
    source = f'sfx/se/anim/PRSFX- {name}.wav'
    url = f'https://raw.githubusercontent.com/{REPO}/{COMMIT}/'+quote(source)
    target = DEST/(identity+'.wav')
    if target.exists(): data = target.read_bytes()
    else:
        try:
            with urlopen(Request(url,headers={'User-Agent':'PokemonTactics-asset-import'}),timeout=45) as response: data=response.read()
        except Exception as exc: return {'id':identity,'unavailable':str(exc),'url':url}
    with wave.open(io.BytesIO(data)) as sample:
        assert sample.getnchannels() in (1,2) and sample.getsampwidth()==2
        duration = sample.getnframes()/sample.getframerate()
        assert 0.03 < duration < 15
        info = {'sampleRate':sample.getframerate(),'channels':sample.getnchannels(),'duration':duration}
    target.write_bytes(data)
    settings=Path(str(target)+'.import')
    if settings.exists():settings.write_text(settings.read_text(encoding='utf-8').replace('compress/mode=2','compress/mode=0'),encoding='utf-8')
    return {'id':identity,'path':'res://assets/original-moves/'+target.name,'source':source,'url':url,'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'gainDb':-10,**info}

def main():
    DEST.mkdir(parents=True,exist_ok=True)
    with ThreadPoolExecutor(max_workers=4) as executor: results=list(executor.map(fetch,MOVES.items()))
    files=[x for x in results if 'unavailable' not in x]
    assert any(x['id']=='hyper-beam' for x in files),'Hyper Beam is mandatory'
    manifest={'repository':REPO,'commit':COMMIT,'rights':'Pokémon audio: GAME FREAK / Nintendo / Creatures. Public availability is not an audio license; repository code licenses do not relicense these recordings. Exact game/version not independently verified. Samples kept byte-for-byte; runtime volume only.','files':files,'unavailable':[x for x in results if 'unavailable' in x]}
    (DEST/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'downloaded':len(files),'missing':[x['id'] for x in manifest['unavailable']]}))

if __name__=='__main__': main()
