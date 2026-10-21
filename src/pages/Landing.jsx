import { useEffect, useRef } from 'react';
import InstallAnywhere from '../components/InstallAnywhere';
import FooterBand from '../components/FooterBand';
import './landing.css';

const APP_STORE = 'https://apps.apple.com/app/id6785764864';

const ROWS = [
  { shot: 'home', label: 'Home', title: 'Your day on one screen', body: 'A health score, anything your labs flagged, your active stack and what you took today.' },
  { shot: 'library', label: 'Library', title: '200 substances, explained', body: 'Dosing ranges, timing and harm reduction notes for every entry, sorted by kind.' },
  { shot: 'insights', label: 'Insights', title: 'See what actually works', body: 'A heatmap of when you dose, what you use most, and a tolerance tracker for anything you take often.' },
];

const CELLS = [
  { label: 'Log', title: 'Log doses as you go', body: 'Record what you take as you take it and keep a running stack of everything active.' },
  { label: 'Interactions', title: 'Check before you take it', body: 'Pick two or more substances and see how they mix, before the dose, not after.' },
  { label: 'Labs', title: 'Your bloodwork, flagged', body: 'Add a lab panel and anything out of range shows up on your home screen.' },
];

// Adds .js to the page, then fades each .reveal in as it scrolls into view (Hermes' landing.js, in React).
function useReveal(rootRef) {
  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;
    root.classList.add('js');
    const items = root.querySelectorAll('.reveal');
    if (!('IntersectionObserver' in window)) { items.forEach(el => el.classList.add('in')); return; }
    const io = new IntersectionObserver(entries => entries.forEach(e => {
      if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
    }), { threshold: 0.15 });
    items.forEach(el => io.observe(el));
    return () => io.disconnect();
  }, [rootRef]);
}

