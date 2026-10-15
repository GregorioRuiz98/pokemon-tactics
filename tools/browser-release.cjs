const {chromium}=require('playwright');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {playCampaign}=require('./simulate-campaign.ts');
const {createRun,performRunEvent,withBattle,completeEncounter,CURRENT_EDITION}=require('../src/rules/run.ts');
const {applyCommand,chooseTacticalCommand,activeUnit}=require('../src/rules/battle.ts');
const {validateRun,SAVE_KEY}=require('../src/data/run-store.ts');
const catalog=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../public/data/pokemon.json'),'utf8'));
const base=process.env.TACTICS_URL||'http://127.0.0.1:5173/',out=process.env.TACTICS_QA_DIR||'docs/qa/sprint-11/release';fs.mkdirSync(out,{recursive:true});
(async()=>{const browser=await chromium.launch({channel:process.platform==='win32'?'msedge':undefined,headless:true});const checks=[],errors=[],external=[];
try{for(const destination of ['birds','psychic']) {
  const context=await browser.newContext({viewport:{width:1440,height:1000},reducedMotion:'reduce',...(process.env.RECORD_VIDEO?{recordVideo:{dir:out+'/video',size:{width:1280,height:900}}}:{})});
  const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>{const u=new URL(r.url());if(['http:','https:'].includes(u.protocol)&&!['127.0.0.1','localhost'].includes(u.hostname))external.push(u.href);});
  await page.goto(base);await page.waitForLoadState('networkidle');await page.locator('.game-guide summary').click();assert(await page.getByText('Construye tu equipo.',{exact:true}).isVisible());
  await page.locator('#game-volume').fill('0');assert.equal(await page.evaluate(()=>localStorage.getItem('pokemon-tactics.volume')),'0');
  await page.locator('#run-seed').fill('kanto-0');await page.locator('#new-run button[type=submit]').click();
  let run=createRun(catalog,'kanto-0',.05,CURRENT_EDITION);
  const expected=playCampaign('kanto-0',destination,CURRENT_EDITION);assert.equal(expected.status,'victory');
  const read=()=>page.evaluate(key=>JSON.parse(localStorage.getItem(key)).run,SAVE_KEY);
  const matches=async()=>{assert.deepEqual(await read(),run);validateRun(run,catalog);};
  const settle=async()=>{
    while(run.battle.outcome==='playing'&&activeUnit(run.battle)?.team==='enemy'){const r=applyCommand(run.battle,chooseTacticalCommand(run.battle));assert(r.ok);run=withBattle(run,r.state);}
    await page.waitForFunction(e=>{const root=document.querySelector('#battle-root');return root&&root.dataset.busy==='false'&&root.dataset.active===String(e.active??'')&&root.dataset.round===String(e.round)&&root.dataset.outcome===e.outcome&&!document.querySelector('#pause').disabled;},{active:activeUnit(run.battle)?.id,round:run.battle.round,outcome:run.battle.outcome});await matches();
  };
  const issue=async command=>{
    if(command.kind==='finish'){await page.locator('#finish-turn').click();if(command.facing!==undefined)await page.locator(`#facing-controls [data-facing="${command.facing}"]`).click();}
    else if(command.kind==='move'){await page.locator('#mode-move').click();await page.locator(`[data-cell="${command.destination.x},${command.destination.y}"]`).click();}
    else{await page.locator(`[data-action="${command.actionId||'basic'}"]`).click();const target=run.battle.units.find(u=>u.id===command.target);await page.locator(`[data-cell="${target.x},${target.y}"]`).click();}
    await page.locator('#confirm').click();const r=applyCommand(run.battle,command);assert(r.ok);run=withBattle(run,r.state);await settle();
  };
  const bag=async()=>{if(await page.locator('#tab-bag').count())await page.locator('#tab-bag').click();else if(await page.locator('#open-bag').count())await page.locator('#open-bag').click();await page.waitForSelector('#manage-member');};
  for(const event of expected.run.events) {
    if(event.kind==='result') {
      let count=0;while(run.battle.outcome==='playing'){await issue(chooseTacticalCommand(run.battle));assert(++count<500);}
      await page.locator('#play-again').click();run=completeEncounter(run,catalog);assert.deepEqual(run.events.at(-1),event);await matches();
      console.log(destination,'combate',run.history.length,run.status);
      if(run.status==='victory')await page.screenshot({path:path.join(out,destination+'-victory.png'),fullPage:true});
      continue;
    }
    if(event.kind==='enter') {
      if(await page.locator('#back-to-route').count())await page.locator('#back-to-route').click();
      await page.locator(`[data-node="${event.nodeId}"]`).click();
    } else if(event.kind==='leave') await page.locator('#leave-service').click();
    else if(event.kind==='buy'||event.kind==='recruit') {
      if(await page.locator('#tab-service').count())await page.locator('#tab-service').click();
      await page.locator(event.kind==='buy'?`[data-buy="${event.itemId}"]`:`[data-recruit="${event.offerId}"]`).click();
    } else if(event.kind==='heal'||event.kind==='evolve') {
      await bag();await page.locator('#manage-member').selectOption(String(event.memberId));
      await page.locator(event.kind==='heal'?`[data-heal="${event.itemId}"]`:'#evolve-member').click();
    } else throw new Error('Unsupported planned event '+event.kind);
    run=performRunEvent(run,event,catalog);
    if(run.status==='combat') {
      await settle();
      if(run.currentNodeId.startsWith('final-'))await page.screenshot({path:path.join(out,destination+'-final.png'),fullPage:true});
      if(run.history.length===2){await page.reload();await page.locator('#continue-run').click();await settle();checks.push(destination+': recarga en combate conserva RNG/cola/PS');}
    } else await matches();
  }
  assert.deepEqual(run,expected.run);await page.reload();await page.locator('#continue-run').click();assert(await page.locator('#result-menu').isVisible());await matches();
  checks.push(destination+': nueve combates reales desde nueva partida hasta victoria; todas las órdenes aliadas mediante UI y guardado exacto');
  await context.close();
}
assert.deepEqual(errors,[]);assert.deepEqual(external,[]);fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify({checks,errors,external},null,2));console.log(JSON.stringify({passed:checks.length,errors,external}));
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
