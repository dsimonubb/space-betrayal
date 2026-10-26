import {Vector3} from 'three';
import {Match,ROLES,INFO,COLORS,TASKS,dist,clamp,approach} from './rules.mjs';
import {SceneView} from './scene.mjs';
const $=id=>document.getElementById(id),esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

class Audio {
  constructor(){this.ctx=null;this.muted=false;}
  unlock(){try{this.ctx??=new (window.AudioContext||window.webkitAudioContext)();this.ctx.resume().catch(()=>{});}catch{this.muted=true;}}
  tone(kind='ui'){
    if(!this.ctx||this.muted||this.ctx.state!=='running')return;const c=this.ctx,t=c.currentTime,o=c.createOscillator(),g=c.createGain();
    const data={step:[90,40,.08,.025],ui:[600,950,.12,.025],task:[650,1250,.35,.035],scan:[400,1500,.22,.045],alarm:[440,660,.55,.03],meeting:[330,660,.4,.035]}[kind]||[600,800,.12,.02];
    o.type=kind==='step'?'triangle':'sine';o.frequency.setValueAtTime(data[0],t);o.frequency.exponentialRampToValueAtTime(data[1],t+data[2]);g.gain.setValueAtTime(.001,t);g.gain.linearRampToValueAtTime(data[3],t+.012);g.gain.exponentialRampToValueAtTime(.001,t+data[2]);o.connect(g);g.connect(c.destination);o.start(t);o.stop(t+data[2]+.02);
  }
}

