import SeedDefaultsButton from './seed-defaults-button';
import { redirect } from 'next/navigation';
import { getAdmin } from '../lib/session';
import { db } from '../lib/firebase-admin';
import LogoutButton from './logout-button';
import Link from 'next/link';
export const dynamic = 'force-dynamic';
const sections = ['items','enemies','skills','areas','resources','recipes','npcs','objects','quests','shops','loot_tables'];
export default async function Dashboard() {
  const admin = await getAdmin(); if (!admin) redirect('/login');
  let version = 'Not published'; let bundle: Record<string, unknown> | null = null; let releases: { id: string; active: boolean }[] = []; let error = '';
  try {
    const current = await db.doc('content_config/current').get();
    const v = current.data()?.publishedVersion;
    if (typeof v === 'string' && v) {
      version = v;
      const release = await db.collection('content_releases').doc(v).get();
      if (release.exists) bundle = (release.data()?.bundle ?? null) as Record<string, unknown> | null;
    }
    const snapshot = await db.collection('content_releases').limit(20).get();
    releases = snapshot.docs.map(doc => ({ id: doc.id, active: doc.id === version }));
  } catch (e) { error = e instanceof Error ? e.message : 'Unable to read Firestore'; }
  const definitions = bundle && typeof bundle.definitions === 'object' && bundle.definitions ? bundle.definitions as Record<string, unknown> : {};
  return <div className="shell"><aside><div className="brand">◆ UPLORD <span>ADMIN</span></div><div className="nav active">Overview</div><Link className="nav" href="/content/items">Content editors <small>Phase 5.4</small></Link><Link className="nav" href="/releases">Publishing <small>Phase 5.5</small></Link><div className="asidebottom">Drafts and releases enabled<br />Phase 5.5</div></aside><main className="main"><header><div><div className="eyebrow">CONTENT MANAGEMENT</div><h1>Overview</h1><p>Published content and release visibility</p></div><LogoutButton /></header>{error && <div className="error panel">Firestore error: {error}</div>}<section className="stats"><div className="panel"><div className="muted">Published release</div><div className="stat">{version}</div></div><div className="panel"><div className="muted">Definitions</div><div className="stat">{Object.values(definitions).reduce<number>((sum, value) => sum + (Array.isArray(value) ? value.length : 0), 0)}</div></div><div className="panel"><div className="muted">Available releases</div><div className="stat">{releases.length}</div></div></section><SeedDefaultsButton /><h2>Content categories</h2><section className="categories">{sections.map(s => <Link href={`/content/${s}`} className="panel category" key={s}><span>{s.replaceAll('_',' ')}</span><strong>{Array.isArray(definitions[s]) ? definitions[s].length : 0}</strong></Link>)}</section><h2>Releases</h2><section className="panel">{releases.length ? releases.map(r => <div className="release" key={r.id}><span>{r.id}</span><span className={r.active ? 'pill' : 'muted'}>{r.active ? 'Published' : 'Available'}</span></div>) : <p className="muted">No Firestore releases yet. The game can continue using its local content fallback.</p>}</section><p className="footnote">Content editors save drafts. Use Publishing to stage, validate and release changes.</p></main></div>;
}
