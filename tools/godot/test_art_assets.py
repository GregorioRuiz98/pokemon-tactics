import importlib.util,json,struct,tempfile,unittest,zlib
from pathlib import Path
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('art_assets',Path(__file__).with_name('art-assets.py'));art=importlib.util.module_from_spec(spec);spec.loader.exec_module(art)
def png(width=2,height=2,color=(80,100,120,0)):
    def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,8,6,0,0,0))+chunk(b'IDAT',zlib.compress((b'\0'+bytes(color)*width)*height))+chunk(b'IEND',b'')
class ArtTests(unittest.TestCase):
    def setUp(self):
        parent=art.ROOT/'godot/.godot/art-tests';parent.mkdir(parents=True,exist_ok=True)
        self.temp=tempfile.TemporaryDirectory(dir=parent);self.root=Path(self.temp.name)
        assert self.root.resolve().is_relative_to(parent.resolve())
        self.addCleanup(self.temp.cleanup);self.path=self.root/'sample.png';self.path.write_bytes(png());self.record={'id':'test','width':2,'height':2,'alpha':True,'kind':'icon'}
    def test_valid_rgba(self):self.assertTrue(art.inspect_png(self.path,self.record)['alpha'])
    def test_wrong_size_rejected(self):
        self.record['width']=3
        with self.assertRaisesRegex(ValueError,'Medida'):art.inspect_png(self.path,self.record)
    def test_false_transparency_rejected(self):
        self.path.write_bytes(png(color=(80,100,120,255)))
        with self.assertRaisesRegex(ValueError,'opaco'):art.inspect_png(self.path,self.record)
    def test_corruption_rejected(self):
        broken=bytearray(self.path.read_bytes());broken[-15]^=1;self.path.write_bytes(broken)
        with self.assertRaises(ValueError):art.inspect_png(self.path,self.record)
    def test_floor_mask_rejected(self):
        self.record.update(width=4,height=4,kind='floor');self.path.write_bytes(png(4,4,(0,80,0,200)))
        with self.assertRaisesRegex(ValueError,'rombo'):art.inspect_png(self.path,self.record)
    def test_install_backs_up_and_preserves_source(self):
        directory=self.root/'godot/art';directory.mkdir(parents=True)
        self.record['final']='res://art/final/test.png'
        (directory/'manifest.json').write_text(json.dumps({'slots':[self.record]}),encoding='utf-8')
        with patch.object(art,'ROOT',self.root),patch.object(art,'ART',directory):
            old=self.path.read_bytes();art.install('test',self.path);self.path.write_bytes(png(color=(40,80,120,50)));new=self.path.read_bytes();art.install('test',self.path)
            self.assertEqual((directory/'final/test.png').read_bytes(),new);self.assertEqual(self.path.read_bytes(),new);self.assertEqual(next((directory/'history').glob('*.png')).read_bytes(),old)
            with self.assertRaises(ValueError):art.resource('res://../outside.png')
    def test_manifest_and_prompts_match(self):
        result=art.check();self.assertEqual(result['slots'],45);self.assertEqual(result['required'],42)
if __name__=='__main__':unittest.main()
