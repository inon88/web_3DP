// Render worker: instantiate the precompiled module, run OpenSCAD, parse binary STL here (S6),
// and transfer a Float32Array of triangle positions back to the main thread.
import OpenSCAD from '/openscad/openscad.js';

function mkdirp(FS, dir) {
  let current = '';
  for (const part of dir.split('/').filter(Boolean)) {
    current += '/' + part;
    try { FS.mkdir(current); } catch {}
  }
}

function parseBinaryStl(bytes) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const count = view.getUint32(80, true);
  const positions = new Float32Array(count * 9);
  let offset = 84;
  for (let i = 0; i < count; i++) {
    offset += 12; // skip normal; the viewer recomputes it
    for (let j = 0; j < 9; j++) { positions[i * 9 + j] = view.getFloat32(offset, true); offset += 4; }
    offset += 2;
  }
  return positions;
}

self.onmessage = async ({ data }) => {
  const { wasmModule, source, entry, assets, fonts, backend, quality } = data;
  const lines = [];
  try {
    const t0 = performance.now();
    const module = await OpenSCAD({
      noInitialRun: true,
      noExitRuntime: true,
      instantiateWasm(imports, receive) {
        WebAssembly.instantiate(wasmModule, imports).then(instance => receive(instance, wasmModule));
        return {};
      },
      print: line => lines.push(String(line)),
      printErr: line => lines.push(String(line))
    });
    const instantiate = performance.now() - t0;
    const FS = module.FS;
    mkdirp(FS, '/workspace');
    FS.writeFile('/workspace/' + entry, source);
    for (const asset of assets) {
      const target = '/workspace/' + asset.path;
      mkdirp(FS, target.slice(0, target.lastIndexOf('/')));
      FS.writeFile(target, new Uint8Array(asset.data));
    }
    if (fonts.length) {
      mkdirp(FS, '/fonts');
      for (const font of fonts) FS.writeFile('/fonts/' + font.name, new Uint8Array(font.data));
      FS.writeFile('/fonts/fonts.conf', '<?xml version="1.0"?><fontconfig><dir>/fonts</dir></fontconfig>');
      if (module.ENV) module.ENV.FONTCONFIG_FILE = '/fonts/fonts.conf';
    }
    const argv = ['-o', '/out.stl', '--export-format', 'binstl'];
    if (backend) argv.push('--backend=' + backend);
    argv.push('-D', '$fn=0', '-D', '$fa=' + quality.fa, '-D', '$fs=' + quality.fs, '/workspace/' + entry);
    const t1 = performance.now();
    try { module.callMain(argv); } catch (error) {
      if (error?.name !== 'ExitStatus' || error.status !== 0) throw error;
    }
    const render = performance.now() - t1;
    const t2 = performance.now();
    const positions = parseBinaryStl(FS.readFile('/out.stl'));
    const parse = performance.now() - t2;
    self.postMessage({ ok: true, instantiate, render, parse, positions }, [positions.buffer]);
  } catch (error) {
    self.postMessage({ ok: false, error: String(error?.message || error) + ' | ' + lines.slice(-4).join(' / ') });
  }
};
