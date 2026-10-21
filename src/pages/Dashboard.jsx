import { useState, useMemo } from 'react';
import { useDoseLog } from '../hooks/useDoseLog';
import { useSubstances } from '../hooks/useSubstances';
import { useBiometrics } from '../hooks/useBiometrics';
import { useLabResults } from '../hooks/useLabResults';
import PinnedCards from '../components/PinnedCards';
import LogEntry from '../components/LogEntry';
import AddEntryModal from '../components/AddEntryModal';
import { CATEGORY_COLORS } from '../constants/colors';
import { topInsights, insightText } from '../utils/insightEngine';

function HealthRing({ score }) {
  if (score == null) return null;
  const r = 22;
  const circ = 2 * Math.PI * r;
  const pct = Math.min(100, Math.max(0, score));
  const fill = pct >= 80 ? '#26a641' : pct >= 50 ? '#f59e0b' : '#ef4444';
  return (
    <svg width="56" height="56" viewBox="0 0 56 56" style={{ flexShrink: 0 }}>
      <circle cx="28" cy="28" r={r} fill="none" stroke="var(--border)" strokeWidth="4" />
      <circle
        cx="28" cy="28" r={r} fill="none"
        stroke={fill} strokeWidth="4"
        strokeDasharray={circ}
        strokeDashoffset={circ * (1 - pct / 100)}
        strokeLinecap="round"
        transform="rotate(-90 28 28)"
        style={{ transition: 'stroke-dashoffset 0.6s ease' }}
      />
      <text x="28" y="33" textAnchor="middle" fontSize="12" fontWeight="700"
        fill="var(--text-primary)" fontFamily="inherit">
        {Math.round(pct)}
      </text>
    </svg>
  );
}

function InsightCard({ insight, getName }) {
  const text = insightText(insight, getName);
  if (!text) return null;

  const iconMap = {
    lab_flag: (
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" y1="22" x2="4" y2="15"/>
      </svg>
    ),
    anomaly: (
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
      </svg>
    ),
    lab_trend: (
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/><polyline points="17 6 23 6 23 12"/>
      </svg>
    ),
    correlation: (
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
      </svg>
    ),
  };

  const urgent = insight.type === 'lab_flag' || insight.flag === 'critical';
  const color = urgent ? 'var(--danger)' : insight.type === 'anomaly' ? 'var(--warning)' : 'var(--accent)';
  const bg = urgent ? 'var(--danger-muted)' : insight.type === 'anomaly' ? 'var(--warning-muted)' : 'var(--accent-muted)';

  return (
    <div style={{
      display: 'flex', gap: 12, alignItems: 'flex-start',
      padding: '12px 14px', borderRadius: 10,
      background: bg, border: `1px solid ${color}22`,
      marginBottom: 8,
    }}>
      <span style={{ color, flexShrink: 0, marginTop: 1 }}>{iconMap[insight.type]}</span>
      <span style={{ fontSize: '0.85rem', lineHeight: 1.5, color: 'var(--text-primary)' }}>{text[0].toUpperCase() + text.slice(1)}</span>
    </div>
  );
}

export default function Dashboard() {
  const { addEntry, deleteEntry, getEntries, getActive } = useDoseLog();
  const { getById } = useSubstances();
  const { entries: bioEntries, getLatest, getRadarData } = useBiometrics();
  const { results: labResults } = useLabResults();
  const [showModal, setShowModal] = useState(false);

  const active = getActive();
  const recent = getEntries().slice(0, 5);
  const activeSubIds = [...new Set(active.map(e => e.substanceId))];
  const allEntries = getEntries();

  const latest = getLatest();
  const healthScore = useMemo(() => {
    if (!latest) return null;
    const radar = getRadarData(latest);
    if (!radar.values.length) return null;
    return Math.round(radar.values.reduce((s, v) => s + v, 0) / radar.values.length);
  }, [latest, getRadarData]);

  const insights = useMemo(() => {
    return topInsights(allEntries, bioEntries, labResults);
  }, [allEntries, bioEntries, labResults]);

  function getName(id) {
    return getById(id)?.name || id;
  }

  return (
    <main className="page">
      <div className="summary-head" style={{ marginBottom: 28, display: 'flex', alignItems: 'flex-start', gap: 16 }}>
        <div style={{ flex: 1 }}>
          <h1 className="page-title" style={{ fontSize: 'clamp(1.5rem, 6vw, 2rem)', marginBottom: 6 }}>
            Summary
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', margin: 0 }}>
            {active.length === 0
              ? 'Nothing logged in the last 24 hours.'
              : `${active.length} dose${active.length !== 1 ? 's' : ''} logged today.`}
          </p>
        </div>
        <HealthRing score={healthScore} />
      </div>

      <PinnedCards />

      {activeSubIds.length > 0 && (
        <section style={{ marginBottom: 24 }}>
          <div className="section-label">Active Stack</div>
          <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4 }}>
            {activeSubIds.map(id => {
              const sub = getById(id);
              if (!sub) return null;
              const color = CATEGORY_COLORS[sub.category] || '#4e9cd7';
              const count = active.filter(e => e.substanceId === id).length;
              return (
                <div key={id} className="active-pill" style={{
                  background: color + '14', border: `1px solid ${color}33`,
                  flexShrink: 0,
                }}>
                  <div style={{
                    width: 3, height: 20, borderRadius: 2,
                    background: color, flexShrink: 0,
                  }} />
                  <span style={{ fontSize: '0.88rem', fontWeight: 600 }}>{sub.name}</span>
                  {count > 1 && (
                    <span style={{
                      fontSize: '0.68rem', fontWeight: 700, lineHeight: 1,
                      background: color + '22', color: color,
                      borderRadius: 100, padding: '2px 6px',
                    }}>
                      {count}x
                    </span>
                  )}
                </div>
              );
            })}
          </div>
        </section>
      )}

      <button className="btn-primary" onClick={() => setShowModal(true)} style={{ marginBottom: 28 }}>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
        </svg>
        Log a Dose
      </button>

      {insights.length > 0 && (
        <section style={{ marginBottom: 28 }}>
          <div className="section-label">Insights</div>
          {insights.slice(0, 3).map((ins, i) => (
            <InsightCard key={i} insight={ins} getName={getName} />
          ))}
        </section>
      )}

      <section>
        <div className="section-label">Recent Entries</div>
        {recent.length === 0 ? (
          <div className="card-empty">
            <img src="/brand/mascot.svg" width="64" height="64" alt="" style={{ display: 'block', margin: '0 auto 8px' }} />
            <div style={{ fontSize: '0.95rem', fontWeight: 600, marginBottom: 6 }}>Nothing logged yet</div>
            <div style={{ fontSize: '0.85rem' }}>Start tracking your doses above.</div>
          </div>
        ) : (
          <div className="entry-list">
            {recent.map(entry => (
              <LogEntry key={entry.id} entry={entry} onDelete={deleteEntry} />
            ))}
          </div>
        )}
      </section>

      {showModal && (
        <AddEntryModal onAdd={addEntry} onClose={() => setShowModal(false)} />
      )}
    </main>
  );
}
