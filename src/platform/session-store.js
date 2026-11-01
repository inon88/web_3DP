// The web version keeps nothing in the browser: presets and settings live in this tab's memory, like the
// files people add (session-files.js). Closing or reloading the page returns everything to its defaults.
const memory = new Map();

export const sessionStore = Object.freeze({
  get: key => (memory.has(key) ? memory.get(key) : null),
  set: (key, value) => { memory.set(key, String(value)); },
  remove: key => { memory.delete(key); }
});

// Keys written to localStorage by earlier web builds (settings, presets). Removed once at start-up,
// so nothing from before this change is left behind in the browser.
const LEGACY_KEYS = /^(bonastudio:|formforge:)/;

export function forgetStoredData() {
  try {
    for (const key of Object.keys(localStorage)) if (LEGACY_KEYS.test(key)) localStorage.removeItem(key);
  } catch {
    // Storage blocked (private mode, policies): there is nothing to remove.
  }
}
