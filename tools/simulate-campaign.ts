import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { validateCatalog } from '../src/data/catalog.ts';
import { createRun, availableNodes, enterRoom, leaveService, performRunEvent, completeEncounter, withBattle, maximumHp } from '../src/rules/run.ts';
import type { Run } from '../src/rules/run.ts';
import { applyCommand, chooseTacticalCommand } from '../src/rules/battle.ts';
import { EVOLUTIONS } from '../src/domain/progression.ts';
import { validateRun } from '../src/data/run-store.ts';
const catalog=validateCatalog(JSON.parse(readFileSync(new URL('../public/data/pokemon.json',import.meta.url),'utf8')));
export function playCampaign(seed: string, destination: 'birds'|'psychic', edition=14) {
  let run=createRun(catalog,seed,.05,edition),commands=0,oneshots=0,hits=0;
  const heal=()=>{for(const itemId of ['super-potion','potion'] as const)while(run.bag[itemId]>0){const member=[...run.roster].sort((a,b)=>(maximumHp(catalog,b.speciesId,b.xp,edition)-b.hp)-(maximumHp(catalog,a.speciesId,a.xp,edition)-a.hp))[0];if(!member||member.hp===maximumHp(catalog,member.speciesId,member.xp,edition))break;run=performRunEvent(run,{kind:'heal',itemId,memberId:member.id},catalog);}};
  const evolve=()=>{for(const member of run.roster){let evolution=EVOLUTIONS[member.speciesId];while(evolution && run.bag[evolution.item]>0){run=performRunEvent(run,{kind:'evolve',memberId:member.id},catalog);evolution=EVOLUTIONS[run.roster.find(m=>m.id===member.id)!.speciesId];}}};
  for(let step=0;step<60&&!['victory','defeat'].includes(run.status);step++) {
    if(run.status==='route') {
      evolve();heal();const choices=availableNodes(run);
      const services=choices.filter(n=>n.kind!=='combat');
      const node=services.length?services.find(n=>n.kind===(run.roster.length<6&&run.money>=80?'recruit':'shop'))!:choices.find(n=>n.mapId===destination)??choices[seed.length%choices.length];
      run=enterRoom(run,node.id,catalog);
    }
    if(run.status==='service') {
      const node=run.nodes.find(n=>n.id===run.currentNodeId)!;
      if(node.kind==='recruit')for(const offer of node.offers)if(run.roster.length<6&&run.money>=offer.price)run=performRunEvent(run,{kind:'recruit',offerId:offer.id,replaceId:null},catalog);
      if(node.kind==='shop') {
        heal();let purchases=0;
        while(purchases<2&&run.money>=90&&run.roster.some(m=>m.hp<maximumHp(catalog,m.speciesId,m.xp,edition))){run=performRunEvent(run,{kind:'buy',itemId:'super-potion'},catalog);heal();purchases++;}
      }
      run=leaveService(run,catalog);
    }
    if(run.status==='combat') {
      let b=run.battle!;
      for(let i=0;i<3000&&b.outcome==='playing';i++) {
        const command=chooseTacticalCommand(b)!;const result=applyCommand(b,command);if(!result.ok)throw new Error(result.reason);
        if(command.kind==='attack')for(const hit of result.hits??[])if(hit.hit&&hit.damage>0){hits++;const target=b.units.find(u=>u.id===hit.targetId)!;if(target.hp===target.maxHp&&hit.damage>=target.hp)oneshots++;}
        b=result.state;commands++;
      }
      if(b.outcome==='playing')throw new Error('Combate sin resolver');run=completeEncounter(withBattle(run,b),catalog);validateRun(run,catalog);
    }
  }
  return {seed,destination,edition,status:run.status,combats:run.history.length,rounds:run.history.reduce((s,r)=>s+r.round,0),commands,oneshots,hits,money:run.money,survivors:run.roster.length,run};
}
if(process.argv[1]?.endsWith('simulate-campaign.ts')) {
  const edition=Number(process.env.EDITION||14),count=Number(process.env.SIM_COUNT||12),results=[];
  for(let i=0;i<count;i++)for(const destination of ['birds','psychic'] as const){const result=playCampaign('kanto-'+i,destination,edition);const {run,...summary}=result;results.push(summary);console.log(JSON.stringify(summary));}
  const out=process.env.TACTICS_QA_DIR||'docs/qa/sprint-11';mkdirSync(out,{recursive:true});writeFileSync(out+'/simulations-'+edition+'.json',JSON.stringify(results,null,2));
}
