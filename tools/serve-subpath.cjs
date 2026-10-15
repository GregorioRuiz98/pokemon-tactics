// Local-only release check; never used as a public hosting server.
const http=require('node:http'),fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'../dist'),prefix='/juego/';
const types={'.html':'text/html','.js':'text/javascript','.css':'text/css','.json':'application/json','.png':'image/png','.ttf':'font/ttf','.wav':'audio/wav','.md':'text/plain','.txt':'text/plain','.xml':'application/xml'};
http.createServer((request,response)=>{
  try {
    const pathname=decodeURIComponent(new URL(request.url,'http://127.0.0.1').pathname);
    if(!['GET','HEAD'].includes(request.method)||!pathname.startsWith(prefix)){response.writeHead(404).end();return;}
    const file=path.resolve(root,pathname.slice(prefix.length)||'index.html'),relative=path.relative(root,file);
    if(relative.startsWith('..')||path.isAbsolute(relative)||!fs.existsSync(file)||!fs.statSync(file).isFile()){response.writeHead(404).end();return;}
    response.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
    if(request.method==='HEAD')response.end();else fs.createReadStream(file).pipe(response);
  } catch {response.writeHead(400).end();}
}).listen(4174,'127.0.0.1',()=>console.log('Subpath QA: http://127.0.0.1:4174/juego/'));