// Art, dithered to halftone: Sebastiano Ricci, The Dream of Aesculapius (public domain); Rijksmuseum engravings of
// Aesculapius reviving Hippolytus, a bust of Asklepios and a sculpture plate (CC0); a statue of Asclepius (CC0).
// All via Wikimedia Commons. Every image is used once.
export default function Landing({ onGetStarted, toggle }) {
  const root = useRef(null);
  useReveal(root);

  return (
    <div className="hl" ref={root}>
      <header className="nav" aria-label="Site">
        <nav className="nav-links" aria-label="Main">
          <a href="#features">Features</a>
          <a href="#get">Platforms</a>
        </nav>
        <a className="nav-brand" href="#top" aria-label="Intake home"><img src="/icon.svg" alt="" width="28" height="28" /><span>Intake</span></a>
        <div className="nav-end">
          {toggle}
          <button className="btn btn-solid" onClick={onGetStarted}>Get started</button>
        </div>
      </header>

      <main id="top">
        <section className="hero">
          <div className="wrap center">
            <p className="label">Supplements, medications and symptoms</p>
            <h1>Intake</h1>
            <p className="lead">Track what you take, and what it does. A private log with an interaction check before every dose.</p>
            <div className="cta">
              <button className="btn btn-solid" onClick={onGetStarted}>Start tracking</button>
              <a className="btn btn-ghost" href="#features">See what it does</a>
            </div>
            <p className="fine">Free on the web. iPhone and iPad on the App Store.</p>
          </div>

          <div className="demo-wrap reveal">
            <div className="stage">
              <div className="art stage-art" style={{ '--img': 'url(/art/hippolytus.png)' }} aria-hidden="true" />
              <div className="shots">
                <img src="/screenshots/ios-home.png" alt="Intake home screen" />
                <img src="/screenshots/ios-insights.png" alt="Intake insights screen" />
              </div>
            </div>
            <p className="demo-hint">Real screens from the app.</p>
          </div>
        </section>

        <section className="band" id="features">
          <div className="band-head">
            <div className="art band-art" style={{ '--img': 'url(/art/ricci.png)' }} aria-hidden="true" />
            <div className="band-copy reveal">
              <p className="label">The doctor in your pocket</p>
              <h2>Know what works</h2>
              <p>Most trackers stop at a list. Intake shows what each dose did.</p>
            </div>
          </div>
          <div className="frows">
            {ROWS.map(r => (
              <article className="frow reveal" key={r.shot}>
                <div className="art"><img className="shot" src={`/screenshots/ios-${r.shot}.png`} alt={`${r.title} screen`} /></div>
                <div><p className="label">{r.label}</p><h3>{r.title}</h3><p>{r.body}</p></div>
              </article>
            ))}
          </div>
          <div className="cells">
            {CELLS.map(c => (
              <article className="cell reveal" key={c.label}><p className="label">{c.label}</p><h3>{c.title}</h3><p>{c.body}</p></article>
            ))}
          </div>
        </section>

        <section className="sec plats" id="get">
          <div className="wrap center">
            <i className="wing reveal" aria-hidden="true" />
            <p className="label reveal">Available now</p>
            <h2 className="reveal">Everywhere</h2>
            <p className="body reveal">One account. Your log follows you between the web and your phone.</p>
            <div className="prods">
              <article className="prod reveal">
                <div className="art prod-art" style={{ '--img': 'url(/art/bust.png)' }} aria-hidden="true" />
                <p className="label">Web</p><h3>intake.jaybulb.com</h3><p>Runs in any browser. Installs like an app.</p>
                <button className="btn btn-solid" onClick={onGetStarted}>Open the web app</button>
              </article>
              <article className="prod reveal">
                <div className="art prod-art" style={{ '--img': 'url(/art/statue.png)' }} aria-hidden="true" />
                <p className="label">iOS 17 and up</p><h3>iPhone and iPad</h3><p>A native app with Health, widgets and Face ID.</p>
                <a href={APP_STORE}>App Store &rarr;</a>
              </article>
              <article className="prod reveal">
                <div className="art prod-art" style={{ '--img': 'url(/art/plate.png)' }} aria-hidden="true" />
                <p className="label">Open source</p><h3>Apache 2.0</h3><p>Read every line, or run your own copy.</p>
                <a href="https://github.com/nulljosh/intake">GitHub &rarr;</a>
              </article>
            </div>
          </div>
        </section>

        <InstallAnywhere name="Intake" appUrl="https://intake.jaybulb.com" appStoreUrl={APP_STORE} />
      </main>

      <footer className="foot">
        <div className="foot-top">
          <div className="foot-brand"><img src="/icon.svg" alt="" width="40" height="40" /><b>Intake</b><p>Track what you take, and what it does.</p></div>
          <nav className="foot-cols" aria-label="Footer">
            <div><p className="label">Intake</p><a href={APP_STORE}>App Store</a><a href="#features">Features</a><a href="#install-anywhere">Install anywhere</a><a href="https://github.com/nulljosh/intake/blob/main/WHITEPAPER.md">Whitepaper</a></div>
            <div><p className="label">Source</p><a href="https://github.com/nulljosh/intake">GitHub</a><a href="https://github.com/nulljosh/intake/blob/main/docs/API.md">API</a><a href="https://github.com/nulljosh/intake/blob/main/docs/ARCHITECTURE.md">Architecture</a><a href="https://github.com/nulljosh/intake/blob/main/SECURITY.md">Security</a></div>
            <div><p className="label">More</p><a href="/privacy.html">Privacy</a><a href="/tos.html">Terms</a><a href="https://jaybulb.com">More apps</a><a href="#top">Back to top</a></div>
          </nav>
        </div>
        <FooterBand />
        <p className="legal">&copy; 2026 Joshua Trommel &middot; Apache 2.0{typeof __APP_VERSION__ !== 'undefined' ? ` · v${__APP_VERSION__}` : ''} &middot; <a href="/privacy.html">Privacy</a></p>
      </footer>
    </div>
  );
}
