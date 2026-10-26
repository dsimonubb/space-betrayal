const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('node:fs/promises');
(async()=>{
const browser=await chromium.launch({headless:true,...(process.env.BROWSER_EXE?{executablePath:process.env.BROWSER_EXE}:{})});
const results=[],errors=[];const base='http://127.0.0.1:18780/';
for(const [name,options]of [['desktop',{viewport:{width:1440,height:900}}],['mobile',{viewport:{width:390,height:844},isMobile:true,hasTouch:true}],['landscape',{viewport:{width:844,height:390},isMobile:true,hasTouch:true}]]){
 const ctx=await browser.newContext(options),page=await ctx.newPage();
 page.on('pageerror',e=>errors.push(name+': '+e.message));
 const requests=[];page.on('request',r=>requests.push(r.url()));
 await page.goto(base+'evidence/test/index.html');
 await page.waitForFunction(()=>window.__SPACE_TEST__);
 await page.screenshot({path:'evidence/'+name+'-menu.png'});
 if(await page.locator('#fatal').isVisible())throw Error('WebGL failed');
 const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth);if(overflow)throw Error(name+' horizontal overflow');
 await page.selectOption('#role','Hunter');
 await page.locator('#setup .start').click();await page.waitForTimeout(500);
 await page.screenshot({path:'evidence/'+name+'-game.png'});
 const pos=await page.evaluate(()=>({...window.__SPACE_TEST__.game.player}));
 if(name==='desktop'){await page.keyboard.down('KeyD');await page.waitForTimeout(500);await page.keyboard.up('KeyD');}
 else{
  const stick=await page.locator('#stick').boundingBox();const cdp=await ctx.newCDPSession(page);
  const point={id:1,x:stick.x+stick.width/2,y:stick.y+stick.height/2};await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[point]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{...point,x:point.x+35}]});await page.waitForTimeout(500);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
 }
 const next=await page.evaluate(()=>({...window.__SPACE_TEST__.game.player}));if(Math.abs(next.x-pos.x)<.2)throw Error(name+' input did not move');
 if(name==='desktop')await page.keyboard.press('Escape');else await page.locator('#pause-open').click();
 await page.waitForSelector('#resume');const before=await page.evaluate(()=>window.__SPACE_TEST__.game.match.elapsed);await page.waitForTimeout(300);const after=await page.evaluate(()=>window.__SPACE_TEST__.game.match.elapsed);if(before!==after)throw Error('pause simulation advanced');
 await page.evaluate(()=>{const g=window.__SPACE_TEST__.game;g.touch=true;g.previousLocked=false;g.unlock();});
 await page.locator('#resume').click();
 await page.evaluate(()=>{const {game:g,TASKS}=window.__SPACE_TEST__;g.touch=true;g.unlock();Object.assign(g.player,{x:TASKS[0].x,z:TASKS[0].z+1.5});Object.assign(g.match.players[0],{x:g.player.x,z:g.player.z});g.interact();});
 await page.waitForSelector('[data-module]');
 const sequence=await page.evaluate(()=>[...window.__SPACE_TEST__.game.sequence]);for(const n of sequence)await page.locator('[data-module="'+n+'"]').click();
 if(await page.evaluate(()=>window.__SPACE_TEST__.game.match.players[0].tasks.length)!==1)throw Error('task did not complete');
 await page.evaluate(()=>{const g=window.__SPACE_TEST__.game;Object.assign(g.player,{x:0,z:3});Object.assign(g.match.players[0],{x:0,z:3});g.interact();});
 await page.waitForSelector('#skip-vote');await page.locator('#skip-vote').click();
 await page.evaluate(()=>window.__SPACE_TEST__.game.match.resolveVotes());
 await page.evaluate(()=>{const g=window.__SPACE_TEST__.game;for(const p of g.match.players)if(p.traitor)p.alive=false;g.match.checkWin();});
 await page.waitForSelector('#rematch');await page.screenshot({path:'evidence/'+name+'-win.png'});await page.locator('#rematch').click();
 await page.evaluate(()=>window.__SPACE_TEST__.game.match.end('traitors','Test: controlul stației a fost preluat.'));
 await page.waitForSelector('#result-menu');await page.locator('#result-menu').click();
 results.push({name,overflow,movement:Math.abs(next.x-pos.x),requests:requests.length,externalRequests:requests.filter(u=>!u.startsWith(base))});
 await ctx.close();
}
const ctx=await browser.newContext();const page=await ctx.newPage();page.on('pageerror',e=>errors.push('release: '+e.message));
await page.goto('file:///'+process.cwd().replace(/\\/g,'/')+'/dist/index.html');await page.waitForTimeout(1500);
if(await page.locator('#fatal').isVisible())throw Error('release file failed');
await page.locator('#setup .start').click();await page.waitForTimeout(300);if(!await page.locator('#hud').isVisible())throw Error('release file start failed');
results.push({name:'production-file',testHook:await page.evaluate(()=>typeof window.__SPACE_TEST__),started:true});
await browser.close();await fs.writeFile('evidence/browser-results.json',JSON.stringify({results,errors},null,2));console.log(JSON.stringify({results,errors}));if(errors.length)process.exitCode=1;
})().catch(e=>{console.error(e);process.exit(1);});
