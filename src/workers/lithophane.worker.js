// Lithophane generator in a Web Worker (port of the desktop lithophane-worker.cjs): decodes the
// height map, builds the mesh with the shared lithophane module, and writes STL or 3MF. Same reply
// shape as render.worker.js ({ output, itemEchoes }).
import { unzlibSync, zipSync, strToU8 } from 'fflate';
import { decodeGrayPng } from '../shared/heightmap.js';
import { buildLithophaneMesh, cropBorder, meshToStl, threeMfEntries } from '../shared/lithophane.js';

self.onmessage = ({ data }) => {
  try {
    const { png, values, format, preview, name } = data;
    const timings = {};
    let mark = performance.now();
    const lap = step => { const now = performance.now(); timings[step] = Math.round(now - mark); mark = now; };
    const image = png ? cropBorder(decodeGrayPng(new Uint8Array(png), bytes => unzlibSync(bytes))) : null;
    lap('decode');
    const mesh = buildLithophaneMesh(image, values, { preview });
    lap('mesh');
    let output;
    if (format === 'stl') {
      output = meshToStl(mesh);
    } else {
      const files = {};
      for (const entry of threeMfEntries(mesh, { name, color: values.plate_color })) {
        files[entry.name] = entry.parts ? concat(entry.parts.map(part => strToU8(part))) : strToU8(entry.text);
      }
      lap('xml');
      // The preview is never saved: store it uncompressed (fastest to zip and to unzip in the
      // viewer, and the buffer is transferred without copying). Exports get the usual compression.
      output = zipSync(files, { level: preview ? 0 : 6 });
    }
    lap('write');
    // Same text as OpenSCAD's echo("formforge-item", ...), parsed by transform.js.
    const itemEchoes = mesh.items.map(item => 'ECHO: ' + JSON.stringify(['formforge-item', item.id, ...item.center, ...item.size, item.rotation]).slice(1, -1));
    const buffer = output.buffer.byteLength === output.byteLength ? output.buffer : output.slice().buffer;
    self.postMessage({ output: buffer, itemEchoes, info: { ...mesh.info, demo: !image, timings } }, [buffer]);
  } catch (error) {
    self.postMessage({ error: error instanceof Error ? error.message : String(error) });
  }
};

function concat(parts) {
  const out = new Uint8Array(parts.reduce((sum, part) => sum + part.length, 0));
  let offset = 0;
  for (const part of parts) { out.set(part, offset); offset += part.length; }
  return out;
}
