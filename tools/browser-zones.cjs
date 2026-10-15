const { chromium }=require('playwright');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {ZONES}=require('../src/data/zones.ts');
const base=process.env.TACTICS_URL||'http://127.0.0.1:5173/',out=process.env.TACTICS_QA_DIR||'docs/qa/zones';fs.mkdirSync(out,{recursive:true});
(async()=>{const browser=await chromium.launch({channel:process.platform==='win32'?'msedge':undefined,headless:true});const checks=[],errors=[];
try{const page=await browser.newPage({reducedMotion:'reduce'});page.on('pageerror',error=>errors.push(error.message));
for(const zone of ZONES.slice(Number(process.env.ZONE_FROM||0),Number(process.env.ZONE_TO||8)))for(let i=0;i<2;i++){
await page.setViewportSize(i?{width:390,height:844}:{width:1440,height:1000});await page.goto(base+'?view=battle&map='+zone.maps[i]);await page.waitForLoadState('networkidle');await page.waitForSelector('canvas');
assert.equal(await page.locator('[role="gridcell"]').count(),64);assert(await page.locator('.tile-unit').count()>=4);assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
await page.screenshot({path:path.join(out,zone.maps[i]+'.png'),fullPage:true});checks.push(zone.maps[i]+(i?' móvil':' escritorio'));}
assert.deepEqual(errors,[]);fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify({checks,errors},null,2));console.log(JSON.stringify({passed:checks.length,errors}));
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
