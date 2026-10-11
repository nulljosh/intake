import { useDoseLog } from '../hooks/useDoseLog';
import { useSubstances } from '../hooks/useSubstances';
import { exportCsv } from '../utils/exportCsv';

// ponytail: share = one-device summary via Web Share / print-to-PDF; multi-user sharing needs a backend, add when asked
export default function Sharing() {
  const { getEntries, getActive } = useDoseLog();
  const { getById } = useSubstances();
  const name = id => getById(id)?.name || id;

  function summaryText() {
    const stack = [...new Set(getActive().map(e => name(e.substanceId)))];
    const recent = getEntries().slice(0, 20).map(e => `${new Date(e.timestamp).toLocaleDateString('en-CA')} ${name(e.substanceId)} ${e.dose}${e.unit}`);
    return `Intake summary\n\nActive stack: ${stack.join(', ') || 'none'}\n\nRecent doses:\n${recent.join('\n') || 'none'}`;
  }

  async function share() {
    const text = summaryText();
    if (navigator.share) { try { await navigator.share({ title: 'Intake summary', text }); } catch { /* cancelled */ } }
    else if (navigator.clipboard) await navigator.clipboard.writeText(text);
  }

  return (
    <main className="page">
      <h1 className="page-title">Sharing</h1>
      <p style={{ color: 'var(--text-secondary)', marginBottom: 20 }}>Send a summary to your doctor or pharmacist. Nothing is shared until you tap.</p>
      <button className="btn-primary" onClick={share} style={{ marginBottom: 12 }}>Share summary</button>
      <button className="btn-primary" onClick={() => window.print()} style={{ marginBottom: 12 }}>Print or save as PDF</button>
      <button className="btn-primary" onClick={() => exportCsv(getEntries(), getById)}>Export CSV</button>
      <pre className="print-only" style={{ whiteSpace: 'pre-wrap' }}>{summaryText()}</pre>
    </main>
  );
}
