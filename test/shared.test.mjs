// The synced modules load as ES modules and the zlib/Buffer shim keeps 3MF zip handling working.
import test from 'node:test';
import assert from 'node:assert/strict';
import { parseParameters } from '../src/shared/parameters.js';
import { readZip, writeZip } from '../src/shared/mesh-transform.js';
import { referencedAssetPaths, exportsSeparateObjects } from '../src/shared/scad-assets.js';

test('parameters parse a Customizer variable', () => {
  const parameters = parseParameters('width = 20; // [10:50]\n');
  assert.equal(parameters[0].name, 'width');
  assert.equal(parameters[0].default, 20);
});

test('zip round-trips through the fflate shim', () => {
  const data = new TextEncoder().encode('<model>'.repeat(200));
  const zip = writeZip([{ name: '3D/3dmodel.model', data }]);
  const [entry] = readZip(zip);
  assert.equal(entry.name, '3D/3dmodel.model');
  assert.deepEqual(new Uint8Array(entry.data), data);
});

test('scad-assets keeps its pure helpers', () => {
  assert.deepEqual(referencedAssetPaths('surface("a.png"); // import("b.svg")'), ['a.png']);
  assert.equal(exportsSeparateObjects('// @formforge-3mf-objects\ncube(1);'), true);
});
