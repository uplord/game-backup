'use client';
import { useEffect, useState } from 'react';
type Preview={version:string;counts:Record<string,number>;total:number};
export default function SeedDefaultsButton(){
 const [preview,setPreview]=useState<Preview|null>(null);
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');
 useEffect(()=>{void fetch('/api/content/seed-defaults',{cache:'no-store'}).then(r=>r.ok?r.json():Promise.reject()).then(setPreview).catch(()=>setMessage('Unable to preview bundled defaults.'));},[]);
 async function importDefaults(){
  if(!preview||!window.confirm(`Import up to ${preview.total} bundled definitions as drafts? Existing drafts and published content will not be changed.`))return;
  setBusy(true);setMessage('');
  try {
   const response=await fetch('/api/content/seed-defaults',{method:'POST'});
   const result=await response.json();
   if(!response.ok)throw new Error(result.errors?.join(' · ')??result.error??'Import failed');
   setMessage(`Imported ${result.created} draft(s); skipped ${result.skipped} existing draft(s). Refresh the page to see updated counts.`);
  }catch(e){setMessage(e instanceof Error?e.message:'Import failed');}
  finally{setBusy(false);}
 }
 return <section className="panel seed-panel"><div><h2>Import default content</h2><p>Copy the game's bundled definitions into editable Firestore drafts. Existing drafts are never overwritten; nothing is published.</p>{preview&&<p className="muted">Bundle {preview.version} · {preview.total} definitions across {Object.values(preview.counts).filter(n=>n>0).length} categories</p>}</div><div><button disabled={busy||!preview} onClick={importDefaults}>{busy?'Importing…':'Add missing defaults'}</button>{message&&<p role="status">{message}</p>}</div></section>;
}
