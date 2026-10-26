"""Package the player-facing UI release after source and executable checks."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
VERSION = '0.26.0'
BASELINE = '60ea4c76b689757837e4d6f68ec04b08ef0684b3'
WORK = (ROOT / '../../work/qa-sprint-26').resolve()
RELEASE = (ROOT / f'../releases/pokemon-tactics-{VERSION}').resolve()
BUNDLE = RELEASE / 'windows'
EXE = BUNDLE / 'PokemonTactics.exe'
EVIDENCE = ROOT / 'docs/qa/sprint-26'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert EXE.is_file() and f'config/version="{VERSION}"' in (ROOT/'godot/project.godot').read_text(encoding='utf-8')
    protected = ['godot/core', 'godot/data', 'godot/tests', 'godot/assets', 'godot/art', 'src', 'public', 'tests', 'CREDITS.md']
    subprocess.run(['git', 'diff', '--exit-code', BASELINE, '--', *protected], cwd=ROOT, check=True, capture_output=True)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    counts = {}
    for suite, filename, minimum in [('player', 'player-ui-result.json', 719), ('moves', 'moves-ui-result.json', 304), ('spatial', 'spatial-ui-result.json', 55), ('economy', 'economy-ui-result.json', 57), ('adventure', 'adventure-ui-result.json', 100)]:
        pair = []
        for side in ['source', 'release']:
            path = WORK/f'{suite}-{side}'/filename
            if side == 'release':
                assert path.stat().st_mtime >= EXE.stat().st_mtime, 'QA predates executable'
            report = read(path)
            assert not report['failures'] and report['assertions'] >= minimum, suite
            shutil.copy2(path, EVIDENCE/f'{suite}-{side}.json')
            pair.append(report)
        if suite == 'player':
            for key in ['assertions', 'stateHash', 'naturalPhase', 'catalog', 'campaignEdition']:
                assert pair[0][key] == pair[1][key], (suite, key)
            assert pair[0]['naturalPhase'] == 'shop' and pair[0]['catalog'] == 211 and pair[0]['campaignEdition'] == 21
        elif suite == 'adventure':
            for key in ['assertions', 'naturalStateHash', 'journalHash', 'gyms', 'edition', 'combatEdition']:
                assert pair[0][key] == pair[1][key], (suite, key)
            assert pair[0]['edition'] == 21 and pair[0]['combatEdition'] == 19
        else:
            assert pair[0] == pair[1], suite
        counts[suite] = pair[0]['assertions']
    core = read(WORK/'adventure-result.json')
    assert not core['failures'] and core['checks'] >= 105
    shutil.copy2(WORK/'adventure-result.json', EVIDENCE/'core-adventure.json')
    validation = read(WORK/'validation.json')
    lint = read(WORK/'lint.json')
    assert validation['ok'] and validation['counts']['errors'] == 0 and validation['counts']['warnings'] == 65 and lint['ok']
    for filename in ['oak-1024-150.png', 'move-dialog.png', 'moves-1024-150.png', 'abilities-power.png', 'combat-power.png', 'shop-power.png']:
        shutil.copy2(WORK/'player-source'/filename, EVIDENCE/filename)
    documentation = BUNDLE/'Documentacion'
    documentation.mkdir(exist_ok=True)
    for name in ['GUIA_DE_PRUEBA.md', 'INFORME_BALANCE.md', 'BALANCE_RESULTADOS.json']:
        path = BUNDLE/name
        if path.is_file():
            path.replace(documentation/name)
    shutil.copy2(ROOT/'docs/SPRINT_26_PLAYER.md', documentation/'CAMBIOS_0.26.md')
    verification = {'version': VERSION, 'baseline': BASELINE, 'unchanged': protected, 'campaignEdition': 21, 'combatEdition': 19, 'errors': 0, 'warnings': 65, 'newWarnings': 0, 'coreChecks': core['checks'], 'uiChecksPerBuild': counts, 'moveDefinitions': 211, 'sourceAndExeNaturalReplayMatch': True, 'fullCampaignRerun': False, 'balanceChanged': False, 'playerProfileImplemented': False, 'publicDeployment': False}
    for path in [EVIDENCE/'verification.json', documentation/'QA_0.26.json']:
        path.write_text(json.dumps(verification, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    (BUNDLE/'LEEME.txt').write_text('''Pokémon Tactics — Aventura por Kanto

Extrae esta carpeta y abre PokemonTactics.exe. No necesitas instalar Godot, navegador ni servidor.

Nueva aventura: elige tu inicial de Oak y comienza. La semilla se genera automáticamente.
Opciones de partida permite introducir una semilla o un código de reto compartido.
Continuar aventura recupera tu equipo y tu recorrido.

En combate: clic en una casilla azul para moverte; clic en un rival para el básico.
Habilidades abre tus movimientos. Sus fichas muestran potencia, precisión, coste y alcance.
R rectifica solo el movimiento antes de actuar. F elige orientación y termina el turno.
Flechas y Enter también permiten jugar; Escape cancela. F2 abre los controles.
Las etiquetas se actualizan si reasignas las teclas. Hay opciones de texto, contraste y movimiento reducido.

Puedes preparar cuatro movimientos además del básico sin tipo. La potencia base es distinta del daño previsto.
El daño previsto al apuntar considera al rival, los tipos, la orientación y los efectos del tablero.
Usa la tienda y la bolsa para preparar al equipo entre encuentros. Revivir recupera la mitad de los PS.
Perder un combate termina la aventura aunque queden Pokémon en el PC.

La partida se guarda automáticamente en %APPDATA%/PokemonTacticsLab/kanto-save.json.
Las opciones de control y presentación se conservan por separado.
La carpeta Documentacion contiene notas de versión y comprobaciones de desarrollo.

Proyecto de fans. Créditos y licencias incluidos. Sin conexión a Internet durante el juego.
''', encoding='utf-8')
    archive = RELEASE/f'pokemon-tactics-{VERSION}-windows.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        for path in sorted(BUNDLE.rglob('*')):
            if path.is_file():
                package.write(path, Path('windows')/path.relative_to(BUNDLE))
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None
    fingerprint = hashlib.sha256()
    for path in sorted((ROOT/'godot').rglob('*')):
        if path.is_file() and '.godot' not in path.parts:
            fingerprint.update(path.relative_to(ROOT).as_posix().encode())
            fingerprint.update(path.read_bytes())
    record = {**verification, 'sourceFingerprint': fingerprint.hexdigest(), 'exe': {'bytes': EXE.stat().st_size, 'sha256': digest(EXE)}, 'zip': {'bytes': archive.stat().st_size, 'sha256': digest(archive)}}
    (EVIDENCE/'release.json').write_text(json.dumps(record, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    (RELEASE/'SHA256SUMS.txt').write_text(digest(EXE)+'  windows/PokemonTactics.exe\n'+digest(archive)+'  '+archive.name+'\n', encoding='utf-8')
    print(json.dumps(record, ensure_ascii=False))


if __name__ == '__main__':
    main()
