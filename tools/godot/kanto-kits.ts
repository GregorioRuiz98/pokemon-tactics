// Reuse the real web profiles where available; never import import-lab (it writes fixtures).
import { pokemonFor } from '../../src/domain/Pokemon.ts';
import { DamageAction, DrainAction, StatusAction, AreaDamageAction, AreaStatusAction, PushAction, GuardAction } from '../../src/domain/actions.ts';
const output = {};
for (const id of [1,2,3,4,5,6,7,8,9,12,25,26,74]) {
  const profile = pokemonFor(id);
  output[id] = { role: profile.role, movement: profile.movement, actions: profile.actionsFor({ ruleset: 14 } as never).map(action => ({
    ...action.definition,
    kind: action instanceof DrainAction ? 'drain' : action instanceof AreaDamageAction ? 'area-damage' : action instanceof PushAction ? 'push' : action instanceof AreaStatusAction ? 'area-status' : action instanceof StatusAction ? 'status' : action instanceof GuardAction ? 'guard' : 'damage',
    ...(action instanceof DamageAction ? { power: action.power, category: action.category, secondary: action.secondary } : {}),
    ...(action instanceof StatusAction ? { effect: action.effect, powder: action.powder } : {}), embers: action.leavesEmbers(),
  })) };
}
process.stdout.write(JSON.stringify(output));
