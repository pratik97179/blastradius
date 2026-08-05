import cytoscape, { type Core } from 'cytoscape';
import { useEffect, useRef } from 'react';
import { buildDisplayGraph, layoutPositions } from '../graph/displayGraph';
import { cssVar } from '../theme';
import type { VisualNode, VisualPayload } from '../types/payload';
import type { RoleFilter } from './KindFilters';

const kindColorsLight: Record<string, string> = {
  service: '#1f3d2a',
  repository: '#0b6e6a',
  bloc: '#8a4b08',
  cubit: '#8a4b08',
  changeNotifier: '#8a4b08',
  provider: '#8a4b08',
  screen: '#c24e00',
  widget: '#5c614f',
  other: '#7a7f6c',
};

const kindColorsDark: Record<string, string> = {
  service: '#9fbf8a',
  repository: '#5fd0c4',
  bloc: '#f0c14d',
  cubit: '#f0c14d',
  changeNotifier: '#f0c14d',
  provider: '#f0c14d',
  screen: '#ff8a3d',
  widget: '#9aa190',
  other: '#7d836c',
};

function themeKindColors(): Record<string, string> {
  const mode = document.documentElement.dataset.theme === 'light' ? 'light' : 'dark';
  return mode === 'light' ? kindColorsLight : kindColorsDark;
}

function graphStyles(): cytoscape.StylesheetStyle[] {
  const nodeBg = cssVar('--node-bg', '#22281e');
  const nodeText = cssVar('--node-text', '#ebe7db');
  const edge = cssVar('--edge', '#6d7562');
  const edgeCalls = cssVar('--edge-calls', '#5fd0c4');
  const accent = cssVar('--accent', '#ff8a3d');
  const ink = cssVar('--ink', '#ebe7db');

  return [
    {
      selector: 'node',
      style: {
        label: 'data(label)',
        'font-family': 'IBM Plex Mono, ui-monospace, monospace',
        'font-size': '12px',
        'font-weight': 500,
        color: nodeText,
        'text-valign': 'center',
        'text-halign': 'center',
        'text-wrap': 'ellipsis',
        'text-max-width': '140px',
        'background-color': nodeBg,
        'border-width': 2,
        'border-color': 'data(color)',
        shape: 'round-rectangle',
        width: '168px',
        height: '44px',
      },
    },
    {
      selector: 'node[role = "seed"]',
      style: {
        'border-width': 3,
        'border-color': accent,
        'background-color': cssVar('--accent-soft', 'rgba(255,138,61,0.16)'),
        'font-weight': 700,
      },
    },
    {
      selector: 'edge',
      style: {
        width: 2,
        'line-color': edge,
        'target-arrow-color': edge,
        'target-arrow-shape': 'triangle',
        'curve-style': 'bezier',
        'control-point-step-size': 40,
        opacity: 0.85,
        'arrow-scale': 1,
      },
    },
    {
      selector: 'edge[kind = "calls"]',
      style: {
        'line-color': edgeCalls,
        'target-arrow-color': edgeCalls,
      },
    },
    {
      selector: 'edge[kind = "uses"]',
      style: {
        'line-style': 'dashed',
        'line-dash-pattern': [6, 4],
        opacity: 0.7,
      },
    },
    {
      selector: ':selected',
      style: {
        'border-color': ink,
        'border-width': 3,
        'line-color': ink,
        'target-arrow-color': ink,
      },
    },
  ] as cytoscape.StylesheetStyle[];
}

export function GraphCanvas({
  payload,
  activeKinds,
  roleFilter,
  theme,
  onSelect,
}: {
  payload: VisualPayload;
  activeKinds: Set<string>;
  roleFilter: RoleFilter;
  theme: string;
  onSelect: (node: VisualNode | null) => void;
}) {
  const hostRef = useRef<HTMLDivElement | null>(null);
  const cyRef = useRef<Core | null>(null);
  const nodesById = useRef(new Map<string, VisualNode>());
  const onSelectRef = useRef(onSelect);
  onSelectRef.current = onSelect;

  useEffect(() => {
    if (!hostRef.current) {
      return;
    }

    const cy = cytoscape({
      container: hostRef.current,
      style: graphStyles(),
      layout: { name: 'preset' },
      elements: [],
      minZoom: 0.25,
      maxZoom: 2.2,
      wheelSensitivity: 0.25,
    });

    cy.on('tap', 'node', (event) => {
      const id = event.target.id() as string;
      onSelectRef.current(nodesById.current.get(id) ?? null);
    });
    cy.on('tap', (event) => {
      if (event.target === cy) {
        onSelectRef.current(null);
      }
    });

    cyRef.current = cy;
    return () => {
      cy.destroy();
      cyRef.current = null;
    };
  }, []);

  useEffect(() => {
    const cy = cyRef.current;
    if (!cy) {
      return;
    }

    const { nodes, edges } = buildDisplayGraph(payload, activeKinds, roleFilter);
    const positions = layoutPositions(nodes);
    nodesById.current = new Map(nodes.map((n) => [n.id, n.source]));
    const colors = themeKindColors();

    cy.style().fromJson(graphStyles()).update();

    cy.batch(() => {
      cy.elements().remove();
      cy.add(
        nodes.map((node) => {
          const pos = positions.get(node.id) ?? { x: 0, y: 0 };
          return {
            group: 'nodes' as const,
            data: {
              id: node.id,
              label: node.label,
              role: node.role,
              color: colors[node.kind] ?? colors.other,
            },
            position: pos,
          };
        }),
      );
      cy.add(
        edges.map((edge) => ({
          group: 'edges' as const,
          data: {
            id: edge.id,
            source: edge.source,
            target: edge.target,
            kind: edge.kind,
          },
        })),
      );
    });

    cy.fit(undefined, 56);
  }, [payload, activeKinds, roleFilter, theme]);

  return (
    <>
      <div className="graph-host" ref={hostRef} />
      <p className="graph-hint">
        Layered left → right · methods collapsed into classes · solid = calls ·
        dashed = uses
      </p>
    </>
  );
}
