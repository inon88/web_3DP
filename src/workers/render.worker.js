// One render per worker: instantiate the precompiled OpenSCAD module, write the tool's files into the
// virtual file system, run OpenSCAD, and transfer the output back. Ported from scad-render-worker.cjs.
// Hash-verified copy written by scripts/fetch-assets.mjs; bundled into this worker by Vite.
import createOpenSCAD from '../vendor/openscad/openscad.js';

function describeError(error) {
  if (error instanceof Error) return error.message || error.name || 'OpenSCAD WASM failed.';
  if (typeof error === 'string') return error;
  if (error && typeof error === 'object') {
    if (error.name === 'ExitStatus') return 'OpenSCAD stopped with exit code ' + error.status + '.';
    try { return 'OpenSCAD WASM failed: ' + JSON.stringify(error); } catch {}
  }
  return 'OpenSCAD WASM failed with an unrecognized error.';
}

function mkdirp(FS, directory) {
  let current = '';
  for (const part of directory.split('/').filter(Boolean)) {
    current += '/' + part;
    try { FS.mkdir(current); } catch (error) {
      if (error.code !== 'EEXIST' && error.errno !== 20) throw new Error('Could not create the virtual folder ' + current + '.');
    }
  }
}

async function render(request) {
  const { wasmModule, files, entry, values, nestedParameterOverrides, fonts, format, quality, separateObjects } = request;
  const lines = [];
  const module = await createOpenSCAD({
    noInitialRun: true,
    noExitRuntime: true,
    // Instantiate the module compiled once on the main thread: no download, no recompilation.
    instantiateWasm(imports, receive) {
      WebAssembly.instantiate(wasmModule, imports).then(instance => receive(instance, wasmModule));
      return {};
    },
    print: line => lines.push(String(line)),
    printErr: line => lines.push(String(line))
  });
  const FS = module.FS;
  const workspace = '/workspace';
  mkdirp(FS, workspace);
  for (const file of files) {
    if (file.path.includes('..') || file.path.startsWith('/')) throw new Error('Invalid file path in tool: ' + file.path);
    const target = workspace + '/' + file.path;
    mkdirp(FS, target.slice(0, target.lastIndexOf('/')));
    FS.writeFile(target, new Uint8Array(file.data));
  }
  if (fonts.length) {
    mkdirp(FS, '/fonts');
    fonts.forEach((font, index) => FS.writeFile(`/fonts/font-${index + 1}.ttf`, new Uint8Array(font.data)));
    FS.writeFile('/fonts/fonts.conf', '<?xml version="1.0" encoding="UTF-8"?><fontconfig><dir>/fonts</dir></fontconfig>');
    if (module.ENV) module.ENV.FONTCONFIG_FILE = '/fonts/fonts.conf';
  }

  const parameterSet = { ...values };
  const nestedArguments = Object.entries(nestedParameterOverrides || {}).flatMap(([name, value]) => {
    delete parameterSet[name];
    return ['-D', name + '=' + JSON.stringify(value)];
  });
  FS.writeFile(workspace + '/formforge-parameters.json', JSON.stringify({ fileFormatVersion: '1', parameterSets: { FormForge: parameterSet } }));
  const outputPath = workspace + '/formforge-output.' + format;
  const args = [
    '-o', outputPath,
    // Pinned explicitly: CGAL is 15–225× slower (rancangan.md §11).
    '--backend=manifold',
    ...(format === 'stl' ? ['--export-format', 'binstl'] : []),
    ...(separateObjects && format === '3mf' ? ['--enable=lazy-union'] : []),
    '-p', workspace + '/formforge-parameters.json', '-P', 'FormForge',
    ...nestedArguments,
    ...(quality ? ['-D', '$fn=0', '-D', '$fa=' + quality.fa, '-D', '$fs=' + quality.fs] : []),
    workspace + '/' + entry
  ];
  try {
    module.callMain(args);
  } catch (error) {
    if (error?.name !== 'ExitStatus' || error.status !== 0) {
      const diagnostics = lines.slice(-30).join('\n');
      throw new Error('OpenSCAD rendering failed: ' + describeError(error) + (diagnostics ? '\n\nOpenSCAD output:\n' + diagnostics : ''));
    }
  }
  const diagnostics = lines.join('\n');
  if (/current top level object is empty|geometr(?:y|ies) in cache:\s*0/i.test(diagnostics)) {
    throw new Error('The model produced no geometry. Check the parameter values and make sure the SCAD file generates a 3D object.\n\nOpenSCAD output:\n' + diagnostics.slice(-4000));
  }
  let output;
  try { output = FS.readFile(outputPath); } catch {
    throw new Error('OpenSCAD did not produce a ' + format.toUpperCase() + ' file. The model may contain no 3D geometry or use unsupported features.' + (lines.length ? '\n' + lines.slice(-20).join('\n') : ''));
  }
  if (!output.byteLength) throw new Error('OpenSCAD produced an empty mesh file.');
  const buffer = output.buffer.slice(output.byteOffset, output.byteOffset + output.byteLength);
  // echo("formforge-item", …) / echo("formforge-plates", n) messages, parsed by transform.js.
  const itemEchoes = lines.filter(line => line.startsWith('ECHO: "formforge-')).slice(0, 1000);
  return { output: buffer, itemEchoes };
}

self.onmessage = async ({ data }) => {
  try {
    const startedAt = performance.now();
    const result = await render(data);
    self.postMessage({ ...result, renderMs: performance.now() - startedAt }, [result.output]);
  } catch (error) {
    self.postMessage({ error: describeError(error) });
  }
};
