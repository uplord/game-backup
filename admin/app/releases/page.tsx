import { redirect } from 'next/navigation';
import { getAdmin } from '../../lib/session';
import Link from 'next/link';
import ReleaseManager from './release-manager';
export const dynamic='force-dynamic';
export default async function ReleasesPage(){
 if(!await getAdmin())redirect('/login');
 return <div className="main"><header><div><div className="eyebrow">CONTENT MANAGEMENT</div><h1>Releases</h1><p>Validate drafts, stage for testing, publish and restore previous versions.</p></div><Link className="secondary" href="/">← Dashboard</Link></header><ReleaseManager /></div>;
}
