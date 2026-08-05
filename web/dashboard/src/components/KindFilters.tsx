export type RoleFilter = 'all' | 'seed' | 'affected';

export function KindFilters({
  kinds,
  activeKinds,
  roleFilter,
  onToggleKind,
  onRoleFilter,
}: {
  kinds: string[];
  activeKinds: Set<string>;
  roleFilter: RoleFilter;
  onToggleKind: (kind: string) => void;
  onRoleFilter: (role: RoleFilter) => void;
}) {
  return (
    <div className="toolbar">
      <div className="toolbar-group">
        <span className="toolbar-label">Focus</span>
        {(['all', 'seed', 'affected'] as RoleFilter[]).map((role) => (
          <button
            key={role}
            type="button"
            className={`chip${roleFilter === role ? ' active' : ''}`}
            onClick={() => onRoleFilter(role)}
          >
            {role}
          </button>
        ))}
      </div>
      <div className="toolbar-group">
        <span className="toolbar-label">Kinds</span>
        {kinds.map((kind) => (
          <button
            key={kind}
            type="button"
            className={`chip${activeKinds.has(kind) ? ' active' : ''}`}
            onClick={() => onToggleKind(kind)}
          >
            {kind}
          </button>
        ))}
      </div>
    </div>
  );
}
