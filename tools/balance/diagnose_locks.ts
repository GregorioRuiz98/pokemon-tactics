import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import assert from 'node:assert/strict';
import { activeUnit, applyCommand, attackPlan, chooseTacticalCommand, living, distance } from '../../src/rules/battle.ts';
import type { Battle, TacticalCommand } from '../../src/rules/battle.ts';
import { routesFrom } from '../../src/rules/movement.ts';
import { pokemonFor } from '../../src/domain/Pokemon.ts';
const root=resolve(process.argv[2]??'docs/reports/balance-2026-10-15');
const diagnostics=[];
for(let index=1;index<=3;index++) {
  const path=resolve(root,`unresolved-save-${index}.json`);
  let battle:Battle=JSON.parse(readFileSync(path,'utf8')).run.battle;
  const initialRound=battle.round,commands:TacticalCommand[]=[];
  for(let i=0;i<300&&battle.outcome==='playing';i++) {
    const actor=activeUnit(battle)!;let command=chooseTacticalCommand(battle);
    // A legal manual-style intervention: move to an immediate firing position
    // instead of repeatedly guarding. Enemy behavior is not replaced.
    if(actor.team==='ally'&&command.kind==='attack'&&pokemonFor(actor.speciesId).action(command.actionId??'basic',actor)!.preview(actor,actor).category==='status'&&!battle.moved) {
      const enemies=living(battle).filter(unit=>unit.team==='enemy');
      const options=[...routesFrom(battle.board,living(battle),actor.id).values()].filter(route=>route.cost>0&&route.cost<=actor.remaining).map(route=>{
        const point=route.path.at(-1)!;
        const damage=Math.max(0,...enemies.flatMap(enemy=>pokemonFor(actor.speciesId).actionsFor(actor).filter(action=>action.definition.target==='enemy').map(action=>{
          const plan=attackPlan(battle,enemy.id,point,action.definition.id);return plan.ok?plan.hits.reduce((sum,hit)=>sum+hit.damage,0):0;
        })));
        return {point,damage,distance:Math.min(...enemies.map(enemy=>distance(point,enemy))),cost:route.cost};
      }).sort((a,b)=>b.damage-a.damage||a.distance-b.distance||a.cost-b.cost);
      if(options[0])command={kind:'move',destination:options[0].point};
    }
    const result=applyCommand(battle,command);assert(result.ok);battle=result.state;commands.push(command);
  }
  diagnostics.push({example:index,initialRound,outcome:battle.outcome,extraRounds:battle.round-initialRound,commands:commands.length,firstOrders:commands.slice(0,12),lastLog:battle.log.slice(-8)});
}
writeFileSync(resolve(root,'guard-lock-diagnostics.json'),JSON.stringify(diagnostics,null,2)+'\n');
console.log(JSON.stringify(diagnostics.map(({firstOrders,lastLog,...result})=>result)));
