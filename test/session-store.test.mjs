import test from 'node:test';
import assert from 'node:assert/strict';

// A localStorage that records every write, so the tests can prove nothing is stored.
const backing = new Map([['bonastudio:settings', '{"theme":"dark"}'], ['formforge:presets:bracket', '[]'], ['other-site-key', 'keep']]);
const writes = [];
Object.defineProperty(globalThis, 'localStorage', {
  configurable: true,
  value: new Proxy({}, {
    get: (_, name) => ({
      getItem: key => backing.get(key) ?? null,
      setItem: (key, value) => { writes.push(key); backing.set(key, String(value)); },
      removeItem: key => backing.delete(key)
    })[name],
    ownKeys: () => [...backing.keys()],
    getOwnPropertyDescriptor: () => ({ enumerable: true, configurable: true })
  })
});

const { readSettings, writeSettings, DEFAULT_SETTINGS } = await import('../src/platform/settings.js');
const { sessionStore, forgetStoredData } = await import('../src/platform/session-store.js');

test('settings change for this visit only and never reach localStorage', () => {
  assert.equal(readSettings().theme, DEFAULT_SETTINGS.theme, 'old stored settings are not read');
  writeSettings({ theme: 'dark', previewDelay: 500 });
  assert.equal(readSettings().theme, 'dark');
  assert.equal(readSettings().previewDelay, 500);
  assert.throws(() => writeSettings({ appTitle: '' }), /1 to 60 characters/);
  assert.deepEqual(writes, []);
});

test('presets live in memory', () => {
  sessionStore.set('formforge:presets:bracket', JSON.stringify([{ name: 'A', values: {} }]));
  assert.equal(JSON.parse(sessionStore.get('formforge:presets:bracket'))[0].name, 'A');
  sessionStore.remove('formforge:presets:bracket');
  assert.equal(sessionStore.get('formforge:presets:bracket'), null);
  assert.deepEqual(writes, []);
});

test('start-up removes data earlier builds stored, and nothing else', () => {
  forgetStoredData();
  assert.deepEqual([...backing.keys()], ['other-site-key']);
});
