import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { pokemonFor } from '../src/domain/Pokemon.ts';
import { itemFor, HeldItem, HealingItem, heldItemFor, ITEMS } from '../src/domain/items.ts';
import { ITEM_METADATA } from '../src/data/item-metadata.ts';
import { createBattle, attackPlan, finishTurn, chooseTacticalCommand } from '../src/rules/battle.ts';
import { fieldDamage } from '../src/rules/terrain.ts';
const catalog = JSON.parse(readFileSync(new URL('../public/data/pokemon.json', import.meta.url), 'utf8'));
function duel() {
  const battle=createBattle(catalog);battle.units=battle.units.filter(unit=>[7,74].includes(unit.id));
  battle.board=Array.from({length:8},()=>Array(8).fill(0));battle.units.forEach((unit,index)=>{unit.x=index;unit.y=0;unit.tp=5;});
  battle.queue=[7,74];battle.initiative=[{id:7,score:43,tie:0},{id:74,score:20,tie:0}];battle.completed=[];battle.fields=[];
  return battle;
}
test('item classes use the five names and identifiers imported from pinned public PokeAPI data',()=>{
  assert.equal(ITEMS.length,7);assert(itemFor('potion') instanceof HealingItem);assert(itemFor('leftovers') instanceof HeldItem);
  for(const item of ITEMS)assert.equal(item.name,ITEM_METADATA[item.id].name);
  assert.equal(ITEM_METADATA['heavy-duty-boots'].pokeApiId,1178);
  const sources=JSON.parse(readFileSync(new URL('../tools/vendor/pokeapi/items-sources.json',import.meta.url),'utf8'));
  for(const [file,hash] of Object.entries(sources.sha256))assert.equal(createHash('sha256').update(readFileSync(new URL(`../tools/vendor/pokeapi/${file}`,import.meta.url))).digest('hex'),hash);
  assert.equal(heldItemFor(null),null);assert.throws(()=>heldItemFor('potion' as never));
});
test('Chaleco Asalto modifies effective special defense without rewriting the base stats or physical defense',()=>{
  const battle=duel(),target=battle.units[0],actor=pokemonFor(4).createCombatant(catalog.find((species:{id:number})=>species.id===4),'enemy',{x:1,y:0});
  const original=target.specialDefense;target.heldItem='assault-vest';
  const special=pokemonFor(4).action('basic')!;
  assert.deepEqual(special.preview(actor,target),special.preview(actor,{...target,heldItem:null,specialDefense:original*1.5}));
  assert.equal(target.specialDefense,original);
  const physical=pokemonFor(74).action('basic')!;
  assert.deepEqual(physical.preview(battle.units[1],target),physical.preview(battle.units[1],{...target,heldItem:null}));
});
test('Chaleco Asalto rejects guard/status actions in previews and AI while damaging actions remain legal',()=>{
  const battle=duel();battle.units[0].heldItem='assault-vest';
  const before=structuredClone(battle),guard=attackPlan(battle,7,undefined,'cover');
  assert(!guard.ok);if(!guard.ok)assert.match(guard.reason,/Chaleco/);
  assert(attackPlan(battle,74,undefined,'water-pulse').ok);assert.deepEqual(battle,before);
  const command=chooseTacticalCommand(battle);assert(command.kind!=='attack'||command.actionId!=='cover');
});
test('Restos heals only after closing a living activation, after damage, and never revives',()=>{
  const battle=duel(),actor=battle.units[0];actor.hp=20;actor.heldItem='leftovers';actor.status={kind:'poison',remaining:1};battle.fields=[{x:0,y:0,kind:'embers',expires:3}];
  const result=finishTurn(battle);assert(result.ok);assert.equal(result.state.units[0].hp,13);assert.equal(actor.hp,20);
  const lethal=structuredClone(battle);lethal.units[0].hp=2;
  const death=finishTurn(lethal);assert(death.ok);assert.equal(death.state.units[0].hp,0);assert.equal(death.state.outcome,'defeat');
});
test('Restos respects max HP and Botas Gruesas prevent embers without blocking status damage',()=>{
  const battle=duel(),actor=battle.units[0];actor.heldItem='leftovers';actor.hp=actor.maxHp-1;
  const healed=finishTurn(battle);assert(healed.ok);assert.equal(healed.state.units[0].hp,actor.maxHp);
  actor.heldItem='heavy-duty-boots';actor.hp=actor.maxHp;actor.status={kind:'burn',remaining:1};battle.fields=[{x:0,y:0,kind:'embers',expires:3}];
  assert.equal(fieldDamage(actor,battle.fields),0);assert.equal(fieldDamage({...actor,heldItem:null},battle.fields),4);
  const burned=finishTurn(battle);assert(burned.ok);assert.equal(burned.state.units[0].hp,actor.maxHp-Math.floor(actor.maxHp/16));
});
