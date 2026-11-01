// Parameter undo/redo. Snapshots are whole value objects (small: tens of parameters). Changes that follow
// each other within COALESCE_MS (a slider drag, typing a number) become one step.
const COALESCE_MS = 600;

export function createHistory(limit = 100) {
  let entries = [];
  let index = -1;
  let lastPush = 0;
  const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

  return {
    reset(snapshot) {
      entries = [structuredClone(snapshot)];
      index = 0;
      lastPush = 0;
    },
    // Records the state after a change.
    push(snapshot) {
      if (index >= 0 && same(entries[index], snapshot)) return;
      const now = performance.now();
      entries = entries.slice(0, index + 1);
      // Coalesce into the previous step, but never overwrite the baseline (entry 0).
      if (now - lastPush < COALESCE_MS && index > 0) entries[index] = structuredClone(snapshot);
      else entries.push(structuredClone(snapshot));
      if (entries.length > limit) entries.shift();
      index = entries.length - 1;
      lastPush = now;
    },
    undo() {
      if (index <= 0) return null;
      lastPush = 0;
      return structuredClone(entries[--index]);
    },
    redo() {
      if (index >= entries.length - 1) return null;
      lastPush = 0;
      return structuredClone(entries[++index]);
    },
    get canUndo() { return index > 0; },
    get canRedo() { return index < entries.length - 1; }
  };
}
