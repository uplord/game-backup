"use client";
export default function LogoutButton() { return <button className="secondary" onClick={async () => { await fetch('/api/session', { method: 'DELETE' }); window.location.assign('/login'); }}>Sign out</button>; }
