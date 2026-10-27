"""Package the finishing sprints from checked native source/executable evidence."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
VERSION = re.search(r'config/version="([^"]+)"', (ROOT/'godot/project.godot').read_text(encoding='utf-8'))[1]
CHAPTER = int(VERSION.split('.')[1])
CONFIG = {
    34: {'baseline':'071a21553bcc2b6c28b046c3199f53c5ec87f77f','report':'SPRINT_34_TACTICAL_QUALITY.md','ui':{'quality':204,'briefing':398,'review':46},'core':{'quality':6939},'edition':27},
    33: {'baseline':'51994283bd98575d56677cbb5703538dee292621','report':'SPRINT_33_REVIEW.md','ui':{'review':46,'climate':112,'playthrough':15000,'symbols':270,'sleep':15},'core':{'review':505},'edition':26},
    32: {'baseline':'aa18d6fbe039ec8c230db0c8b645a6f892e294db','report':'SPRINT_32_CLIMATE.md','ui':{'climate':112,'symbols':270,'sleep':15},'core':{'climate':487},'edition':25},
    31: {'baseline':'7ae0893684e2f72f65593b00f41c693dfdfd73f3','report':'SPRINT_31_POWER.md','ui':{'power':233,'copy':503},'core':{'power':1602},'edition':23},
    30: {'baseline':'99e74e8c8df880f4a2657bf7084b081c8d2e0de4','report':'SPRINT_30_KANTO.md','ui':{'kanto':428,'player':719},'core':{'kanto':7626,'trainer':120,'adventure':105},'edition':22},
    29: {'baseline': '8bbe5dcd078a50bca7140b8858eae77e5d9685a7', 'report': 'SPRINT_29_VARIETY.md', 'ui': {'variety': 72, 'shop': 70, 'trainer': 69, 'player': 719, 'moves': 304}, 'core': {'variety': 7428, 'trainer': 120, 'adventure': 105}, 'edition': 21},
    28: {'baseline': '9d87cd1091815f72525ec66a4d4752065579c2f4', 'report': 'SPRINT_28_KECLEON.md', 'ui': {'shop': 70, 'trainer': 69, 'player': 719}, 'core': {'trainer': 120, 'adventure': 105}, 'edition': 21},
    27: {'baseline': 'be221c89082013c288adf3e28bb8acfb872e1474', 'report': 'SPRINT_27_TRAINER.md', 'ui': {'trainer': 69, 'player': 719}, 'core': {'trainer': 120, 'adventure': 105}, 'edition': 21},
}[CHAPTER]
if VERSION == '0.30.1':
    CONFIG = {'baseline':'8175544ee876251596cdb356d1bb4d20fe42fc1a','report':'FIX_TEXT_0.30.1.md','ui':{'copy':503,'kanto':428},'core':{},'edition':22}
if VERSION == '0.31.1':
    CONFIG = {'baseline':'e8eb2a8493e1f3e99e8f1f77038821c8fc89f105','report':'FIX_SLEEP_0.31.1.md','ui':{'sleep':15,'power':233},'core':{'sleep':35},'edition':24}
if VERSION == '0.31.2':
    CONFIG = {'baseline':'958c720e8e6f2b55b6f1c9921af286c949362798','report':'UI_SYMBOLS_0.31.2.md','ui':{'symbols':270,'sleep':15,'power':233},'core':{},'edition':24}
if VERSION == '0.33.1':
    CONFIG = {'baseline':'745552d96c424fbe8a5b0d4c8dbb652ae94d1744','report':'UI_BUTTONS_BRIEFING_0.33.1.md','ui':{'briefing':300,'review':46,'symbols':270},'core':{},'edition':26}
if VERSION == '0.34.1':
    CONFIG = {'baseline':'5dc4001fa2fb27afbdc350e61ff48dca6c6f8e50','report':'UI_PRECOMBAT_0.34.1.md','ui':{'briefing':1800,'review':46,'symbols':270},'core':{},'edition':27}
QA_LABEL = '34-ui-1' if VERSION == '0.34.1' else '33-ui-1' if VERSION == '0.33.1' else '31-ui-2' if VERSION == '0.31.2' else '31-ui-1' if VERSION == '0.31.1' else '30-ui-1' if VERSION == '0.30.1' else str(CHAPTER)
WORK = (ROOT/f'../../work/qa-sprint-{QA_LABEL}').resolve()
RELEASE = (ROOT/f'../releases/pokemon-tactics-{VERSION}').resolve()
BUNDLE = RELEASE/'windows'
EXE = BUNDLE/'PokemonTactics.exe'
EVIDENCE = ROOT/f'docs/qa/sprint-{QA_LABEL}'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert EXE.is_file()
    protected = ['godot/core', 'godot/data', 'godot/tests', 'godot/assets', 'godot/art', 'src', 'public', 'tests', 'CREDITS.md']
    # New modules are allowed; published rules/assets/tests cannot be overwritten.
    subprocess.run(['git', 'diff', '--exit-code', '--diff-filter=MDR', CONFIG['baseline'], '--', *protected], cwd=ROOT, check=True, capture_output=True)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    counts = {}
    for suite, minimum in CONFIG['ui'].items():
        pair = []
        for side in ['source', 'release']:
            path = WORK/f'{suite}-{side}'/f'{suite}-ui-result.json'
            if side == 'release':
                assert path.stat().st_mtime >= EXE.stat().st_mtime, 'QA predates executable'
            report = read(path)
            assert not report['failures'] and report['assertions'] >= minimum, suite
            shutil.copy2(path, EVIDENCE/f'{suite}-{side}.json')
            pair.append(report)
        for key in ['assertions', 'stateHash', 'naturalStateHash', 'journalHash', 'campaignEdition', 'profileSchema', 'mapCatalogHash', 'gallery']:
            if key in pair[0]:
                assert pair[0][key] == pair[1][key], (suite, key)
        if suite == 'kanto':
            assert pair[0]['mapCatalogHash'] == digest(ROOT/'godot/data/kanto-landscapes.json')
        counts[suite] = pair[0]['assertions']
        selected = pair[0].get('screenshots', [])[:8]
        if suite == 'quality':
            selected += [name for name in pair[0].get('screenshots', []) if name in ['sabrina.png','blaine.png','giovanni-gym.png','champion.png','legendary-birds.png','legendary-origin.png']]
        if suite == 'kanto':
            selected += [name for name in pair[0].get('screenshots', []) if name in ['legendary-birds.png','legendary-origin.png','blastoise-cannons.png']]
        if suite == 'playthrough':
            selected += [name for name in pair[0].get('screenshots', []) if name in ['legendary-birds.png','legendary-origin.png','complete-kanto.png']]
        for name in selected:
            shutil.copy2(WORK/f'{suite}-source'/name, EVIDENCE/f'{suite}-{name}')
    core = {}
    for suite, minimum in CONFIG['core'].items():
        path = WORK/f'{suite}-result.json'
        result = read(path)
        assert not result['failures'] and result['checks'] >= minimum
        shutil.copy2(path, EVIDENCE/f'core-{suite}.json')
        core[suite] = result['checks']
    validation = read(WORK/'validation.json')
    lint = read(WORK/'lint.json')
    assert validation['ok'] and validation['counts']['errors'] == 0 and validation['counts']['warnings'] == 65 and lint['ok']
    docs = BUNDLE/'Documentacion'
    docs.mkdir(exist_ok=True)
    for name in ['GUIA_DE_PRUEBA.md', 'INFORME_BALANCE.md', 'BALANCE_RESULTADOS.json']:
        path = BUNDLE/name
        if path.is_file():
            path.replace(docs/name)
    shutil.copy2(ROOT/'docs'/CONFIG['report'], docs/f'CAMBIOS_0.{CHAPTER}.md')
    if CHAPTER == 29:
        for name in ['variety-moves.csv', 'variety-opening.csv']:
            shutil.copy2(WORK/name, docs/name)
            shutil.copy2(WORK/name, EVIDENCE/name)
    verification = {'version': VERSION, 'baseline': CONFIG['baseline'], 'publishedFilesUnchanged': protected, 'campaignEdition': CONFIG['edition'], 'errors': 0, 'warnings': 65, 'newWarnings': 0, 'coreChecks': core, 'uiChecksPerBuild': counts, 'sourceAndExeStateMatch': True, 'publicDeployment': False, 'fullCampaignPlayed': False}
    if VERSION == '0.33.0':
        campaign = read(WORK/'campaign-summary.json')
        assert campaign['completeAutomated'] and campaign['locations'] == 58 and not campaign['failures']
        verification.update({'fullCampaignPlayed':True,'fullCampaignMode':'Automated legal campaign and full native UI replay','humanPlaytest':False,'externalHardwareTest':False,'campaignOrders':campaign['orders'],'campaignLocations':58})
        for name in ['campaign-summary.json','campaign-encounters.csv','recovery-observations.json','clean-startup.json']:
            shutil.copy2(WORK/name,EVIDENCE/name)
            shutil.copy2(WORK/name,docs/name)
        for folder, label in [('baseline-02','attempt-defeat'),('natural-tactical','attempt-stall'),('natural-coverage','campaign-complete')]:
            shutil.copy2(WORK/folder/'campaign-review.json',EVIDENCE/f'{label}.json')
        journal = read(WORK/'natural-coverage/campaign-journal.json')
        journal['expectedState'] = json.loads(read(WORK/'natural-coverage/natural-save.json')['payload'])['state']
        (EVIDENCE/'campaign-journal.json').write_text(json.dumps(journal,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
        startup = read(WORK/'clean-startup.json')
        assert startup['titleVisible'] and startup['godotNotOnPath'] and startup['exeSha256'] == digest(EXE)
        assert startup['diagnosticHelperPassed'] and not startup['externalHardwareTest']
        for source, target in [('REGLAS_ACTUALES.md','REGLAS_ACTUALES.md'),('PLAYTEST_WINDOWS.md','PLAYTEST_WINDOWS.md'),('PLAYTEST_WINDOWS.md','GUIA_DE_PRUEBA.md'),('SPRINT_33_REVIEW.md','SPRINT_33_REVIEW.md'),('SPRINT_32_CLIMATE.md','SPRINT_32_CLIMATE.md')]:
            shutil.copy2(ROOT/'docs'/source,docs/target)
        shutil.copy2(ROOT/'tools/godot/check-pc.cmd',BUNDLE/'Comprobar-equipo.cmd')
    if VERSION == '0.34.0':
        campaign = read(WORK/'natural-quality-07/campaign-review.json')
        assert not campaign['failures'] and campaign['phase']=='ending' and len(campaign['cleared'])==58
        verification.update({'fullCampaignPlayed':True,'fullCampaignMode':'Automated legal-command campaign','humanPlaytest':False,'externalHardwareTest':False,'campaignOrders':campaign['orders'],'campaignLocations':58})
        shutil.copy2(WORK/'attempt-01-koga'/'campaign-review.json',EVIDENCE/'attempt-01-koga.json')
        for name in ['campaign-review.json','campaign-journal.json']:
            shutil.copy2(WORK/'natural-quality-07'/name,EVIDENCE/name)
        journal = read(WORK/'natural-quality-07/campaign-journal.json')
        journal['expectedState'] = json.loads(read(WORK/'natural-quality-07/natural-save.json')['payload'])['state']
        journal['encounters'] = campaign['encounters']
        (EVIDENCE/'campaign-journal.json').write_text(json.dumps(journal,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
        shutil.copy2(WORK/'natural-quality-05/campaign-review.json',EVIDENCE/'attempt-05-birds.json')
        for name in ['MAPAS_0.34.csv','PLAYTEST_0.34.md']:
            shutil.copy2(ROOT/'docs'/name,docs/name)
        shutil.copy2(ROOT/'docs'/'SPRINT_33_REVIEW.md',docs/'SPRINT_33_REVIEW.md')
    if VERSION in ['0.31.1','0.31.2']:
        verification['sleepCorrection'] = 'Sleeping blocks movement routes and commands; old edition23 loads with backup and mixed replay.'
    for path in [EVIDENCE/'verification.json', docs/f'QA_0.{CHAPTER}.json']:
        path.write_text(json.dumps(verification, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    readme = (ROOT/'../releases/pokemon-tactics-0.26.0/windows/LEEME.txt').read_text(encoding='utf-8')
    readme += '\nPerfil de entrenador: nombre, retrato, Pokédex, historial y logros se conservan entre aventuras. Los títulos y marcos son cosméticos.\n'
    if CHAPTER >= 28:
        readme += '\nTienda Kecleon: tres ofertas, ficha antes de comprar, renovación con precio creciente y accesos a Medicina, Entrenar y Equipo. Movimiento reducido desactiva sus animaciones.\n'
    if CHAPTER == 29:
        readme += '\nEquipo → Movimientos: consulta propuestas de rol, compáralas y confirma para preparar hasta cuatro técnicas aprendidas. El básico neutro permanece. Filtra áreas, zonas, desplazamientos y apoyos; Herramientas del equipo resume tus opciones. Las MT indican qué función añaden.\n'
    if CHAPTER >= 31:
        readme += '\nPP de equipamiento: capacidad10 desde el inicio, +1 por cada5 niveles desde Nv.5, máximo20. Hasta cuatro técnicas y básico gratuito. Se paga presupuesto al preparar; no se gastan puntos en combate. Estados temporales, atributos hasta finalizar el combate. Manantiales: curan estados y confusión al terminar el turno encima, para ambos bandos, sin curar PS.\nLa actualización es voluntaria entre encuentros con copia. Todos los movimientos aprendidos se conservan; si exceden PP, se desequipan los que no caben, respetando el orden de ranuras. Presión no tiene efecto en esta edición. Códigos nuevos KT31.\n'
        price_source = WORK/'power-prices.csv' if (WORK/'power-prices.csv').exists() else (ROOT/'docs/qa/sprint-31/power-prices.csv')
        shutil.copy2(price_source,docs/'PP_MOVIMIENTOS.csv')
        shutil.copy2(price_source,EVIDENCE/'power-prices.csv')
    if CHAPTER >= 30:
        readme = readme.replace('0.26.0',VERSION)
        readme += '\nKanto:58 lugares con geometría propia en16/24 casillas, alturas y obstáculos temáticos. La maleza es transitable; árboles, rocas y muebles sólidos bloquean movimiento y visión. Las copas se atenúan ante unidades y cursor.\nLiga y rival → tres aves juntas → tienda → Mew y Mewtwo. No hay captura legendaria. La actualización es voluntaria entre encuentros, con copia; conserva victorias previas y permite completar el desafío que falte.\nSin roles predefinidos: combina cuatro técnicas aprendidas más básico neutro. Filtros, potencia, diagramas, compatibilidad de MT y herramientas del equipo se conservan. Los valores de combate/EXP/precios no han cambiado. Códigos nuevos KT30; KT25 conserva sus reglas históricas.\n'
        shutil.copy2(ROOT/'docs/reports/kanto-0.30/mapas.csv',docs/'MAPAS_KANTO.csv')
    if CHAPTER >= 31:
        readme = readme.replace('Los valores de combate/EXP/precios no han cambiado.', 'Se conservan potencia, estadísticas, EXP, precios y recompensas. La disponibilidad de acciones cambia con los PP.')
    if VERSION in ['0.31.1','0.31.2']:
        readme += '\nCorrección del sueño: un Pokémon dormido no se mueve ni actúa. Puedes orientar y terminar para que caduque el estado; al despertar recupera movimiento. Al cargar0.31.0 se aplica la corrección automáticamente, con copia y conservando combate/PS/RNG. Rectificar empieza desde ese punto. Nuevos códigos KT31S.\n'
    if VERSION == '0.31.2':
        readme = readme.replace('Medicina, Entrenar y Equipo','Medicina, Mentas y habilidades, y Equipo')
        readme += '\nEquipo → Ficha: completa los EXP restantes del nivel por pokédolares, durante la visita a tienda. Se conserva el precio y el límite de gimnasio. La pestaña Entrenar de la tienda se ha retirado. Iconos locales de los 18 tipos y de movimiento físico, especial y de estado; etiquetas y detalles numéricos accesibles.\n'
        shutil.copytree(ROOT/'godot/assets/ui-symbols',BUNDLE/'credits-ui-symbols',dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.import'))
    if CHAPTER >= 32:
        readme = readme.replace('Medicina, Entrenar y Equipo','Medicina, Mentas y habilidades, y Equipo')
        readme = readme.replace('Presión no tiene efecto en esta edición. Códigos nuevos KT31.', 'Presión reduce el movimiento enemigo en su aura. Códigos nuevos KT32.')
        readme += '\nClimas: sol, lluvia y arena; tres técnicas y MT de80 pokédolares/2 PP de equipamiento. Las treinta habilidades pendientes tienen efecto táctico y las mentas muestran los atributos que suben y bajan. Actualiza voluntariamente entre encuentros, con copia; los combates antiguos conservan su motor. Detalles en Documentacion/CAMBIOS_0.32.md.\nEquipo → Ficha permite comprar EXP en tienda; no hay pestaña Entrenar.\n'
        shutil.copytree(ROOT/'godot/assets/ui-symbols',BUNDLE/'credits-ui-symbols',dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.import'))
        for name in ['climate-credits.md','climate-provenance.json']:
            shutil.copy2(ROOT/'godot/data'/name,docs/name)
        prices = (docs/'PP_MOVIMIENTOS.csv').read_text(encoding='utf-8')
        for identity, move in read(ROOT/'godot/data/climate.json')['moves'].items():
            prices += f'{identity},"{move["name"]}",2,0,U,0\n'
        for path in [docs/'PP_MOVIMIENTOS.csv',EVIDENCE/'power-prices.csv']: path.write_text(prices,encoding='utf-8')
    if CHAPTER >= 33:
        for name in ['REGLAS_ACTUALES.md','PLAYTEST_WINDOWS.md','SPRINT_32_CLIMATE.md']:
            shutil.copy2(ROOT/'docs'/name,docs/name)
        shutil.copy2(ROOT/'tools/godot/check-pc.cmd',BUNDLE/'Comprobar-equipo.cmd')
        readme = (ROOT/'docs/LEEME_WINDOWS.txt').read_text(encoding='utf-8')
    (BUNDLE/'LEEME.txt').write_text(readme, encoding='utf-8')
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
            fingerprint.update(path.relative_to(ROOT).as_posix().encode()); fingerprint.update(path.read_bytes())
    record = {**verification, 'sourceFingerprint': fingerprint.hexdigest(), 'exe': {'bytes': EXE.stat().st_size, 'sha256': digest(EXE)}, 'zip': {'bytes': archive.stat().st_size, 'sha256': digest(archive)}}
    (EVIDENCE/'release.json').write_text(json.dumps(record, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    (RELEASE/'SHA256SUMS.txt').write_text(digest(EXE)+'  windows/PokemonTactics.exe\n'+digest(archive)+'  '+archive.name+'\n', encoding='utf-8')
    print(json.dumps(record, ensure_ascii=False))


if __name__ == '__main__':
    main()
