export const CREW = ['Astronaut','Inginer','Medic','Gardian','Detectiv','Hunter'];
export const TRAITORS = ['Sabotor','Mimetic','Umbră','Infiltrator','Hacker'];
export const ROLES = [...CREW,...TRAITORS];
export const INFO = {
  Astronaut:'Localizezi următoarea misiune. Repară stația și observă echipajul.',
  Inginer:'Calibrezi terminalele mai repede, folosind secvențe mai scurte.',
  Medic:'Protejezi un participant apropiat timp de 20 de secunde.',
  Gardian:'Activezi un scut personal timp de 15 secunde.',
  Detectiv:'Analizezi un semnal deconectat pentru a afla cine l-a perturbat.',
  Hunter:'Membru al echipajului. Scannerul are 3 încărcări și poate neutraliza doar trădători.',
  Sabotor:'Declanșezi o avarie simulată. Echipajul are 75 de secunde să intervină.',
  Mimetic:'Copiezi identitatea unui participant apropiat timp de 12 secunde.',
  Umbră:'Activezi un camuflaj holografic pentru 8 secunde.',
  Infiltrator:'Te deplasezi mai repede timp de 6 secunde. Poți izola costume din apropiere.',
  Hacker:'Întrerupi harta de senzori timp de 20 de secunde.'
};
export const COLORS = ['#67e7da','#f4a269','#83a8ed','#d6a3d9','#e8d56f','#9dd3b4','#c4cadc','#e48d8a','#af9de0','#ddc0a5','#9bc781','#8ed1e7'];
export const NAMES = ['TU','NOVA','ATLAS','IRIS','ORION','VEGA','KAI','LYRA','AXEL','LUNA','ECHO','SOL','ASTRA','NEON','RHEA','TITAN','IO','ARES','ELARA','NYX','ZEN','ARCO','HALO','MIRA','ZENIT','ARGO','QUASAR','LEO','DIONE','ERIS','SIRIUS','ALTAIR','RIGEL','CAPELLA','SORA','THEA','CATO','NIX','ARIEL','CAL'];
export const BASE_MAP_CELLS=53,MAP_MULTIPLIER=6,CELL_SIZE=4;
export const SECTORS=[
  {name:'Laborator',x:-20,z:-20,color:'#92b9ef'},
  {name:'Navigație',x:20,z:-20,color:'#c6a1e8'},
  {name:'Seră orbitală',x:-20,z:20,color:'#83d69b'},
  {name:'Hangar',x:20,z:20,color:'#e6b675'}
];
export const TASKS = [
  {id:0,name:'Reactor · calibrare',room:'Reactor',x:2.8,z:-21.5},
  {id:1,name:'Navigație · antenă',room:'Navigație',x:22.8,z:-21.5},
  {id:2,name:'Laborator · bioscaner',room:'Laborator',x:-21.5,z:-22.8},
  {id:3,name:'Seră orbitală · filtre',room:'Seră orbitală',x:-22.8,z:21.5},
  {id:4,name:'Reactor · energie',room:'Reactor',x:-2.8,z:-18},
  {id:5,name:'Hangar · date',room:'Hangar',x:21.5,z:22.8}
];
export const isTraitor = role => TRAITORS.includes(role);
export const dist = (a,b) => Math.hypot(a.x-b.x,a.z-b.z);
export const clamp = (v,a,b) => Math.max(a,Math.min(b,v));
export class Random {
  constructor(seed=Date.now()){this.value=seed>>>0;}
  next(){let t=this.value+=0x6D2B79F5;t=Math.imul(t^t>>>15,t|1);t^=t+Math.imul(t^t>>>7,t|61);return ((t^t>>>14)>>>0)/4294967296;}
  int(a,b){return a+Math.floor(this.next()*(b-a+1));}
  pick(list){return list[this.int(0,list.length-1)];}
  shuffle(list){for(let i=list.length-1;i>0;i--){const j=this.int(0,i);[list[i],list[j]]=[list[j],list[i]];}return list;}
}
export class Match {
  constructor(onEvent=()=>{}){this.onEvent=onEvent;this.phase='menu';this.players=[];this.signals=[];this.log=[];}
  emit(type,message=''){const e={type,message};this.log.push(e);this.onEvent(e);}
  start(total=12,traitors=2,role='Astronaut',seed=Date.now()){
    total=clamp(Math.floor(total),12,40);traitors=clamp(Math.floor(traitors),1,5);
    if(!ROLES.includes(role))role='Astronaut';
    this.rng=new Random(seed);this.elapsed=0;this.reactor=-1;this.sabotageCd=35;this.sensorsOff=0;this.votes=new Map();this.result=null;this.signals=[];this.log=[];
    const ids=this.rng.shuffle(Array.from({length:total-1},(_,i)=>i+1));
    const traitorIds=new Set(ids.slice(0,traitors-Number(isTraitor(role))));
    this.players=Array.from({length:total},(_,id)=>{
      const r=id===0?role:this.rng.pick(traitorIds.has(id)?TRAITORS:CREW);
      return {id,name:NAMES[id],role:r,traitor:isTraitor(r),alive:true,tasks:[],x:0,z:0,actionCd:18,abilityCd:0,ammo:r==='Hunter'?3:0,protectedUntil:-1,hiddenUntil:-1,boostUntil:-1,mimicUntil:-1,mimicId:-1,emergencyUsed:false,suspicion:new Set()};
    });
    this.required=(total-traitors)*TASKS.length;this.phase='active';this.emit('start','Legătură stabilă. Repară OMEGA-9 și descoperă cine perturbă misiunea.');
  }
  tick(dt){
    if(this.phase==='meeting'){this.meetingLeft-=dt;if(this.meetingLeft<=0)this.resolveVotes();return;}
    if(this.phase!=='active')return;
    this.elapsed+=dt;this.sabotageCd=Math.max(0,this.sabotageCd-dt);this.sensorsOff=Math.max(0,this.sensorsOff-dt);
    for(const p of this.players){p.actionCd=Math.max(0,p.actionCd-dt);p.abilityCd=Math.max(0,p.abilityCd-dt);}
    if(this.reactor>0){this.reactor-=dt;if(this.reactor<=0)this.end('traitors','Avaria simulată nu a fost rezolvată la timp.');}
    this.checkWin();
  }
  alive(traitors){return this.players.filter(p=>p.alive&&p.traitor===traitors).length;}
  progress(){return this.players.reduce((s,p)=>s+(p.traitor?0:p.tasks.length),0);}
  completeTask(id,task){
    const p=this.players[id];if(this.phase!=='active'||!p||p.traitor||!Number.isInteger(task)||!TASKS[task]||p.tasks.includes(task))return false;
    p.tasks.push(task);if(id===0)this.emit('task',`Misiune încheiată: ${TASKS[task].name}.`);this.checkWin();return true;
  }
  isolate(attacker,target){
    const a=this.players[attacker],v=this.players[target];
    if(this.phase!=='active'||!a?.alive||!v?.alive||!a.traitor||v.traitor||a.actionCd>0||dist(a,v)>2.8)return false;
    if(v.protectedUntil>this.elapsed){a.actionCd=6;this.emit('notice','Un scut a protejat un costum.');return false;}
    v.alive=false;a.hiddenUntil=-1;a.actionCd=a.role==='Infiltrator'?22:30;
    this.signals.push({id:target,x:v.x,z:v.z,source:attacker,time:this.elapsed});
    if(target===0)this.emit('isolated','Costumul tău este izolat. Ca ecou holografic poți termina misiunile, dar nu mai votezi.');
    this.checkWin();return true;
  }
  scan(shooter,target=-1){
    const p=this.players[shooter],out={fired:false,neutralized:false,target};
    if(this.phase!=='active'||!p?.alive||p.role!=='Hunter'||p.traitor||p.ammo<=0||p.abilityCd>0||target< -1||target>=this.players.length)return out;
    p.ammo--;p.abilityCd=3;out.fired=true;
    const v=this.players[target];
    if(!v?.alive||!v.traitor||dist(p,v)>25||v.protectedUntil>this.elapsed)return out;
    v.alive=false;out.neutralized=true;this.signals.push({id:target,x:v.x,z:v.z,source:shooter,time:this.elapsed});
    this.emit('notice',`${p.name} a neutralizat un semnal perturbator. Echipajul este protejat.`);this.checkWin();return out;
  }
  sabotage(id){const p=this.players[id];if(this.phase!=='active'||!p?.alive||!p.traitor||this.reactor>0||this.sabotageCd>0)return false;this.reactor=75;this.sabotageCd=100;this.emit('alarm','Avarie simulată la reactor! Calibrează unul dintre terminalele din camera Reactor.');return true;}
  repair(id){const p=this.players[id];if(this.phase!=='active'||!p?.alive||p.traitor||this.reactor<=0||Math.min(dist(p,TASKS[0]),dist(p,TASKS[4]))>3)return false;this.reactor=-1;this.emit('notice','Reactor stabilizat. Misiunea continuă.');return true;}
  meeting(id,signal=-1){
    const p=this.players[id];if(this.phase!=='active'||!p?.alive)return false;
    if(signal<0){if(p.emergencyUsed||this.reactor>0||Math.hypot(p.x,p.z)>3.5)return false;p.emergencyUsed=true;}
    else if(!this.signals.some(s=>s.id===signal&&dist(p,s)<=4))return false;
    this.phase='meeting';this.meetingLeft=25;this.votes.clear();this.emit('meeting',`${p.name} a ${signal<0?'convocat o ședință':'raportat un semnal deconectat'}.`);return true;
  }
  vote(id,target){const p=this.players[id];if(this.phase!=='meeting'||!p?.alive||this.votes.has(id)||!Number.isInteger(target)||target< -1||(target!==-1&&!this.players[target]?.alive))return false;this.votes.set(id,target);return true;}
  resolveVotes(){
    if(this.phase!=='meeting')return;
    for(const p of this.players)if(p.alive&&!this.votes.has(p.id))this.votes.set(p.id,-1);
    const tally=new Map();for(const id of this.votes.values())tally.set(id,(tally.get(id)||0)+1);
    const max=Math.max(...tally.values()),leaders=[...tally].filter(([,n])=>n===max).map(([id])=>id);
    let msg='Egalitate sau abținere. Nimeni nu a fost izolat.';
    if(leaders.length===1&&leaders[0]>=0){const p=this.players[leaders[0]];p.alive=false;msg=`${p.name} a fost izolat din misiune. Făcea parte din ${p.traitor?'echipa trădătorilor':'echipaj'}.`;}
    this.signals=[];this.phase='active';for(const p of this.players){p.actionCd=Math.max(p.actionCd,8);if(p.role==='Hunter')p.abilityCd=Math.max(p.abilityCd,3);}
    this.emit('resume',msg);this.checkWin();
  }
  checkWin(){if(this.phase!=='active')return;if(this.alive(true)===0)this.end('crew','Toți trădătorii au fost descoperiți.');else if(this.alive(true)>=this.alive(false))this.end('traitors','Trădătorii au preluat controlul simulării.');else if(this.progress()>=this.required)this.end('crew','Toate sistemele stației au fost reparate.');}
  end(winner,reason){if(this.phase==='ended')return;this.phase='ended';this.result={winner,reason};this.emit('result',reason);}
}

