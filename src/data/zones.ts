export type Zone = { id: string; name: string; maps: [string,string]; enemies: [number[],number[]] };
export const ZONES: Zone[] = [
  {id:'rock',name:'Roca · Ciudad Plateada',maps:['quarry','pass'],enemies:[[74,75,12],[75,74,4]]},
  {id:'water',name:'Agua · Ciudad Celeste',maps:['pond','canal'],enemies:[[7,8,12],[8,7,25]]},
];
export const zonesForEdition = (edition: number): Zone[] => ZONES.slice(0,Math.min(8,(edition-9)*2));
