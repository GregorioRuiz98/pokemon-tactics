"""Prepare a legal-command native UI proof from an actual simulation journal."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
WORK = (ROOT/'../../work/qa-sprint-41').resolve()


def main():
    candidates = [WORK/'natural-relief-final', (ROOT/'../../work/qa-sprint-40/natural-relief-final').resolve()]
    source = next((path for path in candidates if (path/'campaign-review.json').is_file()),None)
    assert source is not None, 'Generate a legal journal first: npm run godot:simulate:relief'
    journal = json.loads((source/'campaign-journal.json').read_text(encoding='utf-8'))
    payload = json.loads(json.loads((source/'natural-save.json').read_text(encoding='utf-8'))['payload'])
    report = json.loads((source/'campaign-review.json').read_text(encoding='utf-8'))
    assert report['phase']=='ending' and not report['failures'] and payload['version']==30
    assert report['mapCatalogHash']==hashlib.sha256((ROOT/'godot/data/relief-maps.json').read_bytes()).hexdigest()
    assert journal['commands']==payload['commands'] and len(journal['commands'])==10277
    journal['expectedState'] = payload['state']
    WORK.mkdir(parents=True,exist_ok=True)
    (WORK/'journey-strategy.json').write_text(json.dumps(journal,ensure_ascii=False),encoding='utf-8')
    print('Prepared10277 original legal commands; no state injection or rewritten victories.')


if __name__=='__main__': main()
