'use client';
import { useCallback, useEffect, useState } from 'react';
type Change={category:string;id:string;action:string};
type Stage={id:string;createdAt?:string;baseVersion?:string;changes?:Change[]};
type Release={id:string;createdAt?:string;rollbackOf?:string|null};
type Data={publishedVersion:string|null;draftCount:number;changes:Change[];errors:string[];testing:Stage[];releases:Release[]};
export default function ReleaseManager(){
 const [data,setData]=useState<Data|null>(null);const [version,setVersion]=useState('v0.1.0');const [rollbackVersion,setRollbackVersion]=useState('');const [target,setTarget]=useState('');const [busy,setBusy]=useState(false);const [message,setMessage]=useState('');const [errors,setErrors]=useState<string[]>([]);
 const refresh=useCallback(async()=>{const r=await fetch('/api/releases',{cache:'no-store'});const j=await r.json();if(!r.ok)throw new Error(j.error??'Failed to load');setData(j);},[]);
 useEffect(()=>{refresh().catch(e=>setMessage(e.message));},[refresh]);
 async function act(action:string,v:string,extra:Record<string,string>={}){
  if(action==='publish'&&!confirm(`Publish ${v} to the live game?`))return;
  if(action==='rollback'&&!confirm(`Restore content from ${extra.target} as new release ${v}?`))return;
  setBusy(true);setMessage('');setErrors([]);
  try{const r=await fetch('/api/releases',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action,version:v,...extra})});const j=await r.json();if(!r.ok){setErrors(j.errors??[]);throw new Error(j.error??'Operation failed');}setMessage(`${action} completed: ${v}`);await refresh();}
  catch(e){setMessage(e instanceof Error?e.message:'Operation failed');}finally{setBusy(false);}
 }
 return <div className="release-manager">
  {message&&<div className="panel">{message}</div>}
  {errors.length>0&&<div className="panel error"><strong>Validation errors</strong><ul>{errors.map((e,i)=><li key={i}>{e}</li>)}</ul></div>}
  {!data?<p>Loading release data…</p>:<>
   <section className="stats"><div className="panel"><div className="muted">Published</div><div className="stat">{data.publishedVersion??'None'}</div></div><div className="panel"><div className="muted">Drafts</div><div className="stat">{data.draftCount}</div></div><div className="panel"><div className="muted">Pending changes</div><div className="stat">{data.changes.length}</div></div></section>
   <h2>Draft validation &amp; diff</h2><section className="panel">{data.errors.length?<div className="error"><strong>Cannot stage until fixed:</strong><ul>{data.errors.map((e,i)=><li key={i}>{e}</li>)}</ul></div>:<p>All definitions passed validation.</p>}{data.changes.length?<div className="change-list">{data.changes.map((c,i)=><div className="release" key={i}><span>{c.category} / {c.id}</span><span>{c.action}</span></div>)}</div>:<p>No changes from the published release.</p>}<div className="release-controls"><input aria-label="New testing version" value={version} onChange={e=>setVersion(e.target.value)} placeholder="v0.1.0"/><button disabled={busy||data.errors.length>0||!data.changes.length} onClick={()=>act('stage',version)}>Create testing release</button></div></section>
   <h2>Testing releases</h2><section className="panel">{data.testing.length?data.testing.map(s=><div className="release" key={s.id}><div><strong>{s.id}</strong><div className="muted">Based on {s.baseVersion??'local defaults'} · {s.changes?.length??0} changes</div></div><button disabled={busy} onClick={()=>act('publish',s.id)}>Publish</button></div>):<p>No testing releases yet.</p>}</section>
   <h2>Published history &amp; rollback</h2><section className="panel">{data.releases.length?data.releases.map(r=><div className="release" key={r.id}><div><strong>{r.id}</strong> {r.id===data.publishedVersion?'(Current)':''}<div className="muted">{r.rollbackOf?`Restored from ${r.rollbackOf}`:r.createdAt??''}</div></div><button className="secondary" disabled={busy||r.id===data.publishedVersion} onClick={()=>setTarget(r.id)}>Select restore</button></div>):<p>No releases published yet.</p>}{target&&<div className="release-controls"><span>Restore {target} as a new version:</span><input aria-label="Rollback release version" value={rollbackVersion} onChange={e=>setRollbackVersion(e.target.value)} placeholder="v0.1.1"/><button disabled={busy} onClick={()=>act('rollback',rollbackVersion,{target})}>Restore &amp; publish</button></div>}</section>
   <p className="footnote">Testing snapshots are immutable. Publishing updates content_config/current. Restores create a new version, preserving history. Changes to drafts after staging require a new testing version.</p>
  </>}
 </div>;
}
