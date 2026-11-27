/* Backup v2: staging only. No production fallback to non-atomic imports. */
const PrismaBackup = (() => {
const keys=['transactions','study_tasks','bill_reminders','investments','investment_snapshots','investment_dividends'];
const aliases={transactions:['finances','transactions'],study_tasks:['studies','tasks'],bill_reminders:['bills'],investments:['investments'],investment_snapshots:['investmentSnapshots'],investment_dividends:['manualInvestmentDividends','investmentDividends']};
const fields={
transactions:['type','amount','category','transaction_date','description'],
study_tasks:['title','subject','due_date','notes','done','estimated_minutes','completed_at'],
bill_reminders:['title','amount','due_date','paid'],
investments:['ticker','name','asset_type','quantity','average_price','purchase_date','monthly_income','notes','manual_price'],
investment_snapshots:['snapshot_date','total_value','total_cost'],
investment_dividends:['asset_name','amount','payment_date','notes']};
const obj=x=>x!==null&&typeof x==='object'&&!Array.isArray(x);
function normalize(input){
 if(!obj(input)|| (input.version!==undefined&&input.version!==2))throw Error('Versão de backup inválida.');
 const legacy=input.version===undefined;
 if(!legacy&&input.format!=='prisma-backup')throw Error('Formato inválido.');
 if(legacy&&!Object.values(aliases).flat().some(k=>Array.isArray(input[k])))throw Error('Arquivo não reconhecido.');
 const out={version:2,format:'prisma-backup'};
 for(const k of keys){
 const rows=legacy?(aliases[k].map(a=>input[a]).find(a=>a!==undefined)??[]):input[k];
 if(!Array.isArray(rows)||rows.length>10000)throw Error('Lista inválida: '+k);
 out[k]=rows.map((row,i)=>{
 if(!obj(row))throw Error('Registro inválido: '+k+' '+(i+1));
 const x={...row};
 if(legacy){
 if(k==='transactions'){x.transaction_date??=x.date;x.category??='Outros';}
 if(k==='study_tasks'){x.due_date??=x.due??null;x.notes??='';x.done??=false;x.estimated_minutes??=x.estimatedMinutes??25;x.completed_at??=null;}
 if(k==='bill_reminders')x.paid??=false;
 if(k==='investments'){x.asset_type??=x.type;x.average_price??=x.averagePrice;x.purchase_date??=x.purchaseDate;x.monthly_income??=x.monthlyIncome??0;x.manual_price??=x.manualPrice??null;x.notes??='';}
 if(k==='investment_dividends'){x.asset_name??=x.assetName;x.payment_date??=x.paymentDate;x.notes??='';}
 }
 const clean={}; if(x.id!==undefined){if(typeof x.id!=='string'||!/^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$/i.test(x.id))throw Error('ID inválido: '+k);clean.id=x.id;}
 for(const field of fields[k]){
 let v=x[field];
 if(['due_date','completed_at','manual_price'].includes(field)&&v==null){clean[field]=null;continue;}
 if(['amount','quantity','average_price','monthly_income','manual_price','total_value','total_cost','estimated_minutes'].includes(field)){
 if((typeof v!=='number'&&typeof v!=='string')||String(v).trim()===''||!Number.isFinite(Number(v))||Number(v)<0||(['amount','quantity','estimated_minutes'].includes(field)&&Number(v)<=0))throw Error('Número inválido: '+k+' / '+field);
 v=Number(v);if(field==='estimated_minutes'&&!Number.isInteger(v))throw Error('Minutos inválidos.');
 }else if(['done','paid'].includes(field)){if(typeof v!=='boolean')throw Error('Estado inválido: '+field);}
 else if(field.endsWith('_date')){if(typeof v!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(v)||!Number.isFinite(Date.parse(v))||new Date(v).toISOString().slice(0,10)!==v)throw Error('Data inválida: '+field);}
 else if(field==='completed_at'){if(typeof v!=='string'||!Number.isFinite(Date.parse(v)))throw Error('Data de conclusão inválida.');}
 else if(typeof v!=='string'||v.length>10000||(!['notes'].includes(field)&&!v.trim()))throw Error('Texto inválido: '+field);
 clean[field]=v;
 }
 if(k==='transactions'&&!['income','expense'].includes(clean.type))throw Error('Tipo de lançamento inválido.');
 if(k==='investments'&&!['renda_fixa','fii','acao','etf','bdr','cripto','outro'].includes(clean.asset_type))throw Error('Tipo de investimento inválido.');
 return clean;
 });
 }
 return out;
}
async function exportData(db,user){
 const payload={version:2,format:'prisma-backup',exportedAt:new Date().toISOString()};
 for(const k of [...keys,'profiles','user_settings']){
 const rows=[];for(let start=0;;start+=500){const {data,error}=await db.from('prisma_'+k).select('*').eq(k==='profiles'?'id':'user_id',user.id).order(k==='user_settings'?'user_id':'id').range(start,start+499);if(error)throw error;rows.push(...data);if(data.length<500)break;}
 payload[k]=rows.map(({user_id,...row})=>row);
 }
 const url=URL.createObjectURL(new Blob([JSON.stringify(payload,null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download='prisma-backup-v2-'+new Date().toISOString().slice(0,10)+'.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
}
async function restore(db,file,confirmFn){
 if(!file||file.size>5*1024*1024)throw Error('Selecione um JSON de até 5 MB.');
 const payload=normalize(JSON.parse(await file.text()));
 const call=async preview=>{const {data,error}=await db.rpc('prisma_restore_v2',{payload,preview});if(error)throw error;return data;};
 const plan=await call(true);
 if(!await confirmFn(Object.entries(plan).map(([k,v])=>k+': '+v.new+' novos, '+v.skipped+' ignorados').join('\n')+'\n\nConfigurações e perfil existentes não serão alterados. Continuar?',plan))return null;
 return await call(false);
}
return {normalize,exportData,restore};
})();
if(typeof module!=='undefined')module.exports=PrismaBackup;
