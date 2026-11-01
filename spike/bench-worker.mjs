import { parentPort, workerData } from 'node:worker_threads';

const { wasmModule, glueUrl, entry, files, fonts, backend, quality } = workerData;
const lines = [];

function mkdirp(FS, dir) {
  let current = '';
  for (const part of dir.split('/').filter(Boolean)) {
    current += '/' + part;
    try { FS.mkdir(current); } catch {}
  }
}

try {
  const t0 = performance.now();
  const imported = await import(glueUrl);
  const create = imported.default || imported.OpenSCAD || imported;
  const module = await create({
    noInitialRun: true,
    noExitRuntime: true,
    // Reuse the precompiled module: instantiate only, no recompilation.
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
  for (const file of files) {
    const target = '/workspace/' + file.path;
    mkdirp(FS, target.slice(0, target.lastIndexOf('/')));
    FS.writeFile(target, new Uint8Array(file.data));
  }
  if (fonts.length) {
    mkdirp(FS, '/fonts');
    for (const font of fonts) FS.writeFile('/fonts/' + font.name, new Uint8Array(font.data));
    FS.writeFile('/fonts/fonts.conf', '<?xml version="1.0"?><fontconfig><dir>/fonts</dir></fontconfig>');
    if (module.ENV) module.ENV.FONTCONFIG_FILE = '/fonts/fonts.conf';
  }

  const argv = ['-o', '/out.stl', '--export-format', 'binstl'];
  if (backend) argv.push('--backend=' + backend);
  argv.push('-D', '$fn=0', '-D', '$fa=' + quality.fa, '-D', '$fs=' + quality.fs);
  argv.push('/workspace/' + entry);

  const t1 = performance.now();
  try { module.callMain(argv); } catch (error) {
    if (error?.name !== 'ExitStatus' || error.status !== 0) throw error;
  }
  const render = performance.now() - t1;
  const out = FS.readFile('/out.stl');
  const triangles = new DataView(out.buffer, out.byteOffset).getUint32(80, true);
  parentPort.postMessage({ ok: true, instantiate, render, bytes: out.byteLength, triangles, log: lines.slice(-6) });
} catch (error) {
  parentPort.postMessage({ ok: false, error: String(error?.message || error) + ' | ' + lines.slice(-4).join(' / ') });
}
