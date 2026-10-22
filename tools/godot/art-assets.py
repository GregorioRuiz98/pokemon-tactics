"""Validate and install final art without dependencies or game-state changes."""
from pathlib import Path
import argparse, hashlib, json, shutil, struct, sys, time, zlib
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'godot/art'
def manifest(): return json.loads((ART/'manifest.json').read_text(encoding='utf-8'))
def resource(path):
    target=(ROOT/'godot'/path.removeprefix('res://')).resolve()
    if not target.is_relative_to(ART.resolve()): raise ValueError('Destino fuera de art/')
    return target

def inspect_png(path, record):
    raw=Path(path).read_bytes()
    if raw[:8]!=b'\x89PNG\r\n\x1a\n': raise ValueError('Se requiere PNG')
    position=8; compressed=bytearray(); header=None; ended=False
    while position<len(raw):
        if position+12>len(raw): raise ValueError('PNG truncado')
        length=struct.unpack('>I',raw[position:position+4])[0];kind=raw[position+4:position+8]
        data=raw[position+8:position+8+length]
        if position+length+12>len(raw) or zlib.crc32(kind+data)&0xffffffff!=struct.unpack('>I',raw[position+8+length:position+12+length])[0]:raise ValueError('CRC PNG incorrecto')
        if kind==b'IHDR':
            if header is not None or position!=8 or length!=13: raise ValueError('Cabecera PNG incorrecta')
            header=struct.unpack('>IIBBBBB',data)
        elif kind==b'IDAT':compressed.extend(data)
        elif kind==b'IEND':ended=True;position+=length+12;break
        position+=length+12
    if header is None or not ended or position!=len(raw):raise ValueError('PNG incompleto o con datos sobrantes')
    w,h,depth,color,compression,filter_mode,interlace=header
    if (w,h)!=(record['width'],record['height']): raise ValueError(f'Medida requerida: {record["width"]}×{record["height"]}; recibida {w}×{h}')
    if depth!=8 or color not in [2,6] or compression or filter_mode or interlace: raise ValueError('Exporta PNG RGB/RGBA de 8 bits sin entrelazado')
    if record['alpha'] and color!=6: raise ValueError('Se requiere RGBA con transparencia real')
    channels=4 if color==6 else 3;stride=w*channels
    decoder=zlib.decompressobj();pixels=decoder.decompress(bytes(compressed),(stride+1)*h+1)
    if len(pixels)!=(stride+1)*h or not decoder.eof or decoder.unused_data: raise ValueError('Datos de píxeles incorrectos')
    previous=bytearray(stride);transparent=0
    for y in range(h):
        start=y*(stride+1);mode=pixels[start];row=bytearray(pixels[start+1:start+1+stride])
        if mode not in range(5):raise ValueError('Filtro PNG inválido')
        for i in range(stride):
            a=row[i-channels] if i>=channels else 0;b=previous[i];c=previous[i-channels] if i>=channels else 0
            predictor=0
            if mode==1:predictor=a
            elif mode==2:predictor=b
            elif mode==3:predictor=(a+b)//2
            elif mode==4:
                p=a+b-c;pa,pb,pc=abs(p-a),abs(p-b),abs(p-c)
                predictor=a if pa<=pb and pa<=pc else b if pb<=pc else c
            row[i]=(row[i]+predictor)&255
        if color==6:
            for x in range(w):
                alpha=row[x*4+3]
                transparent+=alpha<255
                if record['kind']=='floor' and abs((x+.5)-w/2)/(w/2)+abs((y+.5)-h/2)/(h/2)>1 and alpha:
                    raise ValueError('El suelo debe tener alfa cero fuera del rombo 5:3; aplica la máscara antes de instalar')
        previous=row
    if record['alpha'] and transparent==0:raise ValueError('El canal alfa es totalmente opaco; falta transparencia real')
    return dict(width=w,height=h,alpha=transparent>0,sha256=hashlib.sha256(raw).hexdigest())

def check(require_final=False):
    data=manifest();prompts=(ROOT/'docs/PROMPTS_ARTE_FINAL.md').read_text(encoding='utf-8');seen=set();pending=[];completed=[]
    assert data['projection']=={'tile':[80,48],'lift':12,'ratio':'5:3'}
    for s in data['slots']:
        if s['id'] in seen:raise ValueError('ID duplicado')
        seen.add(s['id']);path=resource(s['placeholder']);element=ET.fromstring(path.read_bytes())
        if (int(element.attrib['width']),int(element.attrib['height']))!=(s['width'],s['height']):raise ValueError('Placeholder con medida incorrecta: '+s['id'])
        if hashlib.sha256(path.read_bytes()).hexdigest()!=s['placeholderSha256']:raise ValueError('Placeholder modificado sin revisar: '+s['id'])
        if f'## {s["prompt"]} · ' not in prompts or f'ID: `{s["id"]}`.' not in prompts:raise ValueError('Falta prompt completo: '+s['id'])
        final=resource(s['final'])
        if final.exists():inspect_png(final,s);completed.append(s['id'])
        elif s['required']:pending.append(s['id'])
    for family in data['biomes'].values():
        if 'floor_'+family not in seen:raise ValueError('Familia sin suelo: '+family)
    result=dict(slots=len(seen),required=sum(s['required'] for s in data['slots']),completed=completed,pendingRequired=pending,artReady=not pending,generatedImages=False)
    if require_final and pending:raise ValueError(f'Faltan {len(pending)} recursos finales requeridos; versión visual provisional')
    return result

def install(identity,source):
    record=next((s for s in manifest()['slots'] if s['id']==identity),None)
    if record is None:raise ValueError('ID desconocido')
    source=Path(source).resolve();details=inspect_png(source,record);target=resource(record['final'])
    if source==target:raise ValueError('La fuente ya es el destino; usa check')
    target.parent.mkdir(parents=True,exist_ok=True)
    if target.exists():
        backup=ART/'history'/f'{identity}-{time.time_ns()}.png';backup.parent.mkdir(parents=True,exist_ok=True);(backup.parent/'.gdignore').touch();shutil.copy2(target,backup)
    temporary=target.with_suffix('.pending');shutil.copy2(source,temporary);temporary.replace(target)
    if identity=='brand_emblem':shutil.copy2(target,resource(manifest()['appIcon']['path']))
    return dict(installed=identity,path=str(target),**details)

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);sub=parser.add_subparsers(dest='command',required=True)
    checker=sub.add_parser('check');checker.add_argument('--require-final',action='store_true')
    installer=sub.add_parser('install');installer.add_argument('--id',required=True);installer.add_argument('--source',required=True)
    args=parser.parse_args()
    try:result=check(args.require_final) if args.command=='check' else install(args.id,args.source)
    except (ValueError,AssertionError,OSError,ET.ParseError,zlib.error) as error:print(str(error),file=sys.stderr);sys.exit(1)
    print(json.dumps(result,ensure_ascii=False,indent=2))
