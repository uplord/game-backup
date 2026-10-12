import 'server-only';
import { db } from './firebase-admin';
import { categories, validate, type Category } from './content-editor';

export type Definitions = Record<Category, Record<string, unknown>[]>;
export type Change = {category: Category; id: string; action: 'Added'|'Changed'|'Removed'};
const asRecord = (v:unknown): v is Record<string,unknown> => !!v && typeof v==='object' && !Array.isArray(v);
export const emptyDefinitions = (): Definitions => Object.fromEntries(categories.map(c=>[c,[]])) as Definitions;
export function normalizeBundle(raw:unknown): Definitions {
 const source=asRecord(raw) && asRecord(raw.definitions) ? raw.definitions : {};
 const result=emptyDefinitions();
 for(const c of categories) result[c]=Array.isArray(source[c]) ? (source[c] as unknown[]).filter(asRecord) : [];
 return result;
}
export function diff(before:Definitions, after:Definitions):Change[] {
 const out:Change[]=[];
 for(const category of categories){
  const old=new Map(before[category].map(x=>[String(x.id),x]));
  const next=new Map(after[category].map(x=>[String(x.id),x]));
  for(const [id,v] of next) if(!old.has(id))out.push({category,id,action:'Added'}); else if(JSON.stringify(old.get(id))!==JSON.stringify(v))out.push({category,id,action:'Changed'});
  for(const id of old.keys())if(!next.has(id))out.push({category,id,action:'Removed'});
 }
 return out;
}
export function validateBundle(defs:Definitions):string[] {
 const errors:string[]=[];
 const ids=Object.fromEntries(categories.map(c=>[c,new Set(defs[c].map(d=>String(d.id)))])) as Record<Category,Set<string>>;
 const reference=(category:Category, id:unknown, source:string)=>{if(typeof id==='string' && id && !ids[category].has(id))errors.push(`${source}: unknown ${category} ID ${id}`);};
 for(const category of categories){
  const seen=new Set<string>();
  for(const d of defs[category]){
   const id=String(d.id??''); const source=`${category}/${id}`;
   if(seen.has(id))errors.push(`${source}: duplicate ID`);seen.add(id);
   errors.push(...validate(category,d).map(e=>`${source}: ${e}`));
   if(category==='resources'){reference('items',d.item_id,source);reference('skills',d.skill_id,source);}
   if(category==='recipes')for(const key of ['ingredients','outputs'])if(Array.isArray(d[key]))for(const entry of d[key])if(asRecord(entry))reference('items',entry.item_id,source);
   if(category==='shops' && Array.isArray(d.items))for(const entry of d.items)if(asRecord(entry))reference('items',entry.item_id,source);
   if(category==='loot_tables' && Array.isArray(d.entries))for(const entry of d.entries)if(asRecord(entry))reference('items',entry.item_id,source);
  }
 }
 return errors;
}
export async function loadPublished(){
 const current=await db.doc('content_config/current').get();
 const version=typeof current.data()?.publishedVersion==='string' ? current.data()!.publishedVersion as string : null;
 if(!version)return {version:null as string|null,definitions:emptyDefinitions()};
 const release=await db.collection('content_releases').doc(version).get();
 if(!release.exists)throw new Error(`Published release ${version} does not exist`);
 return {version,definitions:normalizeBundle(release.data()?.bundle)};
}
export async function collectCandidate(){
 const published=await loadPublished();const definitions=structuredClone(published.definitions);
 const draftIds:Record<string,string[]>={};
 for(const category of categories){
  const docs=await db.collection('content_drafts').doc(category).collection('entries').get();
  draftIds[category]=[];
  const map=new Map(definitions[category].map(d=>[String(d.id),d]));
  for(const doc of docs.docs){
   const definition=doc.data().definition;
   if(!asRecord(definition))throw new Error(`Invalid draft: ${category}/${doc.id}`);
   if(definition.id!==doc.id)throw new Error(`Draft ID mismatch: ${category}/${doc.id}`);
   map.set(doc.id,definition);draftIds[category].push(doc.id);
  }
  definitions[category]=[...map.values()].sort((a,b)=>String(a.id).localeCompare(String(b.id)));
 }
 return {...published,definitions,draftIds,changes:diff(published.definitions,definitions),errors:validateBundle(definitions)};
}
