import type { VisualNode, VisualPayload } from '../types/payload';
import type { RoleFilter } from '../components/KindFilters';

export interface DisplayNode {
  id: string;
  label: string;
  kind: string;
  role: string;
  source: VisualNode;
  column: number;
  row: number;
}

export interface DisplayEdge {
  id: string;
  source: string;
  target: string;
  kind: string;
}

const KIND_COLUMN: Record<string, number> = {
  service: 1,
  repository: 2,
  bloc: 3,
  cubit: 3,
  changeNotifier: 3,
  provider: 3,
  widget: 4,
  screen: 5,
  other: 4,
};

function classAnchorId(node: VisualNode, classNodes: Map<string, VisualNode>): string | null {
  if (!node.isMethod || !node.className) {
    return null;
  }
  return classNodes.get(node.className)?.id ?? null;
}

/**
 * Collapse non-seed methods into class nodes and assign architecture columns
 * so the blast reads left → right without method noise.
 */
export function buildDisplayGraph(
  payload: VisualPayload,
  activeKinds: Set<string>,
  roleFilter: RoleFilter,
): { nodes: DisplayNode[]; edges: DisplayEdge[] } {
  const byId = new Map(payload.graph.nodes.map((n) => [n.id, n]));
  const classNodes = new Map(
    payload.graph.nodes
      .filter((n) => !n.isMethod)
      .map((n) => [n.label, n]),
  );

  const keep = new Map<string, VisualNode>();

  for (const node of payload.graph.nodes) {
    if (!activeKinds.has(node.kind)) {
      continue;
    }
    if (roleFilter !== 'all' && node.role !== roleFilter) {
      continue;
    }

    if (node.role === 'seed') {
      keep.set(node.id, node);
      continue;
    }

    if (node.isMethod) {
      const classId = classAnchorId(node, classNodes);
      if (classId) {
        const cls = byId.get(classId);
        if (
          cls &&
          activeKinds.has(cls.kind) &&
          (roleFilter === 'all' || cls.role === roleFilter || cls.role === 'affected')
        ) {
          // Prefer keeping an affected class even if role filter is all.
          if (!keep.has(cls.id)) {
            keep.set(cls.id, cls);
          }
        }
      }
      continue;
    }

    keep.set(node.id, node);
  }

  // Ensure class endpoints for kept seed methods exist when filters allow.
  for (const node of [...keep.values()]) {
    if (!node.isMethod || !node.className) {
      continue;
    }
    const cls = classNodes.get(node.className);
    if (!cls || keep.has(cls.id)) {
      continue;
    }
    if (!activeKinds.has(cls.kind)) {
      continue;
    }
    if (roleFilter !== 'all' && cls.role !== roleFilter && node.role !== 'seed') {
      continue;
    }
    keep.set(cls.id, cls);
  }

  const resolve = (id: string): string | null => {
    const node = byId.get(id);
    if (!node) {
      return null;
    }
    if (keep.has(node.id)) {
      return node.id;
    }
    if (node.isMethod) {
      const classId = classAnchorId(node, classNodes);
      if (classId && keep.has(classId)) {
        return classId;
      }
    }
    return null;
  };

  const edgeKeys = new Set<string>();
  const edges: DisplayEdge[] = [];
  for (const edge of payload.graph.edges) {
    if (edge.kind === 'extendsType' || edge.kind === 'implementsType') {
      continue;
    }
    const from = resolve(edge.from);
    const to = resolve(edge.to);
    if (!from || !to || from === to) {
      continue;
    }
    // Impact direction: dependency → dependent
    const source = to;
    const target = from;
    const key = `${source}|${target}|${edge.kind}`;
    if (edgeKeys.has(key)) {
      continue;
    }
    edgeKeys.add(key);
    edges.push({
      id: key,
      source,
      target,
      kind: edge.kind,
    });
  }

  const columnBuckets = new Map<number, VisualNode[]>();
  for (const node of keep.values()) {
    const column = node.role === 'seed' ? 0 : (KIND_COLUMN[node.kind] ?? 4);
    const bucket = columnBuckets.get(column) ?? [];
    bucket.push(node);
    columnBuckets.set(column, bucket);
  }

  const nodes: DisplayNode[] = [];
  const columns = [...columnBuckets.keys()].sort((a, b) => a - b);
  for (const column of columns) {
    const bucket = columnBuckets.get(column)!;
    bucket.sort((a, b) => a.label.localeCompare(b.label));
    bucket.forEach((node, row) => {
      nodes.push({
        id: node.id,
        label: node.label,
        kind: node.kind,
        role: node.role,
        source: node,
        column,
        row,
      });
    });
  }

  return { nodes, edges };
}

export function layoutPositions(
  nodes: DisplayNode[],
): Map<string, { x: number; y: number }> {
  const colGap = 260;
  const rowGap = 88;
  const positions = new Map<string, { x: number; y: number }>();
  const colCounts = new Map<number, number>();
  for (const node of nodes) {
    colCounts.set(node.column, (colCounts.get(node.column) ?? 0) + 1);
  }
  const maxRows = Math.max(1, ...colCounts.values());

  for (const node of nodes) {
    const count = colCounts.get(node.column) ?? 1;
    const blockHeight = (count - 1) * rowGap;
    const startY = ((maxRows - 1) * rowGap - blockHeight) / 2;
    positions.set(node.id, {
      x: node.column * colGap,
      y: startY + node.row * rowGap,
    });
  }
  return positions;
}
