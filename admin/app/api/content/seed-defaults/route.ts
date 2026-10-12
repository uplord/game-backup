import { NextResponse } from 'next/server';
import { getAdmin } from '../../../../lib/session';
import { db } from '../../../../lib/firebase-admin';
import { categories, type Category, validate } from '../../../../lib/content-editor';
import defaults from '../../../../data/default-content.json';

export const runtime = 'nodejs';

// Preview is read-only. Import creates missing drafts only; never changes published releases.
export async function GET() {
 const admin = await getAdmin();
 if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
 const counts: Record<string,number> = {};
 for (const category of categories) counts[category] = (defaults.definitions[category] ?? []).length;
 return NextResponse.json({ version: defaults.content_version, counts, total: Object.values(counts).reduce((a,b)=>a+b,0) });
}

export async function POST() {
 const admin = await getAdmin();
 if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
 try {
  const candidates: {category:Category;definition:Record<string,unknown>}[] = [];
  const errors: string[] = [];
  for (const category of categories) {
   for (const definition of defaults.definitions[category] ?? []) {
    const problems = validate(category, definition);
    if (problems.length) errors.push(`${category}/${definition.id}: ${problems.join(', ')}`);
    else candidates.push({ category, definition });
   }
  }
  if (errors.length) return NextResponse.json({error:'Bundled defaults failed validation',errors},{status:422});
  let created=0, skipped=0;
  // Firestore create() is atomic per document: existing drafts cannot be overwritten.
  for (const {category,definition} of candidates) {
   const ref=db.collection('content_drafts').doc(category).collection('entries').doc(String(definition.id));
   try {
    await ref.create({ definition, updatedAt: new Date().toISOString(), updatedBy: admin.uid, source: 'bundled-defaults' });
    created++;
   } catch (error:unknown) {
    const code = (error as {code?:string|number})?.code;
    if (code===6 || code==='already-exists' || code==='ALREADY_EXISTS') { skipped++; continue; }
    throw error;
   }
  }
  return NextResponse.json({ok:true,created,skipped,total:candidates.length});
 } catch (error) {
  console.error('Seed defaults failed', error);
  return NextResponse.json({error:'Unable to import defaults. Some entries may have been created; retry safely.'},{status:500});
 }
}
