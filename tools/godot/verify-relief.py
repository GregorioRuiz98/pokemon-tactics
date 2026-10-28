"""Validate authored geometry without Godot, RNG or published data mutation."""
from pathlib import Path
from collections import deque
import csv
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]


def reachable(layout, excluded=None):
    start = tuple(layout['allies'][0])
    pending, seen = deque([start]), {start}
    while pending:
        x, y = pending.popleft()
        for X, Y in [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]:
            if (0 <= X < 16 and 0 <= Y < 16 and (X,Y) != excluded
                and (X,Y) not in seen and layout['board'][Y][X] not in [2,3]
                and abs(layout['heights'][Y][X]-layout['heights'][y][x]) <= 1):
                seen.add((X,Y)); pending.append((X,Y))
    return seen


def verify():
    path = ROOT/'godot/data/relief-maps.json'
    layouts = json.loads(path.read_text(encoding='utf-8'))
    with (ROOT/'docs/MAPAS_0.34.csv').open(encoding='utf-8-sig',newline='') as file:
        assert set(layouts) == {row['zona'] for row in csv.DictReader(file)}
    results = []
    for identity, layout in layouts.items():
        assert len(layout['board']) == len(layout['heights']) == 16
        assert all(len(row)==16 for row in layout['board']+layout['heights'])
        assert len({h for row in layout['heights'] for h in row}) >= 3, identity
        landmark = ','.join(map(str,layout['landmarkCell']))
        assert landmark in layout['props'], identity
        start, end = tuple(layout['allies'][0]), tuple(layout['enemies'][0])
        reached = reachable(layout)
        for point in layout['enemies']+layout['allies']+layout['deployment']:
            assert tuple(point) in reached, (identity,'isolated anchor',point)
        # No single ground square may cut both approaches to the enemy front.
        for point in reached-{start,end}:
            assert end in reachable(layout,point), (identity,'single access',point)
        results.append({'id':identity,'landmark':layout['landmark'],'form':layout['form'],
                        'groundReachable':len(reached),'obstacles':len(layout['props']),
                        'twoGroundApproaches':True})
    return {'ok':True,'layouts':results,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}


if __name__ == '__main__':
    print(json.dumps(verify(),ensure_ascii=True))
