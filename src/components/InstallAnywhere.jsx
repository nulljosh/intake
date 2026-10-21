// ponytail: self-contained -- its own <style>, no palette guessing. color-mix off
// currentColor means it reads correctly on a light or a dark page without props.
// Shows the one way to get the app on the device you're reading this on; every other platform sits behind "Show more".
const CSS = `
#install-anywhere{padding:5rem 0;border-top:1px solid color-mix(in srgb, currentColor 14%, transparent);}
#install-anywhere .xp-wrap{max-width:680px;margin:0 auto;padding:0 1.5rem;text-align:center;}
#install-anywhere h2{font-size:clamp(1.6rem,3.4vw,2.4rem);margin:0 0 .6rem;letter-spacing:-.02em;}
#install-anywhere .xp-lead{max-width:46ch;margin:0 auto 2rem;opacity:.7;line-height:1.55;}
#install-anywhere .xp-main{display:inline-flex;align-items:center;justify-content:center;min-height:48px;padding:0 1.5rem;border-radius:4px;background:var(--accent,currentColor);color:#fff;font-weight:600;text-decoration:none;}
#install-anywhere .xp-how{margin:.75rem auto 0;max-width:46ch;font-size:.9rem;line-height:1.5;opacity:.7;}
#install-anywhere details{margin-top:2rem;text-align:left;}
#install-anywhere summary{cursor:pointer;width:max-content;margin:0 auto;padding:.5rem 1rem;font-size:.9rem;font-weight:500;color:var(--accent,currentColor);list-style:none;}
#install-anywhere summary::-webkit-details-marker{display:none;}
#install-anywhere summary:focus-visible{outline:3px solid color-mix(in srgb, var(--accent,currentColor) 30%, transparent);outline-offset:2px;}
#install-anywhere .xp-grid{display:grid;gap:1rem;margin-top:1rem;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));}
#install-anywhere .xp-card{border:1px solid color-mix(in srgb, currentColor 14%, transparent);border-radius:4px;padding:1.25rem;display:flex;flex-direction:column;gap:.5rem;}
#install-anywhere .xp-card h3{margin:0;font-size:1rem;letter-spacing:-.01em;}
#install-anywhere .xp-card p{margin:0;font-size:.9rem;line-height:1.5;opacity:.7;flex:1;}
#install-anywhere .xp-card a{font-size:.875rem;font-weight:500;color:var(--accent,currentColor);text-decoration:none;}
#install-anywhere .xp-card a:hover{text-decoration:underline;}
`;

function platforms(name, appUrl, appStoreUrl) {
  return [
    appStoreUrl && { id: 'ios', title: 'iPhone & iPad', href: appStoreUrl, label: 'Get it on the App Store', how: 'A native app, not a wrapped web page.' },
    { id: 'mac', title: 'Mac', href: appUrl, label: 'Open the web app', how: "The native Mac app is in App Review. Until it lands, add the web app to your Dock from Safari's File menu." },
    { id: 'windows', title: 'Windows', href: appUrl, label: `Install ${name}`, how: `Open the web app in Edge or Chrome, then Install ${name} from the address bar. It lands in the Start Menu.` },
    { id: 'android', title: 'Android', href: appUrl, label: `Install ${name}`, how: 'Open the web app in Chrome, then Add to Home screen. Full screen, works offline.' },
    { id: 'linux', title: 'Linux', href: appUrl, label: `Install ${name}`, how: 'Install the web app from Chrome or Chromium and it runs in its own window.' },
    { id: 'web', title: 'Web', href: appUrl, label: 'Open the web app', how: 'Nothing to install. The same app, in any modern browser.' },
  ].filter(Boolean);
}

// The visitor's platform from the user agent; iPadOS reports itself as a Mac, so a touch Mac is an iPad.
export function detectPlatform(ua = navigator.userAgent, touch = navigator.maxTouchPoints > 1) {
  if (/iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && touch)) return 'ios';
  if (/Android/.test(ua)) return 'android';
  if (/Windows/.test(ua)) return 'windows';
  if (/Macintosh/.test(ua)) return 'mac';
  if (/Linux|CrOS/.test(ua)) return 'linux';
  return 'web';
}

export default function InstallAnywhere({ name, appUrl, appStoreUrl }) {
  const all = platforms(name, appUrl, appStoreUrl);
  const id = typeof navigator === 'undefined' ? 'web' : detectPlatform();
  const mine = all.find(p => p.id === id) || all.find(p => p.id === 'web');
  const rest = all.filter(p => p !== mine);
  return (
    <section id="install-anywhere">
      <style>{CSS}</style>
      <div className="xp-wrap">
        <h2>{mine.id === 'web' ? 'Open it in your browser.' : `Get it on your ${mine.title}.`}</h2>
        <p className="xp-lead">{name} runs on every platform. Here is the one you're on.</p>
        <a className="xp-main" href={mine.href}>{mine.label}</a>
        <p className="xp-how">{mine.how}</p>
        <details>
          <summary>Show other platforms</summary>
          <div className="xp-grid">
            {rest.map(p => (
              <div className="xp-card" key={p.id}>
                <h3>{p.title}</h3>
                <p>{p.how}</p>
                <a href={p.href}>{p.label} &rarr;</a>
              </div>
            ))}
          </div>
        </details>
      </div>
    </section>
  );
}
