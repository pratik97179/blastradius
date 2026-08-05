import type { VisualNode, VisualPayload } from '../types/payload';

function ListBlock({ title, items }: { title: string; items: string[] }) {
  if (items.length === 0) {
    return null;
  }
  return (
    <section className="panel">
      <h2>{title}</h2>
      <ul className="list">
        {items.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    </section>
  );
}

export function DetailPanel({
  payload,
  selected,
}: {
  payload: VisualPayload;
  selected: VisualNode | null;
}) {
  const { summary } = payload;
  return (
    <aside className="side">
      <section className="panel">
        <h2>Selected</h2>
        {selected ? (
          <dl>
            <div>
              <dt>Label</dt>
              <dd>{selected.label}</dd>
            </div>
            <div>
              <dt>Kind</dt>
              <dd>{selected.kind}</dd>
            </div>
            <div>
              <dt>Role</dt>
              <dd>{selected.role}</dd>
            </div>
            <div>
              <dt>File</dt>
              <dd>{selected.filePath}</dd>
            </div>
            <div>
              <dt>Score</dt>
              <dd>{selected.score == null ? '—' : selected.score.toFixed(2)}</dd>
            </div>
          </dl>
        ) : (
          <p className="hint" style={{ minHeight: 0, padding: 0, display: 'block' }}>
            Select a node to inspect kind, file, and score.
          </p>
        )}
      </section>

      <ListBlock title="Changed" items={summary.changed} />
      <ListBlock title="Repositories" items={summary.affected.repositories} />
      <ListBlock title="Services" items={summary.affected.services} />
      <ListBlock title="State managers" items={summary.affected.stateManagers} />
      <ListBlock title="Screens" items={summary.affected.screens} />
      <ListBlock title="Widgets" items={summary.affected.widgets} />
      <ListBlock title="Suggested tests" items={summary.suggestedTests} />
    </aside>
  );
}
