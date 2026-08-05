import { useEffect, useMemo, useState } from 'react';
import { DetailPanel } from './components/DetailPanel';
import { GraphCanvas } from './components/GraphCanvas';
import { KindFilters, type RoleFilter } from './components/KindFilters';
import { SummaryBar } from './components/SummaryBar';
import { applyTheme, readStoredTheme, type ThemeMode } from './theme';
import type { VisualNode, VisualPayload } from './types/payload';

async function loadPayload(): Promise<VisualPayload> {
  if (window.__BLASTRADIUS_PAYLOAD__) {
    return window.__BLASTRADIUS_PAYLOAD__;
  }
  const response = await fetch('/api/payload.json');
  if (!response.ok) {
    throw new Error(`Failed to load payload (${response.status})`);
  }
  return (await response.json()) as VisualPayload;
}

export default function App() {
  const [payload, setPayload] = useState<VisualPayload | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<VisualNode | null>(null);
  const [roleFilter, setRoleFilter] = useState<RoleFilter>('all');
  const [activeKinds, setActiveKinds] = useState<Set<string>>(new Set());
  const [theme, setTheme] = useState<ThemeMode>(() => readStoredTheme());

  useEffect(() => {
    applyTheme(theme);
  }, [theme]);

  useEffect(() => {
    let cancelled = false;
    loadPayload()
      .then((data) => {
        if (cancelled) {
          return;
        }
        setPayload(data);
        setActiveKinds(new Set(data.graph.nodes.map((n) => n.kind)));
      })
      .catch((err: unknown) => {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : String(err));
        }
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const kinds = useMemo(() => {
    if (!payload) {
      return [] as string[];
    }
    return [...new Set(payload.graph.nodes.map((n) => n.kind))].sort();
  }, [payload]);

  if (error) {
    return <div className="error">{error}</div>;
  }
  if (!payload) {
    return <div className="loading">Loading blast radius…</div>;
  }

  return (
    <div className="app">
      <SummaryBar
        payload={payload}
        theme={theme}
        onToggleTheme={() =>
          setTheme((current) => (current === 'dark' ? 'light' : 'dark'))
        }
      />
      <KindFilters
        kinds={kinds}
        activeKinds={activeKinds}
        roleFilter={roleFilter}
        onRoleFilter={setRoleFilter}
        onToggleKind={(kind) => {
          setActiveKinds((prev) => {
            const next = new Set(prev);
            if (next.has(kind)) {
              next.delete(kind);
            } else {
              next.add(kind);
            }
            return next;
          });
        }}
      />
      <div className="workspace">
        <div className="graph-pane">
          <GraphCanvas
            payload={payload}
            activeKinds={activeKinds}
            roleFilter={roleFilter}
            theme={theme}
            onSelect={setSelected}
          />
        </div>
        <DetailPanel payload={payload} selected={selected} />
      </div>
    </div>
  );
}
