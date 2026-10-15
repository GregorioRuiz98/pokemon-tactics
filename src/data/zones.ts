export type Zone = { id: string; name: string; maps: [string,string]; enemies: [number[],number[]] };
export const ZONES: Zone[] = [
  {id:'rock',name:'Roca · Ciudad Plateada',maps:['quarry','pass'],enemies:[[74,75,12],[75,74,4]]},
  {id:'water',name:'Agua · Ciudad Celeste',maps:['pond','canal'],enemies:[[7,8,12],[8,7,25]]},
  {id:'electric',name:'Eléctrico · Ciudad Carmín',maps:['power','switchyard'],enemies:[[25,81,74],[81,25,7]]},
  {id:'grass',name:'Planta · Ciudad Azulona',maps:['garden','grove'],enemies:[[1,43,12],[43,1,25]]},
];
export const zonesForEdition = (edition: number): Zone[] => ZONES.slice(0,Math.min(8,(edition-9)*2));