export class Game {
  constructor(){
    this.view=new SceneView($('scene'));this.audio=new Audio();this.match=new Match(e=>this.event(e));this.player={x:0,z:4,yaw:0,pitch:0};this.keys=new Set();this.move={x:0,y:0};this.lookPointer=null;this.stickPointer=null;this.modal='';this.running=false;this.touch=matchMedia('(pointer:coarse)').matches||navigator.maxTouchPoints>0||innerWidth<800;this.mapOn=true;this.noticeLeft=0;this.botTimer=0;this.uiTimer=0;this.alarmTimer=0;this.stepTimer=0;this.previousLocked=false;this.last=performance.now();
    for(const role of ROLES){const o=document.createElement('option');o.value=role;o.textContent=role+(role==='Hunter'?' · scanner':'');$('role').append(o);}
    $('role').onchange=()=>this.describeRole();this.describeRole();
    for(const [id,min,max]of [['players',12,40],['traitors',1,5]])for(const [suffix,change]of [['minus',-1],['plus',1]])$(id+'-'+suffix).onclick=()=>$(id).value=clamp((Number($(id).value)||min)+change,min,max);
    $('setup').onsubmit=e=>{e.preventDefault();this.start(Number($('players').value),Number($('traitors').value),$('role').value);};
    $('help-open').onclick=()=>this.help();$('pause-open').onclick=()=>this.pause();$('use-action').onclick=()=>this.interact();$('report-action').onclick=()=>this.report();$('role-action').onclick=()=>this.ability();$('isolate-action').onclick=()=>this.action();$('look-hint').onclick=()=>this.lock();
    this.input();window.addEventListener('resize',()=>{this.view.resize();this.touch=matchMedia('(pointer:coarse)').matches||navigator.maxTouchPoints>0||innerWidth<800;});
    document.addEventListener('visibilitychange',()=>{if(document.hidden&&this.running&&!this.modal&&this.match.phase==='active')this.pause();});
    requestAnimationFrame(t=>this.frame(t));
  }
  describeRole(){$('role-info').textContent=INFO[$('role').value];}
  input(){
    document.addEventListener('keydown',e=>{
      if(e.code==='Escape'){if(this.modal==='task')this.closeTask();else if(this.modal==='pause')this.resume();else if(this.running&&this.match.phase==='active')this.pause();return;}
      if(this.modal==='task'&&/^Digit[1-4]$/.test(e.code)){e.preventDefault();if(!e.repeat)this.taskPress(Number(e.code.slice(-1)));return;}
      if(!this.running||this.modal||this.match.phase!=='active')return;if(e.target.matches('input,select,textarea'))return;
      this.keys.add(e.code);if(['KeyW','KeyA','KeyS','KeyD','ArrowUp','ArrowDown','ArrowLeft','ArrowRight','KeyE','KeyR','KeyQ','KeyF','Tab','Space'].includes(e.code))e.preventDefault();if(e.repeat)return;
      if(e.code==='KeyE')this.interact();if(e.code==='KeyR')this.report();if(e.code==='KeyQ')this.ability();if(e.code==='KeyF')this.action();if(e.code==='Tab')this.mapOn=!this.mapOn;if(e.code==='KeyM')this.audio.muted=!this.audio.muted;
    });
    document.addEventListener('keyup',e=>this.keys.delete(e.code));window.addEventListener('blur',()=>this.resetInput());
    document.addEventListener('mousemove',e=>{if(document.pointerLockElement===$('scene')&&this.canAct())this.look(e.movementX,e.movementY,.0022);});
    document.addEventListener('pointerlockchange',()=>{const locked=document.pointerLockElement===$('scene');if(this.previousLocked&&!locked&&this.running&&!this.modal&&this.match.phase==='active')this.pause();this.previousLocked=locked;});
    $('scene').addEventListener('pointerdown',e=>{
      if(!this.canAct())return;this.audio.unlock();
      if(e.pointerType==='mouse'&&!this.touch){if(document.pointerLockElement===$('scene')){if(e.button===0&&this.match.players[0].role==='Hunter')this.scan();}else{this.lock();this.lookPointer=e.pointerId;$('scene').setPointerCapture(e.pointerId);}return;}
      if(this.lookPointer===null){this.lookPointer=e.pointerId;this.lastLook={x:e.clientX,y:e.clientY};$('scene').setPointerCapture(e.pointerId);}
    });
    $('scene').addEventListener('pointermove',e=>{if(!this.canAct()||document.pointerLockElement===$('scene')||e.pointerId!==this.lookPointer)return;if(this.lastLook)this.look(e.clientX-this.lastLook.x,e.clientY-this.lastLook.y,.004);this.lastLook={x:e.clientX,y:e.clientY};});
    const endLook=e=>{if(e.pointerId===this.lookPointer){this.lookPointer=null;this.lastLook=null;}};$('scene').addEventListener('pointerup',endLook);$('scene').addEventListener('pointercancel',endLook);
    $('stick').addEventListener('pointerdown',e=>{if(!this.canAct()||this.stickPointer!==null)return;e.preventDefault();this.stickPointer=e.pointerId;$('stick').setPointerCapture(e.pointerId);this.updateStick(e);});
    $('stick').addEventListener('pointermove',e=>{if(e.pointerId===this.stickPointer)this.updateStick(e);});
    const endStick=e=>{if(e.pointerId===this.stickPointer){this.stickPointer=null;this.move={x:0,y:0};$('stick-knob').style.transform='';}};$('stick').addEventListener('pointerup',endStick);$('stick').addEventListener('pointercancel',endStick);
    for(const b of document.querySelectorAll('.actions button'))b.addEventListener('pointerdown',()=>this.audio.unlock());
    document.addEventListener('contextmenu',e=>{if(this.running)e.preventDefault();});
  }
  updateStick(e){const r=$('stick').getBoundingClientRect(),dx=(e.clientX-r.left-r.width/2)/(r.width*.42),dy=(e.clientY-r.top-r.height/2)/(r.height*.42),n=Math.max(1,Math.hypot(dx,dy));this.move={x:dx/n,y:dy/n};$('stick-knob').style.transform=`translate(${this.move.x*30}px,${this.move.y*30}px)`;}
  look(x,y,s){this.player.yaw-=x*s;this.player.pitch=clamp(this.player.pitch-y*s,-1.25,1.25);}
  resetInput(){this.keys.clear();this.move={x:0,y:0};this.lookPointer=null;this.lastLook=null;this.stickPointer=null;$('stick-knob').style.transform='';}
  lock(){if(this.touch||!this.canAct())return;try{const p=$('scene').requestPointerLock?.();p?.catch?.(()=>this.notify('Ține apăsat pe scenă și glisează pentru a privi în jur.'));}catch{this.notify('Ține apăsat pe scenă și glisează pentru a privi în jur.');}}
  unlock(){if(document.pointerLockElement)document.exitPointerLock?.();}
  canAct(){return this.running&&this.match.phase==='active'&&!this.modal;}
  start(total,traitors,role,seed){
    this.audio.unlock();this.closeDialog();this.player={x:0,z:4,yaw:0,pitch:0};this.match.start(total,traitors,role,seed);this.running=true;this.botTimer=0;
    for(const p of this.match.players)if(p.id){const arm=p.id%4,d=4.5+Math.floor(p.id/4)*1.8;p.x=arm===1?d:arm===3?-d:0;p.z=arm===0?-d:arm===2?d:0;p.route=[];p.wait=this.match.rng.next()*3;p.task=-1;p.heading=0;}
    this.match.players[0].x=0;this.match.players[0].z=4;this.view.reset(this.match.players);$('welcome').hidden=true;$('mission-stamp').hidden=true;document.body.classList.add('playing');$('hud').hidden=false;this.view.look(0,4,0,0);this.update();this.notify(`Rolul tău: ${role}. ${INFO[role]}`,9);this.lock();
  }
  menu(){this.running=false;this.match.phase='menu';this.closeDialog();this.unlock();this.resetInput();$('hud').hidden=true;$('welcome').hidden=false;$('mission-stamp').hidden=false;document.body.classList.remove('playing');this.view.scanner.visible=false;this.view.reset([]);this.describeRole();}
  event(e){
    if(e.message)this.notify(e.message,8);
    if(e.type==='meeting'){this.meetingAge=0;this.resetInput();this.showMeeting();this.audio.tone('meeting');}
    if(e.type==='resume'){this.closeDialog();this.view.sync(this.match,0);}
    if(e.type==='result'){this.resetInput();this.finish();this.audio.tone('task');}
    if(e.type==='task')this.audio.tone('task');
  }
  notify(text,seconds=5){$('toast').textContent=text;this.noticeLeft=seconds;}
  frame(now){
    requestAnimationFrame(t=>this.frame(t));const dt=Math.min((now-this.last)/1000,.05);this.last=now;if(document.hidden)return;
    if(this.running){
      if(this.modal!=='pause'&&this.match.phase!=='ended'){
        if(this.match.phase==='active'){
          if(!this.modal)this.movement(dt);this.match.players[0].x=this.player.x;this.match.players[0].z=this.player.z;
          this.match.tick(dt);if(this.match.phase==='active'){
            this.botsMove(dt);this.botTimer-=dt;if(this.botTimer<=0){this.botTimer=.4;this.botsThink();}
            if(this.match.reactor>0){this.alarmTimer-=dt;if(this.alarmTimer<=0){this.audio.tone('alarm');this.alarmTimer=2.5;}}
          }
        }else if(this.match.phase==='meeting'){this.meetingAge+=dt;this.botsVote();this.match.tick(dt);if(this.match.phase==='meeting'&&this.match.votes.size>=this.match.alive(true)+this.match.alive(false))this.match.resolveVotes();}
      }
      this.view.look(this.player.x,this.player.z,this.player.yaw,this.player.pitch);this.view.sync(this.match,dt);
      this.noticeLeft-=dt;if(this.noticeLeft<=0)$('toast').textContent='';this.uiTimer-=dt;if(this.uiTimer<=0){this.uiTimer=.1;this.update();}
    }else this.view.look(3,5,.35+Math.sin(now*.00008)*.12,0);
    this.view.render();
  }
  movement(dt){
    let x=this.move.x+Number(this.keys.has('KeyD')||this.keys.has('ArrowRight'))-Number(this.keys.has('KeyA')||this.keys.has('ArrowLeft')),z=this.move.y+Number(this.keys.has('KeyS')||this.keys.has('ArrowDown'))-Number(this.keys.has('KeyW')||this.keys.has('ArrowUp'));const n=Math.max(1,Math.hypot(x,z));x/=n;z/=n;
    const yaw=this.player.yaw,speed=this.match.players[0].boostUntil>this.match.elapsed?7.2:4.8,dx=(x*Math.cos(yaw)+z*Math.sin(yaw))*speed*dt,dz=(-x*Math.sin(yaw)+z*Math.cos(yaw))*speed*dt;
    if(this.view.world.walkable(this.player.x+dx,this.player.z))this.player.x+=dx;if(this.view.world.walkable(this.player.x,this.player.z+dz))this.player.z+=dz;
    if(Math.hypot(dx,dz)>.002){this.stepTimer-=dt;if(this.stepTimer<=0){this.audio.tone('step');this.stepTimer=.38;}}
  }
  botsMove(dt){for(const p of this.match.players){if(!p.id||!p.alive)continue;p.moving=false;p.wait=Math.max(0,p.wait-dt);if(p.wait>0||!p.route.length)continue;const dest=p.route[0],d=dist(p,dest);if(d<.17)p.route.shift();else{const step=Math.min(dt*2.3,d),dx=(dest.x-p.x)/d,dz=(dest.z-p.z)/d;p.x+=dx*step;p.z+=dz*step;p.heading=Math.atan2(-dx,-dz);p.moving=true;}}}
  visible(a,b){return this.view.world.lineClear(a,b);}
  botsThink(){
    const m=this.match;for(const p of m.players){if(!p.id||m.phase!=='active')continue;
      if(!p.alive){if(!p.traitor&&m.rng.next()<.008){const t=TASKS.find(t=>!p.tasks.includes(t.id));if(t)m.completeTask(p.id,t.id);}continue;}
      if(p.role==='Hunter'&&p.ammo>0&&p.abilityCd<=0)for(const id of p.suspicion){const accused=m.players[id];if(accused?.alive&&dist(p,accused)<=25&&this.visible(p,accused)){const o=new Vector3(p.x,1.45,p.z),dir=new Vector3(accused.x-p.x,-.1,accused.z-p.z).normalize(),hit=this.view.trace(m.players,p.id,o,dir);m.scan(p.id,hit.target);this.audio.tone('scan');break;}}
      if(m.phase!=='active')break;
      const signal=m.signals.find(s=>dist(p,s)<3&&this.visible(p,s));if(signal&&!p.traitor){m.meeting(p.id,signal.id);return;}
      if(p.traitor&&p.actionCd<=0){const near=m.players.filter(v=>v.alive&&!v.traitor&&dist(p,v)<2.7&&this.visible(p,v)).sort((a,b)=>dist(p,a)-dist(p,b))[0];if(near){const witnesses=m.players.filter(o=>o.alive&&!o.traitor&&o.id!==near.id&&dist(o,p)<7&&this.visible(o,p));if(!witnesses.length||m.rng.next()<.035)this.isolate(p.id,near.id);}}
      if(m.phase!=='active')break;
      if(p.traitor&&m.elapsed>55&&m.sabotageCd<=0&&m.rng.next()<.012)m.sabotage(p.id);
      if(p.wait>0)continue;
      if(!p.traitor&&m.reactor>0){if(m.repair(p.id)){p.route=[];p.wait=1;}else if(![0,4].includes(p.task)||!p.route.length){p.task=p.id%2?4:0;p.route=this.view.world.path(p,approach(TASKS[p.task]));}continue;}
      if(!p.route.length){if(p.task>=0&&!p.traitor&&dist(p,approach(TASKS[p.task]))<.4)m.completeTask(p.id,p.task);const options=TASKS.filter(t=>p.traitor||!p.tasks.includes(t.id));if(!options.length){p.task=-1;p.route=this.view.world.path(p,{x:0,z:3.5});p.wait=4+m.rng.next()*4;}else{p.task=m.rng.pick(options).id;p.route=this.view.world.path(p,approach(TASKS[p.task]));p.wait=5+m.rng.next()*4;}}
    }
  }
  botsVote(){const m=this.match;for(const p of m.players){if(!p.id||!p.alive||m.votes.has(p.id)||this.meetingAge<3+(p.id%7)*.6)continue;let target=[...p.suspicion].find(id=>m.players[id]?.alive)??-1;if(target<0&&!p.traitor){const testimony=m.players.filter(w=>w.alive&&!w.traitor).flatMap(w=>[...w.suspicion]).find(id=>m.players[id]?.alive);if(testimony!==undefined&&m.rng.next()<.8)target=testimony;}if(target<0&&p.traitor&&m.rng.next()<.4)target=m.rng.pick(m.players.filter(o=>o.alive&&!o.traitor))?.id??-1;m.vote(p.id,target);}}
  nearbyTask(){return TASKS.filter(t=>dist(this.player,t)<3&&this.visible(this.player,t)).sort((a,b)=>dist(this.player,a)-dist(this.player,b))[0];}
  nearbySignal(){return this.match.signals.find(s=>dist(this.player,s)<4&&this.visible(this.player,s));}
  nearbyPerson(){return this.match.players.filter(p=>p.id&&p.alive&&dist(this.player,p)<3.5&&this.visible(this.player,p)).sort((a,b)=>dist(this.player,a)-dist(this.player,b))[0];}
  interact(){if(!this.canAct())return;this.audio.unlock();const p=this.match.players[0],t=this.nearbyTask();if(t){if(p.traitor){if(!this.match.sabotage(0))this.notify(`Avarie simulată disponibilă în ${Math.ceil(this.match.sabotageCd)}s.`);return;}const repair=[0,4].includes(t.id)&&this.match.reactor>0&&p.alive;if(p.tasks.includes(t.id)&&!repair){this.notify('Acest terminal este deja calibrat.');return;}this.showTask(t.id,repair);}else if(!this.match.meeting(0))this.notify('Apropie-te de un terminal sau de masa din nodul central.');}
  report(){if(!this.canAct())return;const s=this.nearbySignal();if(!s||!this.match.meeting(0,s.id))this.notify('Nu există un semnal deconectat în apropiere.');}
  isolate(attacker,target){const a=this.match.players[attacker],hidden=a.hiddenUntil>this.match.elapsed,shown=a.mimicUntil>this.match.elapsed?a.mimicId:attacker;if(!this.visible(a,this.match.players[target])||!this.match.isolate(attacker,target))return false;if(!hidden)for(const p of this.match.players)if(p.id&&p.alive&&!p.traitor&&dist(p,a)<9&&this.visible(p,a))p.suspicion.add(shown);this.audio.tone('scan');if(target===0&&this.modal==='task')this.closeTask();return true;}
  action(){if(!this.canAct())return;const p=this.match.players[0];if(p.role==='Hunter'){this.scan();return;}if(!p.alive||!p.traitor){this.notify('Acest rol repară și investighează. Nu poate izola alte costume.');return;}const t=this.match.players.filter(v=>v.alive&&!v.traitor&&dist(p,v)<2.8&&this.visible(p,v)).sort((a,b)=>dist(p,a)-dist(p,b))[0];if(!t||!this.isolate(0,t.id))this.notify(`Izolare indisponibilă. Distanță maximă: 2,8m. Pauză: ${Math.ceil(p.actionCd)}s.`);}
  scan(){if(!this.canAct())return;const p=this.match.players[0];if(!p.alive||p.role!=='Hunter')return;if(p.ammo<=0){this.notify('Scanner fără încărcări. Poți continua misiunile și investigația.');return;}if(p.abilityCd>0){this.notify(`Scannerul se stabilizează: ${Math.ceil(p.abilityCd)}s.`);return;}const trace=this.view.trace(this.match.players),out=this.match.scan(0,trace.target);if(out.fired){this.view.pulse(trace.end);this.audio.tone('scan');if(this.match.phase==='active')this.notify(out.neutralized?'Semnal perturbator neutralizat.':`Scanare încheiată. Încărcări: ${p.ammo}. Echipajul este protejat.`);}}
  ability(){
    if(!this.canAct())return;this.audio.unlock();const p=this.match.players[0];if(!p.alive||p.abilityCd>0){this.notify('Abilitatea nu este disponibilă acum.');return;}const target=this.nearbyPerson(),m=this.match;
    switch(p.role){
      case 'Hunter':this.scan();return;
      case 'Astronaut':case 'Inginer':{const t=TASKS.filter(t=>!p.tasks.includes(t.id)).sort((a,b)=>dist(p,a)-dist(p,b))[0];this.notify(t?`Misiune apropiată: ${t.name} · ${Math.round(dist(p,t))}m în linie dreaptă.`:'Misiunile tale sunt gata. Observă echipajul și participă la ședințe.',7);p.abilityCd=3;break;}
      case 'Medic':if(!target){this.notify('Apropie-te de un participant pentru a-i proteja costumul.');return;}target.protectedUntil=m.elapsed+20;p.abilityCd=35;this.notify(`Scut medical pentru ${target.name}: 20s.`);break;
      case 'Gardian':p.protectedUntil=m.elapsed+15;p.abilityCd=35;this.notify('Scut personal activ: 15s.');break;
      case 'Detectiv':{const s=this.nearbySignal();if(!s){this.notify('Analiza necesită un semnal deconectat în apropiere.');return;}this.notify(`Ultimul semnal perturbator a purtat identitatea ${m.players[s.source].name}.`,9);p.abilityCd=12;break;}
      case 'Sabotor':if(!m.sabotage(0)){this.notify(`Avarie disponibilă în ${Math.ceil(m.sabotageCd)}s.`);return;}p.abilityCd=30;break;
      case 'Mimetic':if(!target){this.notify('Apropie-te de un participant pentru a-i copia identitatea.');return;}p.mimicId=target.id;p.mimicUntil=m.elapsed+12;p.abilityCd=35;this.notify(`Identitate copiată: ${target.name} · 12s.`);break;
      case 'Umbră':p.hiddenUntil=m.elapsed+8;p.abilityCd=35;this.notify('Camuflaj holografic activ: 8s.');break;
      case 'Infiltrator':p.boostUntil=m.elapsed+6;p.abilityCd=30;this.notify('Deplasare accelerată: 6s.');break;
      case 'Hacker':m.sensorsOff=20;p.abilityCd=40;this.notify('Harta de senzori este întreruptă pentru 20s.');break;
    }this.audio.tone('ui');
  }
  dialog(kind,title,description,html){this.modal=kind;this.resetInput();$('dialog-title').textContent=title;$('dialog-description').textContent=description;$('dialog-body').innerHTML=html;$('dialog').hidden=false;this.unlock();document.querySelector('.dialog-card').focus({preventScroll:true});}
  closeDialog(){this.modal='';$('dialog').hidden=true;$('dialog-body').replaceChildren();this.resetInput();}
  pause(){if(!this.running||this.match.phase!=='active')return;if(this.modal==='pause'){this.resume();return;}this.dialog('pause','Misiune în așteptare','Simularea locală este oprită.','<div class="dialog-actions"><button class="primary" id="resume">Continuă misiunea</button><button class="secondary" id="mute"></button><button class="secondary" id="menu">Înapoi la meniu</button></div>');$('resume').onclick=()=>this.resume();$('mute').textContent=this.audio.muted?'Sunet: oprit':'Sunet: activ';$('mute').onclick=()=>{this.audio.muted=!this.audio.muted;$('mute').textContent=this.audio.muted?'Sunet: oprit':'Sunet: activ';};$('menu').onclick=()=>this.menu();}
  resume(){this.closeDialog();this.lock();}
  showTask(id,repair){this.taskId=id;this.sequence=Array.from({length:this.match.players[0].role==='Inginer'?2:4},()=>this.match.rng.int(1,4));this.taskIndex=0;this.dialog('task',repair?'Stabilizează reactorul':'Calibrare terminal',`${TASKS[id].name}. Atinge modulele în ordinea afișată.`, '<div id="sequence" class="puzzle-sequence"></div><div class="puzzle-buttons">'+[1,2,3,4].map(n=>`<button data-module="${n}">${n}</button>`).join('')+'</div><p id="puzzle-status" class="puzzle-status">Urmează secvența de la stânga la dreapta.</p><div class="dialog-actions"><button class="secondary" id="disconnect">Deconectează terminalul</button></div>');this.sequenceText();document.querySelectorAll('[data-module]').forEach(b=>b.onclick=()=>this.taskPress(Number(b.dataset.module)));$('disconnect').onclick=()=>this.closeTask();}
  sequenceText(){$('sequence').textContent=this.sequence.map((n,i)=>i<this.taskIndex?'✓':n).join(' → ');}
  taskPress(n){if(this.modal!=='task'||this.match.phase!=='active')return;if(n===this.sequence[this.taskIndex]){this.taskIndex++;this.audio.tone('ui');$('puzzle-status').textContent=`Module calibrate: ${this.taskIndex} / ${this.sequence.length}.`;}else{this.taskIndex=0;$('puzzle-status').textContent='Semnal diferit. Reia secvența de la început.';}this.sequenceText();if(this.taskIndex===this.sequence.length){const id=this.taskId;if(dist(this.player,TASKS[id])>3.1){this.closeTask();return;}if([0,4].includes(id)&&this.match.reactor>0)this.match.repair(0);this.closeTask();this.match.completeTask(0,id);}}
  closeTask(){if(this.modal==='task'){this.closeDialog();this.lock();}}
  showMeeting(){
    const m=this.match,enabled=m.players[0].alive;const testimony=m.players.filter(p=>p.alive&&!p.traitor).flatMap(p=>[...p.suspicion].filter(id=>m.players[id]?.alive).map(id=>`${p.name}: „Am observat o perturbare lângă ${m.players[id].name}.”`)).slice(0,3);
    this.dialog('meeting','Cine perturbă misiunea?',enabled?'Votează pe baza observațiilor. Egalitatea și abținerea nu izolează pe nimeni.':'Ești un ecou holografic și urmărești ședința fără drept de vot.',`<div id="meeting-timer" class="meeting-timer"></div>${testimony.map(t=>`<p class="testimony">${esc(t)}</p>`).join('')||'<p class="testimony">Nu există mărturii directe. Poți alege să te abții.</p>'}<div class="vote-grid">${m.players.filter(p=>p.alive).map(p=>`<button data-vote="${p.id}" style="color:${COLORS[p.id%COLORS.length]}" ${enabled?'':'disabled'}>${p.name}</button>`).join('')}</div><button id="skip-vote" class="secondary" ${enabled?'':'disabled'}>Mă abțin</button>`);
    const vote=id=>{if(m.vote(0,id))document.querySelectorAll('[data-vote],#skip-vote').forEach(b=>b.disabled=true);};document.querySelectorAll('[data-vote]').forEach(b=>b.onclick=()=>vote(Number(b.dataset.vote)));$('skip-vote').onclick=()=>vote(-1);
  }
  finish(){const m=this.match,won=(m.result.winner==='traitors')===m.players[0].traitor;this.dialog('result',won?'Misiune reușită!':'Simularea s-a încheiat',m.result.reason,`<p class="role-tag">${m.result.winner==='crew'?'ECHIPAJUL':'TRĂDĂTORII'} CÂȘTIGĂ</p><p class="testimony">Identități dezvăluite</p>${m.players.filter(p=>p.traitor).map(p=>`<div class="role-tag">${p.name} · ${p.role}</div>`).join('')}<p class="testimony">Timp activ: ${Math.floor(m.elapsed/60)}:${String(Math.floor(m.elapsed)%60).padStart(2,'0')} · Sisteme: ${m.progress()} / ${m.required}</p><div class="dialog-actions"><button class="primary" id="rematch">O nouă misiune</button><button class="secondary" id="result-menu">Înapoi la meniu</button></div>`);$('rematch').onclick=()=>this.start(Number($('players').value),Number($('traitors').value),$('role').value);$('result-menu').onclick=()=>this.menu();}
  help(){const returnTo=this.running?'pause':'menu';this.dialog('help','Cum se joacă','Explorare și deducție într-o simulare spațială. Nu există violență realistă.',`<ol class="help-list"><li>Echipajul calibrează cele șase terminale marcate cu auriu pe hartă. E la terminal deschide o secvență numerică.</li><li>R raportează un semnal deconectat. E lângă masa centrală convoacă o singură ședință de urgență.</li><li>Q folosește abilitatea rolului. Hunter are un scanner cu 3 încărcări: poate neutraliza numai trădători, la maximum 25m, fără pereți sau alte costume în față.</li><li>Trădătorii perturbă sistemele cu E la terminal și pot izola un costum apropiat cu F. Echipajul are 75s să repare o avarie la reactor.</li><li>Echipajul câștigă prin misiuni sau descoperirea tuturor trădătorilor. Trădătorii câștigă la paritate numerică sau când expiră avaria.</li><li>Un costum izolat devine ecou holografic: poate încheia misiuni, dar nu votează și nu folosește abilități.</li></ol><p class="testimony">PC: WASD / săgeți · mouse sau glisare pe scenă · E folosește · R raport · Q rol · F izolează / scanează · click stânga scanează cu Hunter când privirea este capturată · Esc pauză · Tab hartă · M sunet.</p><p class="testimony">Telefon: joystick în stânga, glisare pe scenă pentru privire și butoane de acțiune în dreapta. Poți folosi două degete simultan.</p><p class="testimony">Un singur om și boți locali, fără multiplayer online. OMEGA-9 este harta disponibilă; celelalte patru sunt planificate.</p><p class="credits">Geometrie, personaje și sunete generate pentru joc. Fără imagini sau muzică descărcate. Motor grafic: Three.js, licență MIT. Nu colectăm date și nu trimitem scoruri către un server.</p><details><summary class="text-button">Licența bibliotecii grafice</summary><pre id="license-text" class="credits"></pre></details><div class="dialog-actions"><button class="primary" id="help-back">Înapoi</button></div>`);$('license-text').textContent=__THREE_LICENSE__;$('help-back').onclick=()=>{if(returnTo==='pause'){this.closeDialog();this.pause();}else this.closeDialog();};}
  update(){
    if(!this.running)return;const m=this.match,p=m.players[0];$('hud-role').textContent=(p.alive?'':'ECOU · ')+p.role.toUpperCase();$('hud-role').style.color=p.traitor?'#efd291':'#e4f3ef';$('room').textContent=this.view.world.room(this.player);$('progress-fill').style.width=`${m.progress()/m.required*100}%`;$('hud-progress').textContent=`${m.progress()} / ${m.required} sisteme · ${m.alive(true)+m.alive(false)} participanți activi`;$('hud-objective').textContent=p.traitor?'Perturbă simularea fără să fii descoperit.':`Misiunile tale: ${p.tasks.length} / 6. Urmărește punctele aurii de pe hartă.`;
    $('touch').hidden=!this.touch||!!this.modal;$('role-action').innerHTML=p.role==='Hunter'?'Scanează<small>Q</small>':'Rol<small>Q</small>';$('isolate-action').hidden=!p.traitor;$('equipment').textContent=p.role==='Hunter'?`SCANNER · ${p.ammo} / 3 ÎNCĂRCĂRI · ${p.abilityCd>0?`${Math.ceil(p.abilityCd)}s`:'PREGĂTIT'}\nQ / click · Scanează · Echipajul este protejat`:`Q · ${p.role} · ${p.abilityCd>0?`${Math.ceil(p.abilityCd)}s`:'gata'}${p.traitor?`   F · ${p.actionCd>0?`${Math.ceil(p.actionCd)}s`:'izolează'}`:''}\nEsc · Pauză   Tab · Hartă   M · Sunet`;
    $('alarm').hidden=m.reactor<=0;$('alarm').textContent=`AVARIE SIMULATĂ · ${Math.max(0,Math.ceil(m.reactor))}s`;$('context').textContent=this.modal?'':this.context();$('look-hint').hidden=this.touch||!!this.modal||document.pointerLockElement===$('scene');
    if(this.modal==='meeting'&&$('meeting-timer'))$('meeting-timer').textContent=`${Math.ceil(m.meetingLeft)}s rămase · ${m.votes.size} voturi${m.votes.has(0)?' · Ai votat':''}`;this.drawMap();
  }
  context(){const p=this.match.players[0],s=this.nearbySignal();if(s&&p.alive)return 'R · Raportează semnalul deconectat';const t=this.nearbyTask();if(t){if(p.traitor)return 'E · Avarie simulată';if([0,4].includes(t.id)&&this.match.reactor>0&&p.alive)return 'E · Stabilizează reactorul';return p.tasks.includes(t.id)?'Terminal calibrat':'E · '+t.name;}if(Math.hypot(this.player.x,this.player.z)<3.5&&p.alive)return p.emergencyUsed?'Ședința ta de urgență a fost folosită':'E · Convoacă o ședință';return '';}
  drawMap(){
    const c=$('map'),ctx=c.getContext('2d'),world=this.view.world;c.hidden=!this.mapOn;ctx.clearRect(0,0,360,360);
    if(this.match.sensorsOff>0){ctx.fillStyle='#efd291';ctx.font='16px system-ui';ctx.textAlign='center';ctx.fillText('SENZORI ÎN PAUZĂ',180,180);return;}
    const tile=world.mapScale*4;
    for(const key of world.cells){const [x,z]=key.split(',').map(Number),pos={x:x*4,z:z*4},q=world.project(pos);ctx.fillStyle=world.sector(pos)?'#41656b':'#2b4b59';ctx.fillRect(q.x-tile/2+1,q.y-tile/2+1,tile-2,tile-2);}
    const p=this.match.players[0];for(const t of TASKS)if(!p.tasks.includes(t.id)){const q=world.project(t);ctx.fillStyle='#efd291';ctx.beginPath();ctx.arc(q.x,q.y,4,0,Math.PI*2);ctx.fill();}
    const q=world.project(this.player);ctx.save();ctx.translate(q.x,q.y);ctx.rotate(-this.player.yaw);ctx.fillStyle='#8befcd';ctx.beginPath();ctx.moveTo(0,-8);ctx.lineTo(5,5);ctx.lineTo(-5,5);ctx.closePath();ctx.fill();ctx.restore();
  }
}

try{const game=new Game();if(__TEST__)window.__SPACE_TEST__={game,Match,TASKS};}catch(error){$('fatal').hidden=false;$('welcome').hidden=true;$('fatal').querySelector('p').textContent+=' '+(error?.message||'');}
