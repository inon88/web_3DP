import test from 'node:test';
import assert from 'node:assert/strict';
import { createHistory } from '../src/web/history.js';

test('undo and redo walk through separate steps', async () => {
  const history = createHistory();
  history.reset({ width: 10 });
  history.push({ width: 20 });
  await new Promise(resolve => setTimeout(resolve, 650));
  history.push({ width: 30 });
  assert.deepEqual(history.undo(), { width: 20 });
  assert.deepEqual(history.undo(), { width: 10 });
  assert.equal(history.undo(), null);
  assert.deepEqual(history.redo(), { width: 20 });
});

test('rapid changes coalesce into one step but keep the baseline', () => {
  const history = createHistory();
  history.reset({ width: 10 });
  for (const width of [11, 12, 13, 14]) history.push({ width });
  assert.deepEqual(history.undo(), { width: 10 });
  assert.deepEqual(history.redo(), { width: 14 });
});
