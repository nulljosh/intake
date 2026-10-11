import { useEffect, useRef, useState } from 'react';
import InstallAnywhere from '../components/InstallAnywhere';

const prefersReducedMotion = () =>
  typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

// Reveals a section once it scrolls into view (skipped, always-visible, under
// reduced motion). No new deps: useRef + IntersectionObserver.
function useRevealOnScroll() {
  const ref = useRef(null);
  const [inView, setInView] = useState(prefersReducedMotion());

  useEffect(() => {
    if (prefersReducedMotion() || !ref.current || !('IntersectionObserver' in window)) return;
    const io = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setInView(true);
          io.unobserve(entry.target);
        }
      },
      { threshold: 0.15 }
    );
    io.observe(ref.current);
    return () => io.disconnect();
  }, []);

  return [ref, inView];
}
// Health marks: the app icon's capsule plus the other things a stack tracks.
const S = { fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' };
const MARKS = [
  // capsule on the diagonal, top half filled (matches icon.svg)
  <g transform="rotate(45 12 12)"><rect x="7" y="2" width="10" height="20" rx="5" {...S} /><rect x="7" y="2" width="10" height="10" rx="5" fill="currentColor" /></g>,
  // round tablet, scored
  <g {...S}><circle cx="12" cy="12" r="9" /><path d="M5 12h14" /></g>,
  // droplet
  <path d="M12 3s6 6.5 6 10.5a6 6 0 0 1-12 0C6 9.5 12 3 12 3z" {...S} />,
  // pulse line
  <path d="M2 12h4l3-7 4 14 3-7h6" {...S} />,
  // heart
  <path d="M12 20s-7-4.6-7-9.5A3.9 3.9 0 0 1 12 8a3.9 3.9 0 0 1 7 2.5C19 15.4 12 20 12 20z" {...S} />,
  // leaf
  <g {...S}><path d="M20 4C10 4 4 9 4 16v4" /><path d="M20 4c0 9-5 13-11 13H4" /></g>,
  // flask
  <g {...S}><path d="M10 3v6L4 19a2 2 0 0 0 1.7 3h12.6A2 2 0 0 0 20 19l-6-10V3" /><path d="M9 3h6" /><path d="M7.5 14h9" /></g>,
  // calendar tick
  <g {...S}><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M8 3v4M16 3v4M8 14l3 3 5-5" /></g>,
];

const Mark = ({ i, size = 34 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden="true">
    {MARKS[i % MARKS.length]}
  </svg>
);

// 8 columns of health marks, alternating drift direction; each column's list is
// doubled so the translateY(-50%) loop is seamless. The prime-ish stride keeps
// neighbouring columns from lining up on the same glyph.
const HeroWall = ({ wallRef }) => (
  <div className="hero-wall" aria-hidden="true" ref={wallRef}>
    {Array.from({ length: 8 }, (_, c) => {
      const marks = Array.from({ length: 7 }, (_, i) => <Mark key={i} i={c * 3 + i} />);
      return (
        <div key={c} className={'wall-col ' + (c % 2 ? 'down' : 'up')} style={{ '--dur': (46 + c * 9) + 's' }}>
          {marks}{marks}
        </div>
      );
    })}
  </div>
);

const SECTION_PAD = 'clamp(3rem, 8vw, 5rem) clamp(1.25rem, 4vw, 1.5rem)';

const FEATURES = [
  {
    title: 'Log doses in real-time',
    body: 'Record what you take as you take it and keep a running stack of everything currently active.',
    icon: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12 5v14M5 12h14"/>
        <rect x="4" y="4" width="16" height="16" rx="2"/>
      </svg>
    ),
  },
  {
    title: 'Catch interactions',
    body: 'Get warned before logging something that clashes with your active stack or history.',
    icon: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
      </svg>
    ),
  },
  {
    title: 'Track trends over time',
    body: 'Symptoms, biometrics, and labs plotted over time show real patterns instead of guesses.',
    icon: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/>
      </svg>
    ),
  },
  {
    title: 'Reference built-in',
    body: 'Look up dosing ranges, timing, and harm reduction notes for any substance in your library.',
    icon: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M4 19.5h16M6 12.5h12M6 5.5h12"/>
      </svg>
    ),
  },
];

