import { NextRequest, NextResponse } from 'next/server';
import { getAdmin } from '../../../lib/session';
import { db } from '../../../lib/firebase-admin';
import { collectCandidate, diff, loadPublished, normalizeBundle, validateBundle } from '../../../lib/releases';
export const runtime='nodejs';
const validVersion=(s:unknown):s is string=>typeof s==='string'&&/^v\d+\.\d+\.\d+(?:-[a-z0-9.-]+)?$/.test(s)&&s.length<=70;
export async function GET(){
 if(!await getAdmin())return NextResponse.json({error:'Unauthorized'},{status:401});
 try{
  const candidate=await collectCandidate();
  const testing=await db.collection('content_testing').orderBy('createdAt','desc').limit(20).get();
  const releases=await db.collection('content_releases').orderBy('createdAt','desc').limit(30).get();
  return NextResponse.json({publishedVersion:candidate.version,changes:candidate.changes,errors:candidate.errors,draftCount:Object.values(candidate.draftIds).reduce((n,ids)=>n+ids.length,0),testing:testing.docs.map(d=>({id:d.id,...d.data(),bundle:undefined})),releases:releases.docs.map(d=>({id:d.id,createdAt:d.data().createdAt??null,createdBy:d.data().createdBy??null,rollbackOf:d.data().rollbackOf??null}))});
 }catch(e){console.error('Release listing failed',e);return NextResponse.json({error:'Unable to load releases'},{status:500});}
}
export async function POST(req:NextRequest){
 const admin=await getAdmin();if(!admin)return NextResponse.json({error:'Unauthorized'},{status:401});
 try{
  const body=await req.json();const action=body?.action;const version=body?.version;
  if(!validVersion(version))return NextResponse.json({error:'Use a version such as v0.1.0'},{status:400});
  if(action==='stage'){
   const candidate=await collectCandidate();
   if(candidate.errors.length)return NextResponse.json({error:'Validation failed',errors:candidate.errors},{status:400});
   if(!candidate.changes.length)return NextResponse.json({error:'No changes to stage'},{status:400});
   const ref=db.collection('content_testing').doc(version);
   const releaseRef=db.collection('content_releases').doc(version);
   const [existing,alreadyPublished]=await Promise.all([ref.get(),releaseRef.get()]);
   if(existing.exists||alreadyPublished.exists)return NextResponse.json({error:'Version already exists'},{status:409});
   const bundle={schema_version:1,content_version:version,definitions:candidate.definitions};
   await ref.create({bundle,baseVersion:candidate.version,changes:candidate.changes,draftIds:candidate.draftIds,createdBy:admin.uid,createdAt:new Date().toISOString(),status:'Testing'});
   return NextResponse.json({ok:true,version,changes:candidate.changes});
  }
  if(action==='publish'){
   const stagedRef=db.collection('content_testing').doc(version);
   const staged=await stagedRef.get();if(!staged.exists)return NextResponse.json({error:'Testing release not found'},{status:404});
   const record=staged.data()!;const definitions=normalizeBundle(record.bundle);
   const errors=validateBundle(definitions);if(errors.length)return NextResponse.json({error:'Validation failed',errors},{status:400});
   const releaseRef=db.collection('content_releases').doc(version);const currentRef=db.doc('content_config/current');
   await db.runTransaction(async tx=>{
    const [current,existing,stage]=await Promise.all([tx.get(currentRef),tx.get(releaseRef),tx.get(stagedRef)]);
    if(existing.exists)throw new Error('Release version already published');
    if(!stage.exists)throw new Error('Testing release missing');
    if((current.data()?.publishedVersion??null)!==(record.baseVersion??null))throw new Error('Published version changed since staging. Create a new testing release.');
    tx.create(releaseRef,{bundle:record.bundle,createdAt:new Date().toISOString(),createdBy:admin.uid,baseVersion:record.baseVersion??null,changes:record.changes??[]});
    tx.set(currentRef,{publishedVersion:version,updatedAt:new Date().toISOString(),updatedBy:admin.uid},{merge:true});
    tx.delete(stagedRef);
   });
   // Only clear drafts that are unchanged since staging; never discard later edits.
   for(const [category,ids] of Object.entries((record.draftIds??{}) as Record<string,string[]>)){
    const definitionsById=new Map(definitions[category as keyof typeof definitions]?.map(d=>[String(d.id),d])??[]);
    for(const id of ids){
     const ref=db.collection('content_drafts').doc(category).collection('entries').doc(id);
     const snap=await ref.get();if(snap.exists&&JSON.stringify(snap.data()?.definition)===JSON.stringify(definitionsById.get(id)))await ref.delete();
    }
   }
   return NextResponse.json({ok:true,version});
  }
  if(action==='rollback'){
   const target=body?.target;
   if(!validVersion(target))return NextResponse.json({error:'Invalid rollback target'},{status:400});
   const source=await db.collection('content_releases').doc(target).get();if(!source.exists)return NextResponse.json({error:'Target release not found'},{status:404});
   const definitions=normalizeBundle(source.data()?.bundle);const errors=validateBundle(definitions);
   if(errors.length)return NextResponse.json({error:'Target release invalid',errors},{status:400});
   const current=await loadPublished();const changes=diff(current.definitions,definitions);
   const releaseRef=db.collection('content_releases').doc(version),currentRef=db.doc('content_config/current');
   await db.runTransaction(async tx=>{
    const [existing,currentDoc]=await Promise.all([tx.get(releaseRef),tx.get(currentRef)]);
    if(existing.exists)throw new Error('Version already exists');
    if((currentDoc.data()?.publishedVersion??null)!==current.version)throw new Error('Published version changed. Refresh and retry.');
    tx.create(releaseRef,{bundle:{schema_version:1,content_version:version,definitions},createdAt:new Date().toISOString(),createdBy:admin.uid,rollbackOf:target,baseVersion:current.version,changes});
    tx.set(currentRef,{publishedVersion:version,updatedAt:new Date().toISOString(),updatedBy:admin.uid},{merge:true});
   });
   return NextResponse.json({ok:true,version,rollbackOf:target});
  }
  return NextResponse.json({error:'Unknown action'},{status:400});
 }catch(e){console.error('Release operation failed',e);return NextResponse.json({error:e instanceof Error?e.message:'Release operation failed'},{status:409});}
}
