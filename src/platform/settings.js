// Settings live in this tab's memory only (the web version stores nothing in the browser): a reload
// returns to the defaults. Validation mirrors settingsWrite() in the desktop main.cjs, minus the export
// folder, which the browser decides.
let stored = {};
export const DEFAULT_APP_TITLE = 'BonaStudio';
export const DEFAULT_SETTINGS = {
  appTitle: DEFAULT_APP_TITLE,
  exportDirectory: '',
  exportFormat: 'stl',
  autoPreview: true,
  // Renders take 10–500 ms on the built-in library (rancangan.md §11), so the web waits less than the desktop.
  previewDelay: 250,
  theme: 'system',
  transformEnabled: true,
  transformGizmo: true,
  gizmoSize: 1,
  transformShortcuts: true,
  transformShortcutMode: 'modal',
  keepOnPlate: true,
  snapMove: 1,
  snapRotate: 15,
  snapScale: 10,
  plateLayout: 'auto'
};

export function readSettings() {
  return { ...DEFAULT_SETTINGS, ...stored };
}

const clamp = (value, min, max, fallback) => (Number.isFinite(value) ? Math.min(max, Math.max(min, value)) : fallback);
const bool = (value, fallback) => (typeof value === 'boolean' ? value : fallback);

export function writeSettings(settings = {}) {
  const current = readSettings();
  const title = settings.appTitle;
  if (title !== undefined && (typeof title !== 'string' || !title.trim() || title.trim().length > 60)) {
    throw new Error('Application title must contain 1 to 60 characters.');
  }
  const next = {
    ...current,
    appTitle: title === undefined ? current.appTitle : title.trim(),
    exportDirectory: '',
    exportFormat: ['stl', '3mf'].includes(settings.exportFormat) ? settings.exportFormat : current.exportFormat,
    autoPreview: bool(settings.autoPreview, current.autoPreview),
    previewDelay: Number.isFinite(settings.previewDelay) ? Math.min(3000, Math.max(150, settings.previewDelay)) : current.previewDelay,
    theme: ['light', 'dark', 'system'].includes(settings.theme) ? settings.theme : current.theme,
    transformEnabled: bool(settings.transformEnabled, current.transformEnabled),
    transformGizmo: bool(settings.transformGizmo, current.transformGizmo),
    gizmoSize: clamp(settings.gizmoSize, 0.5, 2, current.gizmoSize),
    transformShortcuts: bool(settings.transformShortcuts, current.transformShortcuts),
    transformShortcutMode: ['modal', 'gizmo'].includes(settings.transformShortcutMode) ? settings.transformShortcutMode : current.transformShortcutMode,
    keepOnPlate: bool(settings.keepOnPlate, current.keepOnPlate),
    snapMove: clamp(settings.snapMove, 0.1, 100, current.snapMove),
    snapRotate: clamp(settings.snapRotate, 1, 90, current.snapRotate),
    snapScale: clamp(settings.snapScale, 1, 100, current.snapScale),
    plateLayout: typeof settings.plateLayout === 'string' && /^(auto|[1-4]x[1-4])$/.test(settings.plateLayout) ? settings.plateLayout : current.plateLayout
  };
  stored = next;
  if (typeof document !== 'undefined') document.title = next.appTitle;
  return next;
}
