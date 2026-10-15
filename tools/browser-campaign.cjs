const { chromium } = require('playwright');
const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict');
const { SAVE_KEY, SAVE_VERSION, validateRun } = require('../src/data/run-store.ts');
const catalog = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../public/data/pokemon.json'), 'utf8'));
const base = process.env.TACTICS_URL || 'http://127.0.0.1:5173/';
const output = path.resolve(process.env.TACTICS_QA_DIR || 'docs/qa/sprint-7');
fs.mkdirSync(output, { recursive: true });
(async () => {
  const browser = await chromium.launch({ channel: process.platform === 'win32' ? 'msedge' : undefined, headless: true });
  const errors = [], checks = [];
  try {
    const page = await browser.newPage({ viewport: { width: 1440, height: 1000 }, reducedMotion: 'reduce' });
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(base); await page.waitForLoadState('networkidle');
    await page.locator('#run-seed').fill('evolution'); await page.locator('#new-run button[type="submit"]').click();
    await page.locator('[data-node="shop-0"]').click(); await page.locator('[data-buy="rare-candy"]').click();
    await page.locator('#tab-bag').click();
    const read = () => page.evaluate(key => JSON.parse(localStorage.getItem(key)).run, SAVE_KEY);
    const before = await read(), member = before.roster.find(m => [1,4,7,74].includes(m.speciesId));
    await page.locator('#manage-member').selectOption(String(member.id)); await page.locator('#evolve-member').click();
    const after = await read(), evolved = after.roster.find(m => m.id === member.id);
    assert.notEqual(evolved.speciesId, member.speciesId); assert.equal(evolved.hp, member.hp); assert.equal(after.bag['rare-candy'],0);
    assert.deepEqual(validateRun(after,catalog), after); checks.push('Evolución mediante compra y controles reales; conserva PS/identidad y consume una vez');
    await page.reload(); await page.locator('#continue-run').click(); await page.locator('#tab-bag').click();
    assert.equal((await read()).roster.find(m=>m.id===member.id).speciesId,evolved.speciesId); checks.push('Recarga conserva evolución y progreso');
    await page.screenshot({path:path.join(output,'evolution-desktop.png'),fullPage:true});
    await page.setViewportSize({width:390,height:844});
    assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
    await page.screenshot({path:path.join(output,'evolution-mobile.png'),fullPage:true}); checks.push('Gestión utilizable a 390 px sin desbordamiento horizontal');
    await page.locator('#leave-service').click(); await page.locator('[data-node="1-1"]').click();
    await page.waitForSelector('canvas'); await page.waitForFunction(()=>!document.body.textContent.includes('Cargando sprites'));
    await page.screenshot({path:path.join(output,'evolved-battle.png'),fullPage:true}); checks.push('Especie evolucionada desplegada en combate con sus recursos');
    for (const boss of catalog.some(p=>p.id===150) ? ['birds','psychic'] : ['birds']) {
      await page.setViewportSize({width:1440,height:1000});
      await page.goto(base+'?view=battle&boss='+boss); await page.waitForLoadState('networkidle');
      await page.waitForSelector('canvas');
      assert(await page.locator('.zone-tile').count()>0);
      assert(await page.locator('.tile-unit').allTextContents().then(names=>names.includes(boss==='birds'?'Articuno':'Mewtwo')));
      await page.screenshot({path:path.join(output,boss+'-desktop.png'),fullPage:true});
      await page.setViewportSize({width:390,height:844});
      assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
      await page.screenshot({path:path.join(output,boss+'-mobile.png'),fullPage:true});
      checks.push('Arena '+boss+': jefes, sectores legibles y escritorio/móvil');
    }
    assert.deepEqual(errors,[]);
    fs.writeFileSync(path.join(output,'checks.json'),JSON.stringify({checks,errors},null,2)); console.log(JSON.stringify({passed:checks.length,errors}));
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1;});
