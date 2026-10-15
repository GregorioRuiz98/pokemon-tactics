export const mean = (values: number[]): number => values.length ? values.reduce((sum,value)=>sum+value,0)/values.length : 0;
export const sum = (values: number[]): number => values.reduce((total,value)=>total+value,0);
export function quantile(values:number[], q:number):number {
  if(!values.length)return 0;
  const sorted=[...values].sort((a,b)=>a-b),index=(sorted.length-1)*q,low=Math.floor(index),high=Math.ceil(index);
  return sorted[low]+(sorted[high]-sorted[low])*(index-low);
}
export function wilson(successes:number,total:number):[number,number]|null {
  if(!total)return null;
  const z=1.959963984540054,p=successes/total,denominator=1+z*z/total;
  const center=(p+z*z/(2*total))/denominator;
  const margin=z*Math.sqrt(p*(1-p)/total+z*z/(4*total*total))/denominator;
  return [Math.max(0,center-margin),Math.min(1,center+margin)];
}
// Bootstrap whole seed pairs: never treat the two finales as independent campaigns.
export function pairedInterval(differences:number[], repeats=1500):[number,number] {
  let state=914773;
  const samples:number[]=[];
  for(let sample=0;sample<repeats;sample++) {
    let total=0;
    for(let i=0;i<differences.length;i++) {state=(Math.imul(state,1664525)+1013904223)>>>0;total+=differences[Math.floor(state/4294967296*differences.length)];}
    samples.push(total/differences.length);
  }
  return [quantile(samples,.025),quantile(samples,.975)];
}
