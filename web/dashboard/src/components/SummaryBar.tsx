import type { ThemeMode } from '../theme';
import type { VisualPayload } from '../types/payload';

export function SummaryBar({
  payload,
  theme,
  onToggleTheme,
}: {
  payload: VisualPayload;
  theme: ThemeMode;
  onToggleTheme: () => void;
}) {
  const { meta, summary } = payload;
  return (
    <header className="topbar">
      <div className="brand-block">
        <h1 className="brand-mark">BlastRadius</h1>
        <p className="brand-meta">
          {meta.packageName} · {meta.platform} · {meta.command}
        </p>
      </div>
      <div className="topbar-right">
        <div className="metrics">
          <div className={`metric risk-${summary.risk}`}>
            <span>Risk</span>
            <strong>{summary.risk}</strong>
          </div>
          <div className="metric">
            <span>Confidence</span>
            <strong>{summary.confidencePercent}%</strong>
          </div>
          <div className="metric">
            <span>Nodes</span>
            <strong>{payload.graph.nodes.length}</strong>
          </div>
        </div>
        <button
          type="button"
          className="theme-toggle"
          onClick={onToggleTheme}
          aria-label="Toggle color theme"
        >
          {theme === 'dark' ? 'Light' : 'Dark'}
        </button>
      </div>
    </header>
  );
}