const SHOWCASE = [
  { shot: 'summary', kicker: 'Summary', title: 'Your day on one screen.', body: 'Pin the numbers you care about. Heart rate, sleep, steps. Your active stack sits right under them.', alt: 'Summary screen with pinned heart rate, sleep and steps' },
  { shot: 'interactions', kicker: 'Interactions', title: 'Check before you take it.', body: 'Pick two or more substances and see how they mix. You get the warning before the dose, not after.', alt: 'Interaction checker' },
  { shot: 'insights', kicker: 'Insights', title: 'See what actually works.', body: 'A heatmap of when you dose, what you use most, and how your body numbers move on the days you take it.', alt: 'Insights screen with usage heatmap' },
  { shot: 'library', kicker: 'Library', title: '200 substances, explained.', body: 'Dosing ranges, timing and harm reduction notes for every entry. Search it like a reference book.', alt: 'Substance library' },
  { shot: 'sharing', kicker: 'Sharing', title: 'Hand it to your doctor.', body: 'Send a summary, print it, or export the whole log. Nothing leaves your device until you tap.', alt: 'Sharing screen' },
];

export default function Landing({ onGetStarted }) {
  const wallRef = useRef(null);
  const [featuresRef, featuresIn] = useRevealOnScroll();
  const [platformsRef, platformsIn] = useRevealOnScroll();

  // Parallax: the hero wall of health marks drifts slower than the page scrolls.
  useEffect(() => {
    if (prefersReducedMotion() || !wallRef.current) return;
    let ticking = false;
    const onScroll = () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        if (wallRef.current) wallRef.current.style.transform = `translateY(${window.scrollY * 0.1}px)`;
        ticking = false;
      });
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <main id="top" style={{ minHeight: '100dvh', background: 'var(--bg)', color: 'var(--text-primary)', overflowX: 'hidden' }}>
      <style>{`
        .reveal { opacity: 0; transform: translateY(20px); transition: opacity .6s ease, transform .6s ease; }
        .reveal.in-view { opacity: 1; transform: none; }
        @media (prefers-reduced-motion: reduce) {
          .reveal { opacity: 1; transform: none; transition: none; }
        }
      `}</style>
      {/* Header */}
      <header style={{
        position: 'sticky',
        top: 0,
        zIndex: 100,
        background: 'var(--glass-bg)',
        backdropFilter: 'blur(20px) saturate(180%)',
        borderBottom: '1px solid var(--border)',
      }}>
        <div style={{ maxWidth: 1080, margin: '0 auto', padding: '0.9rem clamp(1.25rem, 4vw, 1.5rem)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', fontSize: '1.05rem', fontWeight: 700, letterSpacing: '-0.01em' }}>
            <img src="/icon.svg" alt="" width="32" height="32" style={{ flexShrink: 0 }} />
            Intake
          </div>
          <button
            onClick={onGetStarted}
            style={{
              background: 'var(--text-primary)', color: 'var(--bg)', fontSize: '0.875rem', fontWeight: 500,
              padding: '0.55rem 1.25rem', borderRadius: 999, border: 'none', cursor: 'pointer',
            }}
          >
            Get started
          </button>
        </div>
      </header>

      {/* Hero */}
      <section style={{ position: 'relative', isolation: 'isolate', overflow: 'hidden', maxWidth: 1080, margin: '0 auto', padding: 'clamp(3rem, 8vw, 5rem) clamp(1.25rem, 4vw, 1.5rem) 4rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 300px), 1fr))', gap: 'clamp(2rem, 5vw, 3rem)', alignItems: 'center' }}>
        <HeroWall wallRef={wallRef} />
        <div className="hero-scrim" />
        <div style={{ position: 'relative', zIndex: 2 }}>
          <div style={{ fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.12em', color: 'var(--text-secondary)', marginBottom: '0.75rem' }}>Health tracking</div>
          <h1 style={{ fontSize: 'clamp(2.125rem, 5.5vw, 4.25rem)', lineHeight: 1.05, margin: '0 0 1.25rem', fontWeight: 600, letterSpacing: '-0.01em' }}>
            Track what you take, and what it does.
          </h1>
          <p style={{ fontSize: '1.125rem', lineHeight: 1.6, color: 'var(--text-secondary)', maxWidth: 460, margin: '0 0 2rem' }}>
            A private tracker for supplements, medications, and symptoms. Log doses in real-time, check interactions before taking something, and watch trends over time.
          </p>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', flexWrap: 'wrap', marginBottom: '1.75rem' }}>
            <button
              onClick={onGetStarted}
              style={{
                textDecoration: 'none', fontSize: '0.9375rem', fontWeight: 500, padding: '0.875rem 1.75rem',
                borderRadius: 999, display: 'inline-block', cursor: 'pointer', border: 'none',
                background: 'var(--text-primary)', color: 'var(--bg)', transition: 'transform 0.2s',
              }}
            >
              Start tracking →
            </button>
            <button
              onClick={onGetStarted}
              style={{
                textDecoration: 'none', fontSize: '0.9375rem', fontWeight: 500, padding: '0.875rem 1.75rem',
                borderRadius: 999, display: 'inline-block', cursor: 'pointer',
                color: 'var(--text-primary)', border: '1px solid var(--border)', background: 'transparent',
              }}
            >
              Sign in
            </button>
          </div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: '0.6rem', padding: '0.5rem 0.9rem', borderRadius: 999, background: 'var(--bg-secondary)', border: '1px solid var(--border)', fontSize: '0.8125rem', color: 'var(--text-secondary)' }}>
            <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--success)', flexShrink: 0 }} />
            Web + iOS app · private
          </div>
        </div>
        <div style={{ position: 'relative', zIndex: 2, display: 'flex', justifyContent: 'center', minWidth: 0 }}>
          <div style={{ display: 'flex', gap: 'clamp(0.5rem, 2vw, 1rem)', width: '100%', maxWidth: 376, justifyContent: 'center' }}>
            <img
              src="/screenshots/web-summary.png"
              alt="Intake dashboard"
              style={{ width: '100%', maxWidth: 180, minWidth: 0, height: 'auto', borderRadius: 28, border: '1px solid var(--border)' }}
            />
            <img
              src="/screenshots/web-insights.png"
              alt="Intake insights"
              style={{ width: '100%', maxWidth: 180, minWidth: 0, height: 'auto', borderRadius: 28, border: '1px solid var(--border)', transform: 'translateY(20px)' }}
            />
          </div>
        </div>
      </section>

      {/* Features */}
      <section
        ref={featuresRef}
        className={`reveal${featuresIn ? ' in-view' : ''}`}
        style={{ maxWidth: 1080, margin: '0 auto', padding: SECTION_PAD }}
      >
        <div style={{ maxWidth: 480, margin: '0 auto 3rem', textAlign: 'center' }}>
          <div style={{ fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.12em', color: 'var(--text-secondary)', marginBottom: '0.75rem' }}>Core features</div>
          <h2 style={{ fontSize: 'clamp(1.625rem, 4vw, 2rem)', fontWeight: 600, margin: 0, letterSpacing: '-0.01em' }}>Everything you need to track smart</h2>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 240px), 1fr))', gap: '1.25rem' }}>
          {FEATURES.map(f => (
            <div key={f.title} style={{ padding: '1.5rem', background: 'var(--bg-secondary)', border: '1px solid var(--border)', borderRadius: 14 }}>
              <div style={{ width: 44, height: 44, borderRadius: 12, background: 'var(--accent-muted)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '1rem', color: 'var(--accent)' }}>
                {f.icon}
              </div>
              <div style={{ fontWeight: 600, fontSize: '1.0625rem', letterSpacing: '-0.01em', marginBottom: '0.5rem' }}>{f.title}</div>
              <div style={{ fontSize: '0.875rem', lineHeight: 1.55, color: 'var(--text-secondary)' }}>{f.body}</div>
            </div>
          ))}
        </div>
      </section>

      {/* Showcase: one real screen per feature */}
      <section style={{ maxWidth: 960, margin: '0 auto', padding: SECTION_PAD }}>
        {SHOWCASE.map((f, i) => (
          <div key={f.shot} className="showcase-row" style={{ display: 'flex', flexWrap: 'wrap', flexDirection: i % 2 ? 'row-reverse' : 'row', alignItems: 'center', justifyContent: 'center', gap: 'clamp(1.5rem, 6vw, 4rem)', marginBottom: 'clamp(3rem, 8vw, 5rem)' }}>
            <img src={`/screenshots/web-${f.shot}.png`} alt={f.alt} loading="lazy" width="260" height="563" style={{ width: 260, maxWidth: '70vw', height: 'auto', borderRadius: 32, border: '1px solid var(--border)' }} />
            <div style={{ flex: '1 1 280px', maxWidth: 400 }}>
              <div style={{ fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.12em', color: 'var(--accent)', marginBottom: '0.75rem' }}>{f.kicker}</div>
              <h2 style={{ fontSize: 'clamp(1.5rem, 4vw, 2rem)', fontWeight: 600, margin: '0 0 0.75rem', letterSpacing: '-0.02em', lineHeight: 1.15 }}>{f.title}</h2>
              <p style={{ fontSize: '1rem', lineHeight: 1.6, color: 'var(--text-secondary)', margin: 0 }}>{f.body}</p>
            </div>
          </div>
        ))}
      </section>

      {/* Platforms */}
      <section
        ref={platformsRef}
        className={`reveal${platformsIn ? ' in-view' : ''}`}
        style={{ maxWidth: 1080, margin: '0 auto', padding: SECTION_PAD }}
      >
        <div style={{ maxWidth: 480, margin: '0 auto 3rem', textAlign: 'center' }}>
          <div style={{ fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.12em', color: 'var(--text-secondary)', marginBottom: '0.75rem' }}>Available now</div>
          <h2 style={{ fontSize: 'clamp(1.625rem, 4vw, 2rem)', fontWeight: 600, margin: 0, letterSpacing: '-0.01em' }}>Use it everywhere</h2>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 200px), 1fr))', gap: '1.25rem' }}>
          {[
            { name: 'Web', status: 'Live', detail: 'intake.jaybulb.com', live: true },
            { name: 'iOS', status: 'Live', detail: 'On the App Store, iOS 17 and up', live: true },
          ].map(p => (
            <div key={p.name} style={{ padding: '1.5rem', background: 'var(--bg-secondary)', border: '1px solid var(--border)', borderRadius: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '0.75rem', marginBottom: '0.75rem' }}>
                <div style={{ fontWeight: 600, fontSize: '1.0625rem', letterSpacing: '-0.01em' }}>{p.name}</div>
                <div style={{ padding: '0.15rem 0.5rem', borderRadius: 999, fontSize: '0.6875rem', fontWeight: 700, whiteSpace: 'nowrap', background: p.live ? 'var(--success-muted)' : 'var(--bg-tertiary)', color: p.live ? 'var(--success)' : 'var(--text-secondary)' }}>
                  {p.status}
                </div>
              </div>
              <div style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', overflowWrap: 'anywhere' }}>{p.detail}</div>
            </div>
          ))}
        </div>
      </section>

      <InstallAnywhere name="Intake" appUrl="https://intake.jaybulb.com" appStoreUrl="https://apps.apple.com/app/id6785764864" />

      {/* Footer */}
      <footer className="lp-foot">
  <div className="foot-rule" aria-hidden="true"><span>Intake</span><span>Track what works</span></div>
  <nav className="foot-dir" aria-label="Footer">
    <div className="foot-col">
      <h3>Intake</h3>
      <ul>
        <li><a href="https://apps.apple.com/app/id6785764864">App Store</a></li>
        <li><a href="/">Open the web app</a></li>
        <li><a href="https://github.com/nulljosh/intake/blob/main/WHITEPAPER.md">Whitepaper</a></li>
      </ul>
    </div>
    <div className="foot-col">
      <h3>Explore</h3>
      <ul>
        <li><a href="#install-anywhere">Install anywhere</a></li>
        <li><a href="https://jaybulb.com/docs.html#healstack">Docs</a></li>
      </ul>
    </div>
    <div className="foot-col">
      <h3>Developers</h3>
      <ul>
        <li><a href="https://github.com/nulljosh/intake">Source</a></li>
        <li><a href="https://github.com/nulljosh/intake/blob/main/docs/API.md">API reference</a></li>
        <li><a href="https://github.com/nulljosh/intake/blob/main/docs/ARCHITECTURE.md">Architecture</a></li>
        <li><a href="https://github.com/nulljosh/intake/issues">Report a bug</a></li>
        <li><a href="https://github.com/nulljosh/intake/blob/main/CONTRIBUTING.md">Contributing</a></li>
      </ul>
    </div>
    <div className="foot-col">
      <h3>Project</h3>
      <ul>
        <li><a href="/privacy.html">Privacy</a></li>
        <li><a href="/tos.html">Terms</a></li>
        <li><a href="https://github.com/nulljosh/intake/blob/main/SECURITY.md">Security</a></li>
        <li><a href="https://github.com/nulljosh/intake/blob/main/LICENSE">License (MIT)</a></li>
        <li><a href="https://jaybulb.com">Portfolio</a></li>
        <li><a href="#top">Back to top</a></li>
      </ul>
    </div>
  </nav>
  <div className="foot-bar">
    <p className="foot-meta">Intake{typeof __APP_VERSION__ !== 'undefined' ? ` v${__APP_VERSION__}` : ''} · MIT License · © 2026 Joshua Trommel · Made with <span aria-hidden="true">♥</span> in Vancouver, BC</p>
  </div>
</footer>
    </main>
  );
}
