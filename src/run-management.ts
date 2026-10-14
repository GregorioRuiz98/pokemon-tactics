import { TYPE_NAMES } from './data/catalog.ts';
import type { PokemonSpecies } from './data/catalog.ts';
import { pokemonFor } from './domain/Pokemon.ts';
import { ITEMS, HealingItem, HeldItem, itemFor } from './domain/items.ts';
import type { HeldItemId, ItemId } from './domain/items.ts';
import { maximumHp, currentNode, remainingStock, TEAM_LIMIT } from './rules/run.ts';
import type { Run, RunEvent } from './rules/run.ts';
export const escapeHtml = (value: string): string => value.replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character]!);
const speciesFor = (catalog: readonly PokemonSpecies[], id: number) => catalog.find(species => species.id === id)!;
const asset = (path: string): string => `${import.meta.env.BASE_URL}${path}`;
export function managementHtml(run: Run, catalog: readonly PokemonSpecies[], selectedId: number): string {
  const member = run.roster.find(member => member.id === selectedId) ?? run.roster[0];
  if (!member) return '<p>El equipo ha caído. No se pueden usar objetos para revivir.</p>';
  const maximum = maximumHp(catalog, member.speciesId);
  return `<section class="team-management" aria-labelledby="management-title"><h2 id="management-title">Bolsa y equipo</h2><label for="manage-member">Pokémon que recibirá el objeto</label><select id="manage-member">${run.roster.map(candidate => `<option value="${candidate.id}" ${candidate.id === member.id ? 'selected' : ''}>${escapeHtml(speciesFor(catalog, candidate.speciesId).name)} #${candidate.id} · ${candidate.hp}/${maximumHp(catalog, candidate.speciesId)} PS</option>`).join('')}</select><p class="gear-slot">Objeto equipado: <strong>${member.heldItem ? itemFor(member.heldItem).name : 'Ninguno'}</strong> ${member.heldItem ? '<button data-equip="">Retirar a la bolsa</button>' : ''}</p><h3>Consumibles</h3><ul class="bag-list">${ITEMS.filter(item => item instanceof HealingItem).map(item => {
    const healing = item as HealingItem, recovery = healing.restored(member.hp, maximum);
    return `<li><div><strong>${item.name}</strong><p>${recovery ? `${member.hp} → ${member.hp + recovery} PS · recupera ${recovery}` : 'PS completos'} · ${run.bag[item.id]} en la bolsa</p></div><button data-heal="${item.id}" ${recovery === 0 || run.bag[item.id] === 0 ? 'disabled' : ''}>Usar ${item.name}</button></li>`;
  }).join('')}</ul><h3>Equipables</h3><ul class="bag-list">${ITEMS.filter(item => item instanceof HeldItem).map(item => `<li><div><strong>${item.name}</strong><p>${item.description}</p><small>${run.bag[item.id]} en la bolsa${member.heldItem === item.id ? ' · equipado en este Pokémon' : ''}</small></div><button data-equip="${item.id}" ${run.bag[item.id] === 0 || member.heldItem === item.id ? 'disabled' : ''}>Equipar</button></li>`).join('')}</ul><p class="management-note">Los consumibles solo se usan fuera de combate. Al cambiar un objeto o perder un Pokémon, el equipable vuelve a la bolsa.</p></section>`;
}
export function serviceHtml(run: Run, catalog: readonly PokemonSpecies[], pendingOfferId: string | null): string {
  const node = currentNode(run)!;
  if (node.kind === 'shop') return `<section class="shop-panel" aria-labelledby="service-title"><h2 id="service-title">Tienda de la cantera</h2><p>Ofertas limitadas a esta visita. Puedes comprar y gestionar el equipo antes de continuar.</p><ul class="shop-list">${ITEMS.map(item => {
    const stock = remainingStock(run, item.id), affordable = run.money >= item.price;
    return `<li><div><h3>${item.name}</h3><p>${item.description}</p><small>${stock ? `${stock} disponibles` : 'Agotado'} · ${item.price} monedas</small></div><button data-buy="${item.id}" ${!stock || !affordable ? 'disabled' : ''}>${stock === 0 ? 'Agotado' : !affordable ? 'Saldo insuficiente' : 'Comprar'}</button></li>`;
  }).join('')}</ul></section>`;
  const pending = node.offers.find(offer => offer.id === pendingOfferId);
  return `<section class="recruit-panel" aria-labelledby="service-title"><h2 id="service-title">Sala de reclutamiento</h2><p>Tres candidatos para esta visita. Cada uno se incorpora como un miembro nuevo; las bajas anteriores siguen siendo definitivas.</p><div class="recruit-candidates">${node.offers.map(offer => {
    const species = speciesFor(catalog, offer.speciesId), sold = run.recruited.includes(offer.id);
    return `<article class="recruit-candidate"><img src="${asset(`assets/pokemon/${species.id}/thumbnail.png`)}" alt="" width="72" height="72"><h3>${escapeHtml(species.name)}</h3><div class="type-list">${species.types.map(type => `<span class="type type-${type}">${TYPE_NAMES[type]}</span>`).join('')}</div><p>${pokemonFor(species.id).role}</p><small>${maximumHp(catalog, species.id)} PS · ${offer.price} monedas</small><button data-recruit="${offer.id}" ${sold || run.money < offer.price ? 'disabled' : ''}>${sold ? 'Reclutado' : run.money < offer.price ? 'Saldo insuficiente' : run.roster.length === TEAM_LIMIT ? 'Elegir sustitución' : 'Reclutar'}</button>${!sold && run.roster.length < TEAM_LIMIT ? `<button data-replace-recruit="${offer.id}" ${run.money < offer.price ? 'disabled' : ''}>Sustituir a un miembro</button>` : ''}</article>`;
  }).join('')}</div>${pending ? `<section id="replace-panel" class="replace-panel" aria-labelledby="replace-title"><h3 id="replace-title">Incorporar a ${escapeHtml(speciesFor(catalog, pending.speciesId).name)}</h3><label for="replace-member">¿A quién sustituyes?</label><select id="replace-member">${run.roster.map(member => `<option value="${member.id}">${escapeHtml(speciesFor(catalog, member.speciesId).name)} #${member.id} · ${member.hp} PS${member.heldItem ? ` · ${itemFor(member.heldItem).name}` : ''}</option>`).join('')}</select><p>El miembro saliente quedará liberado de esta partida. Su objeto vuelve a la bolsa. Coste: ${pending.price} monedas.</p><button id="confirm-recruit">Confirmar sustitución</button><button id="cancel-recruit">Conservar equipo</button></section>` : ''}</section>`;
}
export function bindManagement(root: HTMLElement, memberId: number, changeMember: (id: number) => void, perform: (event: RunEvent, message: string, focus: string) => void): void {
  root.querySelector<HTMLSelectElement>('#manage-member')?.addEventListener('change', event => changeMember(Number((event.target as HTMLSelectElement).value)));
  root.querySelectorAll<HTMLButtonElement>('[data-heal]').forEach(button => button.addEventListener('click', () => {
    const itemId = button.dataset.heal as ItemId;
    perform({ kind: 'heal', itemId, memberId }, `${itemFor(itemId).name} utilizada. Los PS y el consumo se han registrado.`, '#manage-member');
  }));
  root.querySelectorAll<HTMLButtonElement>('[data-equip]').forEach(button => button.addEventListener('click', () => {
    const itemId = (button.dataset.equip || null) as HeldItemId | null;
    perform({ kind: 'equip', itemId, memberId }, itemId ? `${itemFor(itemId).name} equipado. El objeto anterior vuelve a la bolsa.` : 'Objeto devuelto a la bolsa.', '#manage-member');
  }));
}
