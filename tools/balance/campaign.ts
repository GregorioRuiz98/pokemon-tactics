import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateCatalog } from '../../src/data/catalog.ts';
import { runMap } from '../../src/data/run-maps.ts';
import { pokemonFor } from '../../src/domain/Pokemon.ts';
import { EVOLUTIONS, atLevel, levelFor } from '../../src/domain/progression.ts';
import { HealingItem, itemFor } from '../../src/domain/items.ts';
import type { HeldItemId, ItemId } from '../../src/domain/items.ts';
import { hashSeed, random, createEncounter } from '../../src/rules/battle.ts';
import {
  createRun, availableNodes, enterRoom, leaveService, performRunEvent, completeEncounter,
  withBattle, maximumHp, remainingStock, CURRENT_EDITION,
} from '../../src/rules/run.ts';
import type { Run, RunEvent, RunMember } from '../../src/rules/run.ts';
import { validateRun } from '../../src/data/run-store.ts';
import { simulateFight } from './telemetry.ts';
import type { FightMetric } from './telemetry.ts';

export const catalog = validateCatalog(JSON.parse(readFileSync(new URL('../../public/data/pokemon.json', import.meta.url), 'utf8')));
export const POLICIES = [
  { id: 'reference', label: 'Referencia: seis, curación inmediata', limit: 6, reference: true, evolution: false, gear: null },
  { id: 'trio', label: 'Tres, curación eficiente', limit: 3, reference: false, evolution: false, gear: null },
  { id: 'six', label: 'Seis, curación eficiente', limit: 6, reference: false, evolution: false, gear: null },
  { id: 'evolution', label: 'Seis, invertir en evoluciones', limit: 6, reference: false, evolution: true, gear: null },
  { id: 'leftovers', label: 'Seis, invertir en Restos', limit: 6, reference: false, evolution: false, gear: 'leftovers' },
  { id: 'vest', label: 'Seis, invertir en Chaleco Asalto', limit: 6, reference: false, evolution: false, gear: 'assault-vest' },
  { id: 'four', label: 'Cuatro, curación eficiente', limit: 4, reference: false, evolution: false, gear: null },
  { id: 'trio-evolution', label: 'Tres, invertir en evoluciones', limit: 3, reference: false, evolution: true, gear: null },
  { id: 'trio-leftovers', label: 'Tres, invertir en Restos', limit: 3, reference: false, evolution: false, gear: 'leftovers' },
  { id: 'boots', label: 'Seis, invertir en Botas Gruesas', limit: 6, reference: false, evolution: false, gear: 'heavy-duty-boots' },
] as const;
type Policy = typeof POLICIES[number];
export type CampaignFight = FightMetric & { floor: number; nodeId: string; mapId: string; startMoney: number; endMoney: number; recruits: number; evolutions: number };
const maxHp = (member: RunMember) => maximumHp(catalog, member.speciesId, member.xp, CURRENT_EDITION);
const deficit = (member: RunMember) => maxHp(member) - member.hp;
const roster = (run: Run) => run.roster.map(member => ({ ...member, maxHp: maxHp(member), level: levelFor(member.xp) }));

