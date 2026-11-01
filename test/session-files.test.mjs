import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { addToolAsset, referencedToolAssets, addIconFiles, iconIndex, readIcon } from '../src/platform/session-files.js';
import { initVtracer } from '../src/vendor/vtracer/vtracer.js';
import { traceImage } from '../src/shared/image-trace.js';
import manifest from '../src/platform/asset-manifest.json' with { type: 'json' };

test('tool assets are found through references in values, including nested trees', () => {
  const svg = addToolAsset('tool-a', '.svg', new TextEncoder().encode('<svg></svg>'));
  const png = addToolAsset('tool-a', '.png', new Uint8Array([1, 2, 3]));
  assert.match(svg, /^user-assets\/[0-9a-f-]{36}\.svg$/);
  const files = referencedToolAssets('tool-a', { icon_left_file: svg, decorative_layers: [['Icon', '', '', 'Heart', png, 0, 0, 10, 1, false, 'Front', false, [], '#000000', 0]] });
  assert.deepEqual(files.map(file => file.path).sort(), [png, svg].sort());
  assert.deepEqual(referencedToolAssets('tool-a', { icon_left_file: '' }), []);
});

test('a reference to an image from an earlier session gives a clear message', () => {
  assert.throws(() => referencedToolAssets('tool-a', { icon_left_file: 'user-assets/00000000-0000-4000-8000-000000000000.svg' }), /kept only until the page is closed/);
  // Assets belong to their tool.
  const reference = addToolAsset('tool-b', '.svg', new TextEncoder().encode('<svg></svg>'));
  assert.throws(() => referencedToolAssets('tool-a', { icon_left_file: reference }), /no longer available/);
});

test('icon folders become packs; only SVG files, hidden entries skipped', async () => {
  const file = (relative, text = '<svg viewBox="0 0 1 1"></svg>') => Object.assign(new File([text], relative.split('/').pop()), { webkitRelativePath: relative });
  const added = addIconFiles([
    file('Icons/Animals/cat.svg'), file('Icons/Animals/dog_face.svg'), file('Icons/Tools/hammer.svg'),
    file('Icons/.hidden/x.svg'), file('Icons/Animals/readme.txt', 'x'), file('heart.svg')
  ]);
  assert.equal(added, 4);
  const index = iconIndex();
  assert.deepEqual(index.packs.map(pack => [pack.name, pack.count]), [['', 1], ['Animals', 2], ['Tools', 1]]);
  assert.ok(index.icons.some(icon => icon.pack === 'Animals' && icon.path === 'dog_face.svg' && icon.name === 'dog face'));
  assert.match(await readIcon('Animals', 'cat.svg'), /<svg/);
  await assert.rejects(readIcon('Animals', '../Tools/hammer.svg'), /not in the icon library/);
});

test('vtracer (browser build) traces an image into color layers', () => {
  initVtracer(new WebAssembly.Module(readFileSync(new URL('../public/' + manifest.vtracer, import.meta.url))));
  const width = 40, height = 40, rgba = new Uint8Array(width * height * 4);
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    const i = (y * width + x) * 4;
    const red = x < 20, inside = x > 4 && x < 36 && y > 4 && y < 36;
    rgba.set(inside ? (red ? [220, 30, 30, 255] : [30, 30, 220, 255]) : [255, 255, 255, 255], i);
  }
  const result = traceImage({ rgba, width, height, maxColors: 0, removeBackground: true, detail: 'medium' });
  assert.match(result.svg, /<g id="c0"/);
  assert.equal(result.colors.length, 2);
});
