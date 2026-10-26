import * as T from 'three';
import {COLORS,TASKS,SECTORS,StationMap} from './rules.mjs';

export class SceneView {
  constructor(canvas){
    this.canvas=canvas;this.world=new StationMap();this.scene=new T.Scene();this.scene.background=new T.Color('#07151e');this.scene.fog=new T.Fog('#07151e',18,65);
    this.renderer=new T.WebGLRenderer({canvas,antialias:true,alpha:false,powerPreference:'high-performance'});
    this.renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.5));this.renderer.outputColorSpace=T.SRGBColorSpace;this.renderer.toneMapping=T.ACESFilmicToneMapping;this.renderer.toneMappingExposure=1.25;
    this.camera=new T.PerspectiveCamera(77,1,.07,90);this.camera.layers.enable(1);this.camera.rotation.order='YXZ';this.scene.add(this.camera);
    this.scene.add(new T.HemisphereLight('#b6e5f1','#1f3241',2.5));const sun=new T.DirectionalLight('#e0f3ff',1.8);sun.position.set(3,7,4);this.scene.add(sun);
    this.materials=new Map();this.geos={box:new T.BoxGeometry(1,1,1),sphere:new T.SphereGeometry(1,12,8),capsule:new T.CapsuleGeometry(.5,1,3,10),cylinder:new T.CylinderGeometry(1,1,1,12)};
    this.staticBatches=new Map();this.rayObjects=[];this.actors=new Map();this.holograms=new Map();this.beams=[];this.ray=new T.Raycaster();this.elapsed=0;
    this.humanTarget=new T.Mesh(new T.BoxGeometry(.6,1.7,.55));this.humanTarget.userData.id=0;
    this.station();this.flushStatic();this.scanner=this.makeScanner(true);this.camera.add(this.scanner);this.scanner.position.set(.22,-.22,-.54);this.scanner.rotation.set(-.1,-.18,.08);this.scanner.visible=false;
    this.camera.position.set(3,1.63,5);this.camera.rotation.y=.35;this.resize();
  }
  material(color,glow=false){const key=color+glow;if(!this.materials.has(key))this.materials.set(key,new T.MeshStandardMaterial({color,roughness:.72,metalness:.25,emissive:glow?color:'#000000',emissiveIntensity:glow?1.2:0}));return this.materials.get(key);}
  box(parent,x,y,z,w,h,d,color,glow=false,staticMesh=false){
    if(staticMesh){const key=color+glow;if(!this.staticBatches.has(key))this.staticBatches.set(key,{color,glow,entries:[]});this.staticBatches.get(key).entries.push([x,y,z,w,h,d]);return;}
    const m=new T.Mesh(this.geos.box,this.material(color,glow));m.position.set(x,y,z);m.scale.set(w,h,d);parent.add(m);return m;
  }
  solid(x,y,z,w,h,d,color,glow=false){this.box(this.scene,x,y,z,w,h,d,color,glow,true);}
  prop(x,z,w,d,h,color){this.solid(x,h/2,z,w,h,d,color);this.world.obstacles.push({x,z,w,d});}
  flushStatic(){const matrix=new T.Matrix4(),q=new T.Quaternion();for(const batch of this.staticBatches.values()){const m=new T.InstancedMesh(this.geos.box,this.material(batch.color,batch.glow),batch.entries.length);batch.entries.forEach(([x,y,z,w,h,d],i)=>{matrix.compose(new T.Vector3(x,y,z),q,new T.Vector3(w,h,d));m.setMatrixAt(i,matrix);});m.instanceMatrix.needsUpdate=true;this.scene.add(m);this.rayObjects.push(m);}this.staticBatches.clear();}
  sprite(text,w=3,h=.7,color='#c8fbef'){
    const c=document.createElement('canvas');c.width=512;c.height=128;const ctx=c.getContext('2d');ctx.textAlign='center';ctx.textBaseline='middle';ctx.font='600 38px system-ui';ctx.fillStyle=color;ctx.fillText(text,256,64,500);
    const tex=new T.CanvasTexture(c);tex.colorSpace=T.SRGBColorSpace;const sprite=new T.Sprite(new T.SpriteMaterial({map:tex,transparent:true,depthWrite:false}));sprite.layers.set(1);sprite.scale.set(w,h,1);return sprite;
  }
  station(){
    for(const key of this.world.cells){const [cx,cz]=key.split(',').map(Number),x=cx*4,z=cz*4;
      const sector=this.world.sector({x,z}),accent=sector?.color||'#2ad2c8';
      this.solid(x,-.12,z,4,.24,4,sector?'#2e4650':'#263c49');this.solid(x,3.75,z,4,.2,4,'#142732');
      this.solid(x+1.96,.006,z,.028,.012,4,'#527380');this.solid(x,.006,z+1.96,4,.012,.028,'#527380');
      for(const [dx,dz]of [[1,0],[-1,0],[0,1],[0,-1]])if(!this.world.has(cx+dx,cz+dz)){
        const wx=x+dx*2,wz=z+dz*2;
        this.solid(wx,1.8,wz,dx?.22:4,3.6,dz?.22:4,'#172e3c');
        this.solid(wx,1.7,wz,dx?.24:3.65,2.15,dz?.24:3.65,'#314f60');
        this.solid(wx,.26,wz,dx?.28:3.6,.045,dz?.28:3.6,accent,true);
      }
      if((cx+cz)%3===0)this.solid(x,3.56,z,.2,.045,2.4,'#c8f8ff',true);
    }
    this.solid(0,.65,0,2.5,1.3,2,'#1c3948');this.solid(0,1.32,0,2.6,.08,2.1,'#4e8791');this.solid(0,1.43,.5,.4,.15,.4,'#ffbf78',true);
    const sign=this.sprite('OMEGA—9 · ADUNARE',3.2,.6);sign.position.set(0,2.55,-1);this.scene.add(sign);
    for(const t of TASKS){
      this.prop(t.x,t.z,1.15,.7,1.4,'#355969');
      this.solid(t.x,1.53,t.z,1.08,.12,.72,'#48e6cf',true);
      this.solid(t.x,1.22,t.z+.37,.85,.35,.03,'#60e5ce',true);
      const s=this.sprite(t.name.toUpperCase(),2.9,.52);s.position.set(t.x,2.3,t.z);this.scene.add(s);
    }
    for(const [x,z]of [[-2.8,23.7],[2.8,23.7]]){this.prop(x,z,1.3,1.4,1.55,'#285b60');this.solid(x,1.6,z,1.1,.06,1.2,'#64d9b5',true);}
    for(const [x,z]of [[-24,-3.7],[-17,3.7]]){this.prop(x,z,1.4,2.0,.85,'#4c6772');this.solid(x,.94,z,1.35,.12,1.9,'#b2ced1');}
    for(const x of [-3.8,3.8]){this.prop(x,-24,1.5,1.5,2.3,'#425b67');this.solid(x,1.2,-23.22,.7,1.6,.04,'#edb565',true);}
    for(const data of [{text:'01 · REACTOR',x:0,z:-14.2,rot:0},{text:'02 · COMUNICAȚII',x:14.2,z:0,rot:-Math.PI/2},{text:'03 · SUPORT VITAL',x:0,z:14.2,rot:Math.PI},{text:'04 · INFIRMERIE',x:-14.2,z:0,rot:Math.PI/2}]){
      const sign=this.sprite(data.text,3.4,.65);sign.position.set(data.x,2.96,data.z);this.scene.add(sign);
      if(Math.abs(data.x)>0){this.solid(data.x,1.75,-1.8,.18,3.5,.15,'#458d97');this.solid(data.x,1.75,1.8,.18,3.5,.15,'#458d97');this.solid(data.x,3.48,0,.2,.08,3.6,'#7cebd7',true);}
      else{this.solid(-1.8,1.75,data.z,.15,3.5,.18,'#458d97');this.solid(1.8,1.75,data.z,.15,3.5,.18,'#458d97');this.solid(0,3.48,data.z,3.6,.08,.2,'#7cebd7',true);}
    }
    for(const s of SECTORS){
      const sign=this.sprite(s.name.toUpperCase(),4.5,.8,s.color);sign.position.set(s.x,3,s.z);this.scene.add(sign);
      this.solid(s.x,.014,s.z,3.4,.02,3.4,'#36545f');
      for(const side of [-1,1]){
        const x=s.x+side*7.35,z=s.z+7.35;
        this.prop(x,z,1.1,1.1,1.65,'#38515d');this.solid(x,1.7,z,1,.06,1,s.color,true);
      }
      // Distinctive room fixtures leave the navigation grid and terminal approaches clear.
      if(s.name==='Seră orbitală')for(const side of [-1,1]){this.solid(s.x+side*7.35,2.1,s.z+7.35,.6,.7,.6,'#83d69b');}
      if(s.name==='Hangar')this.solid(s.x,3.2,s.z,6.5,.18,1.5,s.color);
      if(s.name==='Navigație')this.solid(s.x,3.45,s.z,3.5,.08,3.5,s.color,true);
      if(s.name==='Laborator')for(const side of [-1,1])this.solid(s.x+side*7.35,2.4,s.z+7.35,.55,.5,.55,'#92b9ef',true);
    }
    this.solid(0,1.95,-41.8,3.1,2.2,.04,'#06111f');
    for(let i=0;i<16;i++)this.solid(-1.25+(i%5)*.59,1.12+(i%7)*.25,-41.76,.035,.035,.025,'#bfe4ff',true);
    for(const [x,z,label]of [[0,-34,'OBSERVATOR ↑'],[0,34,'GALERIE · SUD'],[-34,0,'GALERIE · VEST'],[34,0,'GALERIE · EST']]){const sign=this.sprite(label,3.2,.6);sign.position.set(x,2.9,z);this.scene.add(sign);}
    for(const [x,z]of [[0,0],[0,-21],[0,21],[-21,0],[21,0]]){const l=new T.PointLight('#70d5d2',9,12,1.6);l.position.set(x,2.8,z);this.scene.add(l);}
  }
  part(group,type,x,y,z,sx,sy,sz,color){const m=new T.Mesh(this.geos[type],this.material(color));m.position.set(x,y,z);m.scale.set(sx,sy,sz);group.add(m);return m;}
  makeScanner(hands=false){
    const g=new T.Group();this.box(g,0,0,0,.23,.17,.065,'#2c5364');this.box(g,0,.01,.041,.195,.12,.018,'#65e4cd',true);
    const lens=this.part(g,'cylinder',-.052,.012,.057,.035,.018,.035,'#143340');lens.rotation.x=Math.PI/2;
    for(let i=0;i<3;i++)this.box(g,.022+i*.022,.01,.057,.012,.045,.008,'#f2d58b',true);
    this.box(g,0,-.096,0,.19,.02,.05,'#9ebfcb');if(hands){this.part(g,'sphere',-.12,-.04,-.005,.045,.06,.06,'#34616c');this.part(g,'sphere',.12,-.04,-.005,.045,.06,.06,'#34616c');}return g;
  }
  avatar(p){
    const g=new T.Group(),color=COLORS[p.id%COLORS.length];g.userData.id=p.id;
    this.part(g,'capsule',0,1.04,0,.58,.35,.35,color);this.part(g,'sphere',0,1.58,0,.28,.29,.25,color);
    this.part(g,'sphere',0,1.61,-.18,.24,.15,.13,'#102d3d');this.box(g,0,1.08,.24,.38,.52,.22,'#1a303e');this.box(g,0,1.19,-.22,.29,.20,.04,'#b6c9cf');
    const limbs=[];
    for(const side of [-1,1]){
      const leg=new T.Group();leg.position.set(side*.16,.76,0);this.part(leg,'capsule',0,-.28,0,.22,.31,.25,color);this.box(leg,0,-.62,-.05,.24,.16,.32,'#142a36');g.add(leg);limbs.push(leg);
      const arm=new T.Group();arm.position.set(side*.37,1.36,0);this.part(arm,'capsule',0,-.25,0,.19,.29,.21,color);this.part(arm,'sphere',0,-.52,0,.095,.10,.10,'#25414e');g.add(arm);limbs.push(arm);
    }
    const tag=this.sprite(p.name,1.2,.34,'#e0f6ef');tag.position.y=2.05;g.add(tag);
    const scanner=this.makeScanner();scanner.position.set(.32,.9,-.25);scanner.scale.setScalar(.8);g.add(scanner);g.userData={id:p.id,limbs,tag,scanner};this.scene.add(g);return g;
  }
  reset(players){
    for(const a of this.actors.values())this.disposeGroup(a);this.actors.clear();for(const h of this.holograms.values())this.disposeGroup(h);this.holograms.clear();
    for(const p of players)if(p.id!==0)this.actors.set(p.id,this.avatar(p));
  }
  disposeGroup(group){this.scene.remove(group);group.traverse(o=>{if(o.isSprite){o.material.map?.dispose();o.material.dispose();}});}
  sync(match,dt){
    this.elapsed+=dt;
    for(const p of match.players){if(p.id===0)continue;const a=this.actors.get(p.id);a.position.set(p.x,0,p.z);a.visible=p.alive&&p.hiddenUntil<=match.elapsed;
      if(p.heading!==undefined)a.rotation.y=p.heading;
      a.userData.limbs.forEach((l,i)=>l.rotation.x=Math.sin(this.elapsed*7+i*Math.PI)*(p.moving?.35:.015));
      const copy=p.mimicUntil>match.elapsed?match.players[p.mimicId]:p;a.userData.scanner.visible=copy.role==='Hunter';
      if(a.userData.shownId!==copy.id){a.userData.shownId=copy.id;a.children.filter(o=>o.isMesh&&o.material===this.material(COLORS[(a.userData.oldColor??p.id)%COLORS.length])).forEach(o=>o.material=this.material(COLORS[copy.id%COLORS.length]));a.userData.oldColor=copy.id;const tag=this.sprite(copy.name,1.2,.34);tag.position.y=2.05;a.remove(a.userData.tag);a.userData.tag.material.map.dispose();a.userData.tag.material.dispose();a.add(tag);a.userData.tag=tag;}
    }
    const ids=new Set(match.signals.map(s=>s.id));for(const [id,g]of this.holograms)if(!ids.has(id)){this.disposeGroup(g);this.holograms.delete(id);}
    for(const s of match.signals)if(!this.holograms.has(s.id)){
      const g=new T.Group(),mat=new T.MeshBasicMaterial({color:'#6de6dc',transparent:true,opacity:.38,depthWrite:false});
      const capsule=new T.Mesh(this.geos.capsule,mat);capsule.scale.set(.4,.48,.3);capsule.position.y=.85;g.add(capsule);
      const ring=new T.Mesh(new T.TorusGeometry(.5,.025,6,24),this.material('#65e6cf',true));ring.rotation.x=Math.PI/2;ring.position.y=.04;g.add(ring);const tag=this.sprite('SEMNAL DECONECTAT',2.3,.42);tag.position.y=1.9;g.add(tag);g.position.set(s.x,0,s.z);this.scene.add(g);this.holograms.set(s.id,g);
    }
    this.scanner.visible=match.players[0]?.role==='Hunter'&&match.players[0]?.alive;
    for(let i=this.beams.length-1;i>=0;i--){const b=this.beams[i];b.life-=dt;b.line.material.opacity=Math.max(0,b.life*5);if(b.life<=0){this.scene.remove(b.line);b.line.geometry.dispose();b.line.material.dispose();this.beams.splice(i,1);}}
  }
  trace(players,shooter=0,origin=null,direction=null){
    this.scene.updateMatrixWorld(true);const from=origin||this.camera.getWorldPosition(new T.Vector3()),dir=direction||this.camera.getWorldDirection(new T.Vector3());this.ray.set(from,dir);this.ray.far=25;
    const objects=[...this.rayObjects,...[...this.actors].filter(([id])=>id!==shooter&&players[id].alive).map(([,a])=>a)];
    if(shooter!==0&&players[0]?.alive){this.humanTarget.position.set(players[0].x,.85,players[0].z);this.humanTarget.updateMatrixWorld(true);objects.push(this.humanTarget);}
    const hit=this.ray.intersectObjects(objects,true)[0];if(!hit)return {target:-1,end:from.clone().addScaledVector(dir,25)};
    let node=hit.object;while(node&&node.userData.id===undefined)node=node.parent;
    return {target:node?.userData.id??-1,end:hit.point};
  }
  pulse(end){const from=this.scanner.getWorldPosition(new T.Vector3());const line=new T.Line(new T.BufferGeometry().setFromPoints([from,end]),new T.LineBasicMaterial({color:'#89fff0',transparent:true,opacity:1}));this.scene.add(line);this.beams.push({line,life:.2});}
  look(x,z,yaw,pitch,bob=0){this.camera.position.set(x,1.63+bob,z);this.camera.rotation.set(pitch,yaw,0,'YXZ');}
  resize(){const w=innerWidth,h=innerHeight;this.renderer.setSize(w,h,false);this.camera.aspect=w/h;this.camera.updateProjectionMatrix();if(this.scanner){this.scanner.position.x=Math.min(.22,.18*w/h);this.scanner.scale.setScalar(w/h<.75?.82:1);}}
  render(){this.renderer.render(this.scene,this.camera);}
}
