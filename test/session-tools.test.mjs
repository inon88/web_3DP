// Tools imported in this session (src/platform/session-tools.js): files, project folders, links, limits.
import test from 'node:test';
import assert from 'node:assert/strict';
import {
  importScadFile, readProjectFolder, suggestEntry, importProject, normalizeImportUrl, importUrl,
  sessionToolList, sessionToolFiles, isSessionTool, deleteSessionTool, addCustomParameter, withCustomParameters,
  resolveToolPath, missingReferencedFiles, IMPORT_LIMITS
} from '../src/platform/session-tools.js';
import { scadDescription } from '../src/platform/describe.js';

const encoder = new TextEncoder();
const fakeFile = (name, text, size) => {
  const data = typeof text === 'string' ? encoder.encode(text) : text;
  return { name, size: size ?? data.byteLength, arrayBuffer: async () => data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength) };
};
const SCAD = '// Simple box for tests.\n/* [Size] */\nwidth = 10; // [1:1:50]\ncube(width);\n';

test('a .scad file becomes a session tool with parsed parameters and a description', async () => {
  const tool = await importScadFile(fakeFile('My_box.scad', SCAD));
  assert.equal(tool.name, 'My_box');
  assert.equal(tool.entry, 'model.scad');
  assert.equal(tool.category, 'Imported');
  assert.equal(tool.session, true);
  assert.equal(tool.description, 'Simple box for tests.');
  assert.deepEqual(tool.parameters.map(parameter => parameter.name), ['width']);
  assert.match(tool.revision, /^session-/);
  assert.ok(isSessionTool(tool.id));
  assert.ok(sessionToolList().some(item => item.id === tool.id));
  assert.equal(new TextDecoder().decode(sessionToolFiles(tool.id)[0].data), SCAD);
  assert.ok(deleteSessionTool(tool.id));
  assert.throws(() => sessionToolFiles(tool.id), /kept only until the page is closed/);
});

test('file import rejects other types, empty files and files over 10 MB', async () => {
  await assert.rejects(importScadFile(fakeFile('model.stl', SCAD)), /\.scad/);
  await assert.rejects(importScadFile(fakeFile('empty.scad', '   ')), /empty/);
  await assert.rejects(importScadFile(fakeFile('big.scad', 'x', IMPORT_LIMITS.scadBytes + 1)), /10 MB/);
});

test('project folders skip hidden files and node_modules, and suggest the main file', async () => {
  const project = await readProjectFolder([
    { path: 'Bowl/parts.scad', file: fakeFile('parts.scad', 'module p() {}') },
    { path: 'Bowl/bowl.scad', file: fakeFile('bowl.scad', 'size = 3; // [1:5]\nicon = "a.svg";\nimport("art/a.svg");') },
    { path: 'Bowl/art/a.svg', file: fakeFile('a.svg', '<svg></svg>') },
    { path: 'Bowl/.git/config', file: fakeFile('config', 'x') },
    { path: 'Bowl/node_modules/x/y.scad', file: fakeFile('y.scad', 'x') }
  ]);
  assert.equal(project.name, 'Bowl');
  assert.deepEqual(project.files.map(file => file.path), ['art/a.svg', 'bowl.scad', 'parts.scad']);
  assert.equal(suggestEntry(project), 'bowl.scad');
  const tool = importProject(project, 'bowl.scad');
  assert.equal(tool.entry, 'project/bowl.scad');
  assert.equal(tool.category, 'Project');
  assert.deepEqual(tool.files.map(file => file.path), ['project/art/a.svg', 'project/bowl.scad', 'project/parts.scad']);
  assert.deepEqual(missingReferencedFiles(tool, 'import("art/a.svg"); surface("missing.png");'), ['missing.png']);
  assert.throws(() => importProject(project, 'other.scad'), /inside the selected project folder/);
  deleteSessionTool(tool.id);
});

test('a folder without .scad files is refused', async () => {
  await assert.rejects(readProjectFolder([{ path: 'Art/a.svg', file: fakeFile('a.svg', '<svg/>') }]), /no \.scad file/);
});

test('paths a model refers to are resolved next to its entry file and cannot leave the tool', () => {
  assert.equal(resolveToolPath('project/sub/main.scad', '../img/a.png'), 'project/img/a.png');
  assert.equal(resolveToolPath('model.scad', './a.svg'), 'a.svg');
  assert.equal(resolveToolPath('model.scad', '../../etc/x'), null);
  const single = { entry: 'model.scad', files: [{ path: 'model.scad' }] };
  assert.deepEqual(missingReferencedFiles(single, 'import("logo.svg");'), ['logo.svg']);
  assert.deepEqual(missingReferencedFiles(single, 'import(icon_left_file);'), []);
});

