import './styles.css';
export const metadata = { title: 'Uplord Admin', description: 'Uplord content management' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
