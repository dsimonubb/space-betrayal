const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('node:fs/promises');
(async()=>{
 const browser=await chromium.launch({headless:true,...(process.env.BROWSER_EXE?{executablePath:process.env.BROWSER_EXE}:{})});
 const page=await browser.newPage({viewport:{width:1440,height:900},hasTouch:true});const errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto('http://127.0.0.1:18780/evidence/test/index.html');await page.waitForFunction(()=>window.__SPACE_TEST__);await page.locator('.start').click();
 const routes=await page.evaluate(()=>{
  const {game:g,TASKS}=window.__SPACE_TEST__,world=g.view.world;g.modal='pause';const points=[{x:0,z:4},{x:-20,z:-20},{x:20,z:-20},{x:-20,z:20},{x:20,z:20},{x:0,z:-40},{x:34,z:0},{x:0,z:34},{x:-34,z:0}];let tested=0;
  for(const a of points)for(const t of TASKS){
   const center={x:Math.abs(t.x)>14?Math.sign(t.x)*20:0,z:Math.abs(t.z)>14?Math.sign(t.z)*20:0},d=Math.hypot(t.x-center.x,t.z-center.z),b={x:t.x+(center.x-t.x)/d*1.6,z:t.z+(center.z-t.z)/d*1.6},path=world.path(a,b);
   if(!path.length)throw Error('Unreachable '+JSON.stringify({a,t}));let from=a;
   for(const to of path){const n=Math.ceil(Math.hypot(to.x-from.x,to.z-from.z)/.15);for(let i=0;i<=n;i++){const k=n?i/n:0,p={x:from.x+(to.x-from.x)*k,z:from.z+(to.z-from.z)*k};if(!world.walkable(p.x,p.z))throw Error('Route crosses solid '+JSON.stringify({a,t,p}));}from=to;}tested++;
  }
  return {tested,tiles:world.cells.size,area:world.cells.size*16,bounds:world.bounds};
 });
 for(const [name,x,z,yaw]of [['laborator',-20,-14,0],['navigatie',20,-14,0],['sera',-20,14,Math.PI],['hangar',20,14,Math.PI],['observator',0,-38.5,0]]){
  await page.evaluate(({x,z,yaw})=>{const g=window.__SPACE_TEST__.game;g.modal='';Object.assign(g.player,{x,z,yaw,pitch:0});Object.assign(g.match.players[0],{x,z});for(const p of g.match.players)if(p.id)p.wait=10000;g.view.look(x,z,yaw,0);g.update();},{x,z,yaw});await page.waitForTimeout(150);await page.screenshot({path:'evidence/expanded-'+name+'.png'});
 }
 if(errors.length)throw Error(errors.join('\n'));await fs.writeFile('evidence/expanded-map-results.json',JSON.stringify({routes,errors},null,2));console.log(JSON.stringify({routes,errors}));await browser.close();
})().catch(e=>{console.error(e);process.exit(1);});