export class StationMap {
  constructor(){
    this.cells=new Set();this.obstacles=[];
    for(let x=-6;x<=6;x++)for(let z=-6;z<=6;z++)if((Math.abs(x)<=1&&Math.abs(z)<=1)||x===0||z===0||(Math.abs(x)>=4&&Math.abs(z)<=1)||(Math.abs(z)>=4&&Math.abs(x)<=1))this.cells.add(`${x},${z}`);
    // Retain the original 53 tiles, then add connected rooms, a two-tile ring and shortcuts.
    for(let x=-9;x<=9;x++)for(let z=-9;z<=9;z++){
      const ax=Math.abs(x),az=Math.abs(z);
      if(Math.max(ax,az)>=8||x===0||z===0||(ax>=3&&ax<=7&&az>=3&&az<=7)||(ax===2&&[3,4,5].includes(az))||(az===2&&[3,4,5].includes(ax)))this.cells.add(`${x},${z}`);
    }
    this.cells.add('0,-10'); // Observatory alcove: 318 floor tiles, exactly six times the original.
    const coords=[...this.cells].map(k=>k.split(',').map(Number));
    this.bounds={minX:Math.min(...coords.map(c=>c[0]))*4-2,maxX:Math.max(...coords.map(c=>c[0]))*4+2,minZ:Math.min(...coords.map(c=>c[1]))*4-2,maxZ:Math.max(...coords.map(c=>c[1]))*4+2};
    const b=this.bounds;this.mapScale=328/Math.max(b.maxX-b.minX,b.maxZ-b.minZ);
    this.mapCenter={x:(b.minX+b.maxX)/2,z:(b.minZ+b.maxZ)/2};
    this.obstacles.push({x:0,z:0,w:2.5,d:2});
  }
  has(x,z){return this.cells.has(`${x},${z}`);}
  sector(p){return SECTORS.find(s=>Math.abs(p.x-s.x)<=10&&Math.abs(p.z-s.z)<=10);}
  project(p){return {x:180+(p.x-this.mapCenter.x)*this.mapScale,y:180+(p.z-this.mapCenter.z)*this.mapScale};}
  room(p){if(p.z< -38)return 'Observator';if(Math.abs(p.x)>=30||Math.abs(p.z)>=30)return 'Galerie perimetrală';const sector=this.sector(p);if(sector)return sector.name;if(p.z< -14)return 'Reactor';if(p.z>14)return 'Suport vital';if(p.x< -14)return 'Infirmerie';if(p.x>14)return 'Comunicații';return Math.abs(p.x)<6&&Math.abs(p.z)<6?'Nod central':'Coridor de tranzit';}
  walkable(x,z,r=.3){
    for(const a of [-r,r])for(const b of [-r,r])if(!this.has(Math.round((x+a)/4),Math.round((z+b)/4)))return false;
    for(const o of this.obstacles){const dx=Math.max(Math.abs(x-o.x)-o.w/2,0),dz=Math.max(Math.abs(z-o.z)-o.d/2,0);if(dx*dx+dz*dz<r*r)return false;}
    return true;
  }
  lineClear(a,b){const n=Math.ceil(dist(a,b)*5);for(let i=0;i<=n;i++){const t=n?i/n:0,x=a.x+(b.x-a.x)*t,z=a.z+(b.z-a.z)*t;if(!this.has(Math.round(x/4),Math.round(z/4)))return false;}return true;}
  path(a,b){
    const start=[Math.round(a.x/4),Math.round(a.z/4)],goal=[Math.round(b.x/4),Math.round(b.z/4)],key=p=>p.join(',');
    if(!this.has(...start)||!this.has(...goal))return [];
    const queue=[start],parents=new Map([[key(start),null]]);let found=false;
    for(let i=0;i<queue.length;i++){const p=queue[i];if(key(p)===key(goal)){found=true;break;}for(const [dx,dz]of [[1,0],[-1,0],[0,1],[0,-1]]){const q=[p[0]+dx,p[1]+dz],k=key(q);if(!this.has(...q)||parents.has(k)||!this.walkable(q[0]*4,q[1]*4))continue;parents.set(k,p);queue.push(q);}}
    if(!found)return [];const out=[];let p=goal;while(p){out.push({x:p[0]*4,z:p[1]*4});p=parents.get(key(p));}out.reverse();if(out.length>1)out.shift();out.push({...b});return out;
  }
}
export function approach(t){const c={x:Math.abs(t.x)>14?Math.sign(t.x)*20:0,z:Math.abs(t.z)>14?Math.sign(t.z)*20:0},d=dist(t,c)||1;return {x:t.x+(c.x-t.x)/d*1.6,z:t.z+(c.z-t.z)/d*1.6};}
