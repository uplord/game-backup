export const categories = ['items','enemies','resources','npcs','skills','loot_tables','shops','quests','recipes','objects','areas'] as const;
export type Category = typeof categories[number];
export const fields: Record<Category, {key:string;label:string;type?:'number'|'boolean'|'json';required?:boolean}[]> = {
 items:[{key:'name',label:'Name',required:true},{key:'stackable',label:'Stackable',type:'boolean'},{key:'equipmentSlot',label:'Equipment slot'},{key:'requiredLevel',label:'Required level',type:'number'}],
 enemies:[{key:'name',label:'Name',required:true},{key:'level',label:'Level',type:'number'},{key:'max_hp',label:'Maximum HP',type:'number'},{key:'interaction_label',label:'Interaction label'}],
 resources:[{key:'name',label:'Name',required:true},{key:'item_id',label:'Reward item ID'},{key:'skill_id',label:'Skill ID'},{key:'required_level',label:'Required level',type:'number'},{key:'respawn_seconds',label:'Respawn seconds',type:'number'},{key:'interaction_label',label:'Interaction label'}],
 npcs:[{key:'name',label:'Name',required:true},{key:'interaction_label',label:'Interaction label'},{key:'dialogue',label:'Dialogue'}],
 skills:[{key:'name',label:'Name',required:true},{key:'cooldown',label:'Cooldown',type:'number'},{key:'required_level',label:'Required level',type:'number'}],
 loot_tables:[{key:'name',label:'Name',required:true},{key:'entries',label:'Entries (JSON)',type:'json'}],
 shops:[{key:'name',label:'Name',required:true},{key:'items',label:'Items (JSON)',type:'json'}],
 quests:[{key:'name',label:'Name',required:true},{key:'objectives',label:'Objectives (JSON)',type:'json'}],
 recipes:[{key:'name',label:'Name',required:true},{key:'ingredients',label:'Ingredients (JSON)',type:'json'},{key:'outputs',label:'Outputs (JSON)',type:'json'}],
 objects:[{key:'name',label:'Name',required:true},{key:'interaction_label',label:'Interaction label'}],
 areas:[{key:'name',label:'Name',required:true}]
};
export function validate(category:Category, value:unknown): string[] {
 if (!value || typeof value !== 'object' || Array.isArray(value)) return ['Definition must be an object'];
 const v=value as Record<string,unknown>; const errors:string[]=[];
 if(typeof v.id!=='string'|| !/^[a-z0-9][a-z0-9_-]{0,79}$/.test(v.id)) errors.push('ID must use lowercase letters, numbers, _ or - (max 80 characters)');
 for(const f of fields[category]) {
  const x=v[f.key]; if(f.required && (typeof x!=='string'||!x.trim())) errors.push(`${f.label} is required`);
  if(x===undefined||x===null||x==='') continue;
  if(f.type==='number' && (typeof x!=='number'||!Number.isFinite(x)||x<0)) errors.push(`${f.label} must be a nonnegative number`);
  if(f.type==='boolean' && typeof x!=='boolean') errors.push(`${f.label} must be true or false`);
  if(f.type==='json' && !Array.isArray(x) && (typeof x!=='object'||x===null)) errors.push(`${f.label} must be JSON object or array`);
 }
 return errors;
}
