const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('node:fs/promises');
(async()=>{
 const browser=await chromium.launch({headless:true,...(process.env.BROWSER_EXE?{executablePath:process.env.BROWSER_EXE}:{})});
 const ctx=await browser.newContext({viewport:{width:390,height:844},hasTouch:true,isMobile:true}),page=await ctx.newPage();await page.goto('http://127.0.0.1:18780/evidence/test/index.html');await page.waitForFunction(()=>window.__SPACE_TEST__);
 await page.selectOption('#role','Hunter');await page.locator('.start').click();
 const stick=await page.locator('#stick').boundingBox(),cdp=await ctx.newCDPSession(page);
 const a={id:1,x:stick.x+stick.width/2,y:stick.y+stick.height/2},b={id:2,x:300,y:430};
 const before=await page.evaluate(()=>({...window.__SPACE_TEST__.game.player}));
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[a,b]});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{...a,x:a.x+30},{...b,x:b.x-35,y:b.y+10}]});await page.waitForTimeout(350);await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
 const after=await page.evaluate(()=>({...window.__SPACE_TEST__.game.player}));
 if(Math.abs(after.yaw-before.yaw)<.05||Math.abs(after.x-before.x)<.2)throw Error('multi-touch movement/look failed');
 const ray=await page.evaluate(()=>{
 const g=window.__SPACE_TEST__.game;g.modal='pause';const m=g.match;
 for(const p of m.players)if(p.id){p.x=-24;p.z=0;}
 const t=m.players.find(p=>p.traitor),crew=m.players.find(p=>p.id&&!p.traitor);
 Object.assign(g.player,{x:0,z:7,yaw:Math.PI,pitch:0});Object.assign(m.players[0],{x:0,z:7});Object.assign(t,{x:0,z:12});g.view.sync(m,0);g.view.look(0,7,Math.PI,0);
 const clear=g.view.trace(m.players).target;
 Object.assign(crew,{x:0,z:9});g.view.sync(m,0);const body=g.view.trace(m.players).target;
 Object.assign(crew,{x:-24,z:0});Object.assign(t,{x:8,z:8});g.view.sync(m,0);g.view.look(0,7,-Math.atan2(8,1),0);const wall=g.view.trace(m.players).target;
 return {clear,expected:t.id,body,expectedBody:crew.id,wall};
 });
 if(ray.clear!==ray.expected||ray.body!==ray.expectedBody||ray.wall!==-1)throw Error('ray test failed '+JSON.stringify(ray));
 const simulations=await page.evaluate(()=>{
 const g=window.__SPACE_TEST__.game,out=[];g.touch=true;
 for(let seed=1;seed<=12;seed++){
  g.start(seed%2?12:40,seed%5+1,seed%3?'Hunter':'Sabotor',seed);g.modal='pause';
  const m=g.match;for(const t of window.__SPACE_TEST__.TASKS)if(!m.players[0].traitor)m.completeTask(0,t.id);
  let i=0,meetings=0;
  for(;i<8000&&m.phase!=='ended';i++){
   if(m.phase==='meeting'){meetings++;m.vote(0,-1);g.meetingAge=30;g.botsVote();m.tick(26);}
   else {m.tick(.2);if(m.phase!=='active')break;g.botsMove(.2);if(i%2===0){g.view.sync(m,.4);g.botsThink();}}
  }
  if(!m.result)throw Error('simulation stalled seed '+seed);
  out.push({seed,total:m.players.length,traitors:seed%5+1,winner:m.result.winner,elapsed:Math.round(m.elapsed),meetings,reason:m.result.reason});
 }
 return out;
 });
 await browser.close();const result={multiTouch:{dx:after.x-before.x,yaw:after.yaw-before.yaw},ray,simulations};await fs.writeFile('evidence/mechanics-results.json',JSON.stringify(result,null,2));console.log(JSON.stringify(result));
})().catch(e=>{console.error(e);process.exit(1);});
