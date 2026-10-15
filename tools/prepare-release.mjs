import { readFileSync, writeFileSync, readdirSync, statSync } from 'node:fs';
import { resolve, relative, sep } from 'node:path';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const root=resolve(import.meta.dirname,'..'),dist=resolve(root,'dist');
const files=[];
function visit(directory) {
  for(const name of readdirSync(directory).sort()) {
    const file=resolve(directory,name),path=relative(dist,file).split(sep).join('/');
    if(path==='release-manifest.json')continue;
    if(statSync(file).isDirectory())visit(file);
    else {const data=readFileSync(file);files.push({path,bytes:data.length,sha256:createHash('sha256').update(data).digest('hex')});}
  }
}
visit(dist);
const version=JSON.parse(readFileSync(resolve(root,'package.json'),'utf8')).version;
const env={...process.env,GIT_CONFIG_GLOBAL:process.platform==='win32'?'NUL':'/dev/null',GIT_CONFIG_NOSYSTEM:'1'};
const commit=execFileSync('git',['rev-parse','HEAD'],{cwd:root,env,encoding:'utf8'}).trim();
const dirty=execFileSync('git',['status','--porcelain'],{cwd:root,env,encoding:'utf8'}).trim().length>0;
writeFileSync(resolve(dist,'release-manifest.json'),JSON.stringify({version,commit,dirty,published:false,files},null,2)+'\n');
console.log(`Prepared ${version}: ${files.length} files, ${files.reduce((sum,file)=>sum+file.bytes,0)} bytes; source ${commit}${dirty?' (working changes)':''}.`);