export function campaign(seed: string, policy: Policy) {
  assert.equal(CURRENT_EDITION, 14, 'Audit targets release 0.12 ruleset 14');
  let run = createRun(catalog, seed, .05, CURRENT_EDITION);
  const initial = roster(run), routeRng = { rng: hashSeed(`audit-route:${seed}`) };
  const branches = Array.from({ length: 8 }, () => Math.floor(random(routeRng) * 2));
  const management = {
    spentHealing: 0, spentGear: 0, spentEvolution: 0, spentRecruiting: 0,
    healed: 0, nominalHealing: 0, healingUses: 0, recruits: 0, evolutions: 0,
    equipOperations: 0, purchases: {} as Record<string,number>, services: { shop: 0, recruit: 0 },
  };
  const transact = (event: RunEvent): void => {
    const before = run;
    run = performRunEvent(run, event, catalog);
    if (event.kind === 'buy') {
      const item = itemFor(event.itemId);
      management.purchases[item.id] = (management.purchases[item.id] ?? 0) + 1;
      if (item instanceof HealingItem) management.spentHealing += item.price;
      else if (['rare-candy','thunder-stone'].includes(item.id)) management.spentEvolution += item.price;
      else management.spentGear += item.price;
    }
    if (event.kind === 'heal') {
      management.healed += run.roster.find(m => m.id === event.memberId)!.hp - before.roster.find(m => m.id === event.memberId)!.hp;
      management.nominalHealing += (itemFor(event.itemId) as HealingItem).recovery * 2;
      management.healingUses++;
    }
    if (event.kind === 'evolve') management.evolutions++;
    if (event.kind === 'equip') management.equipOperations++;
    if (event.kind === 'recruit') {
      management.recruits++; management.spentRecruiting += before.money - run.money;
    }
  };
  const wounded = () => [...run.roster].filter(m => deficit(m) > 0).sort((a,b) => deficit(b) - deficit(a) || a.id-b.id)[0];
  const heal = (): void => {
    for (let safety = 0; safety < 100; safety++) {
      const member = wounded(); if (!member) return;
      const need = deficit(member), urgent = member.hp / maxHp(member) < .65;
      const order: ('potion'|'super-potion')[] = ['super-potion','potion'];
      if(!policy.reference)order.sort((a,b)=>itemFor(a).price/Math.min(need,(itemFor(a) as HealingItem).recovery*2)-itemFor(b).price/Math.min(need,(itemFor(b) as HealingItem).recovery*2));
      const itemId = order.find(id => run.bag[id] > 0 && (policy.reference || urgent || need >= (id === 'potion' ? 28 : 70)));
      if (!itemId) return;
      transact({ kind: 'heal', itemId, memberId: member.id });
    }
    throw new Error('Healing loop cap');
  };
  const evolve = (): void => {
    for (let safety=0; safety<20; safety++) {
      const compatible = run.roster.filter(m => EVOLUTIONS[m.speciesId] && run.bag[EVOLUTIONS[m.speciesId].item] > 0);
      if (!compatible.length) return;
      if (policy.evolution) compatible.sort((a,b) => Number([1,4,7,25,74].includes(b.speciesId)) - Number([1,4,7,25,74].includes(a.speciesId)) || b.hp/maxHp(b)-a.hp/maxHp(a) || a.id-b.id);
      transact({ kind:'evolve', memberId:compatible[0].id });
    }
    throw new Error('Evolution loop cap');
  };
  const recipient = () => run.roster.filter(m => !m.heldItem).sort((a,b) => {
    const score = (member:RunMember) => {
      const unit=atLevel(pokemonFor(member.speciesId).createCombatant(catalog.find(s=>s.id===member.speciesId)!,'ally',{x:0,y:0}),levelFor(member.xp),14);
      const support=pokemonFor(member.speciesId).actionsFor(unit).filter(action=>action.preview(unit,unit).category==='status').length;
      return maxHp(member)+(unit.defense+unit.specialDefense)*.15-(policy.gear==='assault-vest'?support*100:0);
    };
    return score(b)-score(a)||a.id-b.id;
  })[0];
  const equip = (): void => {
    if (!policy.gear) return;
    for (let i=0;i<6&&run.bag[policy.gear]>0;i++) {
      const member=recipient();if(!member)break;
      transact({kind:'equip',memberId:member.id,itemId:policy.gear});
    }
  };
  const fights: CampaignFight[] = [];
  let unresolvedRun: Run|null = null;
  for (let step=0; step<40 && !['victory','defeat'].includes(run.status); step++) {
    if (run.status==='route') {
      evolve(); equip(); heal();
      const choices=availableNodes(run);
      if(choices[0]?.id.startsWith('final-'))break;
      const services=choices.filter(n=>n.kind!=='combat');
      const injury=run.roster.reduce((sum,m)=>sum+deficit(m),0);
      const needMembers=run.roster.length<policy.limit && run.money>=80;
      const preferRecruit=needMembers&&(policy.reference||run.roster.length<4||injury<80);
      const node=services.length?services.find(n=>n.kind===(preferRecruit?'recruit':'shop'))!:choices[branches[choices[0].floor-1]];
      run=enterRoom(run,node.id,catalog);
    }
    if(run.status==='service') {
      const node=run.nodes.find(n=>n.id===run.currentNodeId)!;
      management.services[node.kind as 'shop'|'recruit']++;
      if(node.kind==='recruit')for(const offer of node.offers)if(run.roster.length<policy.limit&&run.money>=offer.price)transact({kind:'recruit',offerId:offer.id,replaceId:null});
      if(node.kind==='shop') {
        heal();let bought=0;
        for(let i=0;i<10;i++) {
          const member=wounded();if(!member)break;
          let itemId: ItemId|undefined;
          if(policy.reference) {if(bought<2&&run.money>=90&&remainingStock(run,'super-potion')>0)itemId='super-potion';}
          else {
            const need=deficit(member),urgent=member.hp/maxHp(member)<.65;
            const options=(['potion','super-potion'] as const).filter(id=>run.money>=itemFor(id).price&&remainingStock(run,id)>0&&(urgent||need>=(id==='potion'?28:70)));
            options.sort((a,b)=>itemFor(a).price/Math.min(need,(itemFor(a) as HealingItem).recovery*2)-itemFor(b).price/Math.min(need,(itemFor(b) as HealingItem).recovery*2));
            itemId=options[0];
          }
          if(!itemId)break;
          transact({kind:'buy',itemId});bought++;
          const uses=management.healingUses;heal();assert(management.healingUses>uses,'Purchased healing must be consumed');
        }
        if(policy.evolution) {
          const member=run.roster.find(m=>EVOLUTIONS[m.speciesId]);
          if(member) {const itemId=EVOLUTIONS[member.speciesId].item;if(run.money>=itemFor(itemId).price+90&&remainingStock(run,itemId)>0){transact({kind:'buy',itemId});evolve();}}
        }
        if(policy.gear) {
          equip();if(recipient()&&run.money>=itemFor(policy.gear).price+90&&remainingStock(run,policy.gear)>0){transact({kind:'buy',itemId:policy.gear});equip();}
        }
      }
      run=leaveService(run,catalog);
    }
    if(run.status==='combat') {
      const node=run.nodes.find(n=>n.id===run.currentNodeId)!;
      const startMoney=run.money,recruits=management.recruits,evolutions=management.evolutions;
      const result=simulateFight(run.battle!);
      run=withBattle(run,result.battle);
      if(result.battle.outcome!=='playing') run=completeEncounter(run,catalog);
      else unresolvedRun=structuredClone(run);
      validateRun(run,catalog);
      fights.push({...result.metrics,floor:node.floor,nodeId:node.id,mapId:node.mapId,startMoney,endMoney:run.money,recruits,evolutions});
      if(unresolvedRun)break;
    }
  }
  assert(unresolvedRun||run.status==='defeat'||availableNodes(run).every(node=>node.id.startsWith('final-')),'Unexpected unfinished prefix');
  const checkpoint=roster(run);
  const finals: Record<string,(FightMetric & { survivors:number; money:number })|null>={birds:null,psychic:null};
  const reachedFinal=!unresolvedRun&&run.status!=='defeat';
  if(reachedFinal)for(const destination of ['birds','psychic']) {
    const trial=enterRoom(run,`final-${destination}`,catalog),result=simulateFight(trial.battle!);
    const completed=result.battle.outcome==='playing'?withBattle(trial,result.battle):completeEncounter(withBattle(trial,result.battle),catalog);validateRun(completed,catalog);
    if(result.battle.outcome==='playing'&&!unresolvedRun)unresolvedRun=structuredClone(completed);
    finals[destination]={...result.metrics,survivors:completed.roster.length,money:completed.money};
  }
  return {seed,policy:policy.id,branches,initial,reachedFinal,unresolvedRun,fights,management,checkpoint,money:run.money,departed:run.departed.length,finals};
}

export function itemProbe(seed:string,destination:'birds'|'psychic',ids:number[],held:HeldItemId|null):FightMetric {
  const map=runMap(destination);
  const allies=ids.map((speciesId,index)=>{
    const unit=atLevel(pokemonFor(speciesId).createCombatant(catalog.find(p=>p.id===speciesId)!,'ally',{x:0,y:0}),3,14);
    return {id:index+1,speciesId,xp:120,hp:Math.floor(unit.maxHp*.8),heldItem:index===2?held:null};
  });
  const battle=createEncounter(catalog,seed,.05,map.board,allies,destination==='birds'?[144,145,146]:[150,151],{progression:true,ruleset:14,hazards:map.hazards});
  return simulateFight(battle).metrics;
}
