import { redirect, notFound } from 'next/navigation';
import Link from 'next/link';
import { getAdmin } from '../../../lib/session';
import { categories, type Category } from '../../../lib/content-editor';
import ContentEditor from './content-editor';
export default async function ContentPage({params}:{params:Promise<{category:string}>}) {
 if(!await getAdmin()) redirect('/login');const {category}=await params;
 if(!(categories as readonly string[]).includes(category))notFound();
 return <div className="main"><header><div><Link href="/">← Overview</Link><h1>{category.replaceAll('_',' ')} editor</h1><p>Draft changes are separate from published content.</p></div></header><ContentEditor category={category as Category}/></div>;
}
