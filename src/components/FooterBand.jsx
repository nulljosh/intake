import { useEffect, useRef } from 'react';

// Footer band: Asclepius' things in a row (the stethoscope mark, his rod and snake, Hygieia's bowl, a capsule, a heart,
// a mortar and pestle), cut like a line engraving in plain 2D canvas, after Hermes' footer-band.js. Faint rules run
// across the band; inside the glyphs they thicken, and thicken again on the edge facing away from the light, so the
// glyphs look cut into the page. Drawn once per width and theme.

const GLYPHS = [
  (c, mark) => { // the stethoscope: the brand mark itself
    if (mark.complete && mark.naturalWidth) c.drawImage(mark, -6, -6, 112, 112);
  },
  (c) => { // the rod of Asclepius: a knotted staff, one snake climbing it in wide loops
    c.fillRect(46, 12, 8, 82); c.beginPath(); c.arc(50, 12, 7, 0, 7); c.fill();
    c.lineWidth = 9; c.lineCap = 'round'; c.beginPath();
    for (let t = 0; t <= 1.001; t += 0.02) { const y = 88 - t * 58, x = 50 + 26 * Math.sin(t * Math.PI * 2.5 + Math.PI); t ? c.lineTo(x, y) : c.moveTo(x, y); }
    c.stroke(); c.beginPath(); c.ellipse(80, 27, 9, 6, -0.3, 0, 7); c.fill();
  },
  (c) => { // the bowl of Hygieia
    c.beginPath(); c.arc(50, 42, 28, 0, Math.PI); c.fill();
    c.fillRect(20, 38, 60, 7); c.fillRect(46, 68, 8, 16);
    c.beginPath(); c.ellipse(50, 88, 20, 6, 0, 0, 7); c.fill();
    c.lineWidth = 6; c.lineCap = 'round'; c.beginPath(); c.moveTo(28, 80); c.quadraticCurveTo(84, 70, 64, 30); c.quadraticCurveTo(58, 16, 46, 22); c.stroke();
  },
  (c) => { // a capsule, scored across the middle
    c.save(); c.translate(50, 50); c.rotate(-Math.PI / 4);
    c.beginPath(); c.roundRect(-16, -40, 32, 80, 16); c.fill();
    c.globalCompositeOperation = 'destination-out'; c.fillRect(-18, -2.5, 36, 5);
    c.restore();
  },
  (c) => { // a heart
    c.beginPath(); c.moveTo(50, 86);
    c.bezierCurveTo(12, 60, 12, 20, 34, 20); c.bezierCurveTo(44, 20, 50, 28, 50, 36);
    c.bezierCurveTo(50, 28, 56, 20, 66, 20); c.bezierCurveTo(88, 20, 88, 60, 50, 86); c.fill();
  },
  (c) => { // a mortar and pestle
    c.lineWidth = 11; c.lineCap = 'round'; c.beginPath(); c.moveTo(56, 52); c.lineTo(80, 14); c.stroke();
    c.beginPath(); c.moveTo(16, 50); c.lineTo(84, 50); c.quadraticCurveTo(82, 86, 50, 88); c.quadraticCurveTo(18, 86, 16, 50); c.fill();
    c.fillRect(36, 88, 28, 6);
  },
];

// One row, or two on a narrow band.
function grid(w, h) {
  const n = GLYPHS.length, rows = w < h * 3 ? 2 : 1, per = Math.ceil(n / rows);
  return { rows, per, cell: Math.min((h / rows) * 0.86, (w / per) * 0.8) };
}

function layer(w, h) { const c = document.createElement('canvas'); c.width = w; c.height = h; return c; }

// Horizontal rules `t` px thick, one every `pitch` px, kept only where `mask` is drawn (everywhere when null).
function rules(w, h, pitch, t, colour, mask) {
  const c = layer(w, h), x = c.getContext('2d');
  x.fillStyle = colour;
  for (let y = 0; y < h; y += pitch) x.fillRect(0, Math.round(y + (pitch - t) / 2), w, Math.max(1, Math.round(t)));
  if (mask) { x.globalCompositeOperation = 'destination-in'; x.drawImage(mask, 0, 0); }
  return c;
}

export default function FooterBand() {
  const bandRef = useRef(null), canvasRef = useRef(null);

  useEffect(() => {
    const band = bandRef.current, canvas = canvasRef.current, ctx = canvas?.getContext('2d');
    if (!ctx) return;
    const mark = new Image();
    mark.src = '/brand-mark.svg'; // only its shape is used: the glyph layer is a mask
    let drawnW = 0;

    const draw = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2), w = Math.round(canvas.clientWidth * dpr), h = Math.round(canvas.clientHeight * dpr);
      if (!w || !h) return;
      drawnW = w; canvas.width = w; canvas.height = h;
      const colour = getComputedStyle(band).color, g = grid(w, h);
      const pitch = Math.min(5 * dpr, Math.max(3 * dpr, g.cell / 22)), s = Math.max(2, h * 0.014);
      const glyphs = layer(w, h), gc = glyphs.getContext('2d'), gap = (w - g.cell * g.per) / g.per, rowH = h / g.rows;
      GLYPHS.forEach((paint, i) => {
        const col = i % g.per, row = Math.floor(i / g.per);
        gc.save(); gc.translate(gap / 2 + col * (g.cell + gap), row * rowH + (rowH - g.cell) / 2); gc.scale(g.cell / 100, g.cell / 100);
        gc.fillStyle = gc.strokeStyle = '#fff'; paint(gc, mark); gc.restore();
      });
      // the shadow side: glyph pixels whose neighbour down and right is outside the glyph (light from the top left)
      const shade = layer(w, h), sc = shade.getContext('2d');
      sc.drawImage(glyphs, 0, 0); sc.globalCompositeOperation = 'destination-out'; sc.drawImage(glyphs, -s, -s);
      ctx.globalAlpha = 0.28; ctx.drawImage(rules(w, h, pitch, dpr * 0.75, colour, null), 0, 0);
      ctx.globalAlpha = 1; ctx.drawImage(rules(w, h, pitch, pitch * 0.32, colour, glyphs), 0, 0);
      ctx.drawImage(rules(w, h, pitch, pitch * 0.6, colour, shade), 0, 0);
    };

    band.classList.add('live');
    draw();
    mark.addEventListener('load', draw);
    // iOS fires resize as the toolbar slides; only a width change needs a redraw
    const onResize = () => { if (Math.round(canvas.clientWidth * Math.min(window.devicePixelRatio || 1, 2)) !== drawnW) draw(); };
    window.addEventListener('resize', onResize);
    const scheme = matchMedia('(prefers-color-scheme: dark)');
    scheme.addEventListener('change', draw);
    const themeWatch = new MutationObserver(draw); // the app's own theme toggle sets data-theme
    themeWatch.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
    return () => { window.removeEventListener('resize', onResize); scheme.removeEventListener('change', draw); themeWatch.disconnect(); };
  }, []);

  return <div className="word-band" aria-hidden="true" ref={bandRef}><canvas className="word-canvas" ref={canvasRef} /></div>;
}
