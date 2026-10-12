import { NextRequest, NextResponse } from 'next/server';
import { getAdmin } from '../../../../lib/session';
import { db } from '../../../../lib/firebase-admin';
import { categories, type Category, validate } from '../../../../lib/content-editor';
export const runtime='nodejs';
function checkCategory(s:string): s is Category {return (categories as readonly string[]).includes(s);}
async function authorized(category:string) {const user=await getAdmin();return user && checkCategory(category);}
export async function GET(_req:NextRequest,{params}:{params:Promise<{category:string}>}) {
 const {category}=await params;
 if(!await authorized(category)) return NextResponse.json({error:'Unauthorized'},{status:401});
 try {
  const snapshot=await db.collection('content_drafts').doc(category).collection('entries').limit(500).get();
  const drafts=snapshot.docs.map(d=>({id:d.id,...d.data()}));
  const current=await db.doc('content_config/current').get(); const version=current.data()?.publishedVersion;
  let published:Record<string,unknown>[]=[];
  if(typeof version==='string' && version){const release=await db.collection('content_releases').doc(version).get();const defs=release.data()?.bundle?.definitions;const arr=defs?.[category];if(Array.isArray(arr)) published=arr;}
  return NextResponse.json({drafts,published,version:version??null});
 }catch(e){console.error('Content list failed',e);return NextResponse.json({error:'Unable to load content'},{status:500});}
}
export async function PUT(req:NextRequest,{params}:{params:Promise<{category:string}>}) {
 const {category}=await params;if(!await authorized(category)) return NextResponse.json({error:'Unauthorized'},{status:401});
 try {
  const body=await req.json();const definition=body?.definition;const errors=validate(category as Category,definition);
  if(errors.length) return NextResponse.json({error:'Validation failed',errors},{status:400});
  const id=(definition as {id:string}).id;
  const ref=db.collection('content_drafts').doc(category).collection('entries').doc(id);
  await ref.set({definition,updatedAt:new Date().toISOString(),updatedBy:(await getAdmin())!.uid});
  return NextResponse.json({ok:true,id});
 }catch(e){console.error('Save draft failed',e);return NextResponse.json({error:'Unable to save draft'},{status:500});}
}
export async function DELETE(req:NextRequest,{params}:{params:Promise<{category:string}>}) {
 const {category}=await params;if(!await authorized(category)) return NextResponse.json({error:'Unauthorized'},{status:401});
 const id=new URL(req.url).searchParams.get('id');
 if(!id|| !/^[a-z0-9][a-z0-9_-]{0,79}$/.test(id))return NextResponse.json({error:'Invalid ID'},{status:400});
 try {await db.collection('content_drafts').doc(category).collection('entries').doc(id).delete();return NextResponse.json({ok:true});}
 catch(e){console.error('Delete draft failed',e);return NextResponse.json({error:'Unable to delete draft'},{status:500});}
}
