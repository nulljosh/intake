import { useState, useEffect } from 'react';
import { HashRouter, Routes, Route, Link } from 'react-router-dom';
import { SessionProvider } from './context/SessionContext';
import { AuthProvider, useAuth } from './context/AuthContext';
import Auth from './pages/Auth';
import Landing from './pages/Landing';
import ResetPassword from './pages/ResetPassword';
import Nav from './components/Nav';
import Dashboard from './pages/Dashboard';
import Substances from './pages/Substances';
import SubstanceDetail from './pages/SubstanceDetail';
import Insights from './pages/Insights';
import Biometrics from './pages/Biometrics';
import Body from './pages/Body';
import Bodywork from './pages/Bodywork';
import Feet from './pages/Feet';
import Hands from './pages/Hands';
import Abdomen from './pages/Abdomen';
import Meridians from './pages/Meridians';
import SymptomFinder from './pages/SymptomFinder';
import Sessions from './pages/Sessions';
import Facemaxxing from './pages/Facemaxxing';
import LabResults from './pages/LabResults';
import Routine from './pages/Routine';
import Supplements from './pages/Supplements';
import Profile from './pages/Profile';
import Browse from './pages/Browse';
import Sharing from './pages/Sharing';
import WhatsNew from './components/WhatsNew';
import { WebMCP } from './lib/webmcp';

function ThemeToggle({ theme, setTheme, style }) {
  return (
    <button
      className="theme-toggle"
      style={style}
      onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
      aria-label="Toggle theme"
    >
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        {theme === 'dark' ? (
          <><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></>
        ) : (
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
        )}
      </svg>
    </button>
  );
}

function AppShell({ theme, setTheme }) {
  const { user, loading, isPasswordRecovery } = useAuth();
  // ponytail: signed-out view is a two-state toggle, not a route, no router needed above AuthProvider
  const [showAuth, setShowAuth] = useState(false);

  if (loading) return null;
  if (isPasswordRecovery) return <ResetPassword />;
  if (!user) return showAuth ? <Auth /> : <Landing onGetStarted={() => setShowAuth(true)} toggle={<ThemeToggle theme={theme} setTheme={setTheme} style={{ position: 'static' }} />} />;

  return (
    <SessionProvider>
      <main style={{ minHeight: '100dvh' }}>
        <ThemeToggle theme={theme} setTheme={setTheme} />
        <Link to="/profile" className="theme-toggle profile-link" aria-label="Profile">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
        </Link>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/browse" element={<Browse />} />
          <Route path="/sharing" element={<Sharing />} />
          <Route path="/substances" element={<Substances />} />
          <Route path="/substances/:id" element={<SubstanceDetail />} />
          <Route path="/interactions" element={<Substances key="interactions" defaultTab="interactions" />} />
          <Route path="/insights" element={<Insights />} />
          <Route path="/body" element={<Body />} />
          <Route path="/biometrics" element={<Biometrics />} />
          <Route path="/health" element={<Biometrics key="health" defaultTab="health" />} />
          <Route path="/bodywork" element={<Bodywork />} />
          <Route path="/feet" element={<Feet />} />
          <Route path="/hands" element={<Hands />} />
          <Route path="/abdomen" element={<Abdomen />} />
          <Route path="/meridians" element={<Meridians />} />
          <Route path="/symptom-finder" element={<SymptomFinder />} />
          <Route path="/sessions" element={<Sessions />} />
          <Route path="/facemaxxing" element={<Facemaxxing />} />
          <Route path="/routine" element={<Routine />} />
          <Route path="/supplements" element={<Supplements />} />
          <Route path="/lab-results" element={<LabResults />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="*" element={<Dashboard />} />
        </Routes>
        <Nav />
        <WhatsNew />
        <WebMCP />
      </main>
    </SessionProvider>
  );
}

export default function App() {
  const [theme, setTheme] = useState(
    () => localStorage.getItem('dose:theme') || (matchMedia('(prefers-color-scheme:dark)').matches ? 'dark' : 'light')
  );

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('dose:theme', theme);
  }, [theme]);

  useEffect(() => {
    const mq = matchMedia('(prefers-color-scheme:dark)');
    const handler = (e) => setTheme(e.matches ? 'dark' : 'light');
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);

  return (
    <HashRouter>
      <AuthProvider>
        <AppShell theme={theme} setTheme={setTheme} />
      </AuthProvider>
    </HashRouter>
  );
}
