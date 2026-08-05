export type NodeRole = 'seed' | 'affected' | 'context';

export interface VisualNode {
  id: string;
  label: string;
  kind: string;
  filePath: string;
  isMethod: boolean;
  className: string | null;
  role: NodeRole;
  score: number | null;
}

export interface VisualEdge {
  from: string;
  to: string;
  kind: string;
  confidence: number;
}

export interface VisualPayload {
  meta: {
    packageName: string;
    projectRoot: string;
    platform: string;
    command: string;
    generatedAt: string;
  };
  summary: {
    changed: string[];
    changedFiles: string[];
    affected: {
      repositories: string[];
      services: string[];
      stateManagers: string[];
      screens: string[];
      widgets: string[];
    };
    suggestedTests: string[];
    risk: string;
    confidence: number;
    confidencePercent: number;
    empty: boolean;
  };
  graph: {
    nodes: VisualNode[];
    edges: VisualEdge[];
  };
}