test('import links are checked like the desktop and file pages become raw links', () => {
  assert.equal(normalizeImportUrl('https://github.com/a/b/blob/main/dir/x.scad').href, 'https://raw.githubusercontent.com/a/b/main/dir/x.scad');
  assert.equal(normalizeImportUrl('https://gitlab.com/g/p/-/blob/main/x.scad').href, 'https://gitlab.com/g/p/-/raw/main/x.scad');
  assert.equal(normalizeImportUrl('https://codeberg.org/u/r/src/branch/main/x.scad').href, 'https://codeberg.org/u/r/raw/branch/main/x.scad');
  assert.equal(normalizeImportUrl('https://example.com/m.scad#top').href, 'https://example.com/m.scad');
  assert.throws(() => normalizeImportUrl('http://example.com/m.scad'), /HTTPS only/);
  assert.throws(() => normalizeImportUrl('https://user:pw@example.com/m.scad'), /username or password/);
  assert.throws(() => normalizeImportUrl('https://localhost/m.scad'), /Local addresses/);
  assert.throws(() => normalizeImportUrl('https://192.168.1.5/m.scad'), /Local addresses/);
  assert.throws(() => normalizeImportUrl('https://[::1]/m.scad'), /Local addresses/);
  assert.throws(() => normalizeImportUrl('https://example.com/m.stl'), /\.scad file/);
  assert.throws(() => normalizeImportUrl('not a url'), /Invalid URL/);
});

test('link imports: no credentials, size limit, web pages and blocked downloads give clear messages', async () => {
  let options = null;
  const ok = async (url, init) => { options = init; return new Response(SCAD, { status: 200 }); };
  const tool = await importUrl('https://github.com/a/b/blob/main/Tray%20box.scad', ok);
  assert.equal(options.credentials, 'omit');
  assert.equal(tool.name, 'Tray box');
  assert.equal(tool.sourceUrl, 'https://raw.githubusercontent.com/a/b/main/Tray%20box.scad');
  deleteSessionTool(tool.id);

  const big = new Uint8Array(IMPORT_LIMITS.scadBytes + 10);
  await assert.rejects(importUrl('https://example.com/big.scad', async () => new Response(big)), /10 MB/);
  await assert.rejects(importUrl('https://example.com/page.scad', async () => new Response('<!doctype html><html></html>')), /web page/);
  await assert.rejects(importUrl('https://example.com/x.scad', async () => new Response('', { status: 404 })), /HTTP 404/);
  await assert.rejects(importUrl('https://example.com/x.scad', async () => { throw new TypeError('Failed to fetch'); }), /not allow downloads from other websites/);
});

test('custom parameters are added for this session, also to built-in tools', () => {
  const builtIn = { id: 'bracket', parameters: [{ name: 'width', type: 'number', default: 1 }] };
  addCustomParameter(builtIn, { name: 'extra_height', label: 'Extra height', type: 'number', default: '2.5' });
  const merged = withCustomParameters(builtIn);
  assert.deepEqual(merged.parameters.at(-1), { name: 'extra_height', label: 'Extra height', type: 'number', default: 2.5, group: 'Custom parameters', description: 'Manual parameter', source: 'manual' });
  assert.equal(builtIn.parameters.length, 1, 'the library manifest itself is not changed');
  assert.throws(() => addCustomParameter(builtIn, { name: 'width', type: 'number', default: 1 }), /already exists/);
  assert.throws(() => addCustomParameter(builtIn, { name: '1bad', type: 'number', default: 1 }), /letters, numbers, and underscores/);
  assert.throws(() => addCustomParameter(builtIn, { name: 'n', type: 'number', default: 'x' }), /invalid/);
  assert.throws(() => addCustomParameter({ id: 'g', kind: 'generator' }, { name: 'n', type: 'boolean' }), /fixed set/);
});

test('gallery descriptions come from the first sentence of the opening comment', () => {
  assert.equal(scadDescription('// Parametric name keychain\n// Recreated from a link.\n'), 'Parametric name keychain.');
  assert.equal(scadDescription('\n// Flat lithophane: a photo. More text.\n'), 'Flat lithophane: a photo.');
  assert.equal(scadDescription('// @formforge-3mf-objects\n// Tray.\n'), 'Tray.');
  assert.equal(scadDescription('/* [Size] */\nw = 1;'), '');
  assert.ok(scadDescription('// ' + 'word '.repeat(60)).endsWith('…'));
});
