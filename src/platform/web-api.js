// window.formforge for the browser: same names and data shapes as the desktop preload.cjs, so the
// shared renderer runs unchanged where the platforms agree (rancangan.md §3).
import { parseItemEchoes, parsePlateCount, normalizeTransformPayload, MAX_EXPORT_PLATES } from '../shared/transform.js';
import { loadLibrary, getTool } from './library.js';
import { BUNDLED_FONTS } from './fonts.js';
import { readSettings, writeSettings } from './settings.js';
import { prepareRenderJob } from './render-job.js';
import { render, loadEngine, RenderTimeoutError } from './engine.js';
import { chooseTarget, writeTarget, sanitizeName, hasSaveDialog } from './export.js';
import { pickFiles } from './file-picker.js';
import { addToolAsset, addIconFiles, iconIndex, readIcon, forgetToolAssets } from './session-files.js';
import { importScadFile, readProjectFolder, suggestEntry, importProject, importUrl as importFromUrl, isSessionTool, deleteSessionTool, addCustomParameter } from './session-tools.js';
import { traceImage } from './trace.js';
import { validateHeightmapPng, LITHOPHANE_LIMITS } from '../shared/heightmap.js';
import { LITHOPHANE_IMAGE_PARAMETER } from '../shared/lithophane.js';
import { renderLithophane, isGeneratorTool } from './lithophane.js';

const MAX_PARAMETER_FILE_BYTES = 10 * 1024 * 1024;

export const PREVIEW_QUALITY = { fa: 20, fs: 2 };
export const EXPORT_QUALITY = { fa: 2, fs: 0.2 };
const FALLBACK_QUALITY = { fa: 4, fs: 0.5 };
const PREVIEW_TIMEOUT_MS = 120 * 1000;
const EXPORT_TIMEOUT_MS = 5 * 60 * 1000;
const EXPORT_FALLBACK_TIMEOUT_MS = 2 * 60 * 1000;

// S8: preview at export quality when this tool renders fast enough, so the preview is what gets printed.
const FAST_PREVIEW_MS = 150;
const MAX_EXPORT_PREVIEW_MS = 1200;
const previewStats = new Map(); // toolId → { exportQuality: boolean }

function previewQuality(job) {
  if (job.sourceSetsResolution) return null;
  return previewStats.get(job.tool.id)?.exportQuality ? EXPORT_QUALITY : PREVIEW_QUALITY;
}

function recordPreview(job, quality, result) {
  if (result.cached || !quality) return;
  const stats = previewStats.get(job.tool.id) || { exportQuality: false };
  if (quality === PREVIEW_QUALITY && result.renderMs < FAST_PREVIEW_MS) stats.exportQuality = true;
  else if (quality === EXPORT_QUALITY && result.renderMs > MAX_EXPORT_PREVIEW_MS) stats.exportQuality = false;
  previewStats.set(job.tool.id, stats);
}

async function renderExport(toolId, values, format) {
  const tool = await getTool(toolId);
  if (isGeneratorTool(tool)) {
    const result = await renderLithophane(tool, values, format, { channel: 'export', timeoutMs: EXPORT_TIMEOUT_MS });
    return { ...result, job: { tool, separateObjects: false }, quality: 'maximum' };
  }
  const job = await prepareRenderJob(toolId, values);
  try {
    const result = await render(job, format, EXPORT_QUALITY, { channel: 'export', timeoutMs: EXPORT_TIMEOUT_MS });
    return { ...result, job, quality: 'maximum' };
  } catch (error) {
    if (!(error instanceof RenderTimeoutError)) throw error;
    const result = await render(job, format, job.sourceSetsResolution ? null : FALLBACK_QUALITY, { channel: 'export', timeoutMs: EXPORT_FALLBACK_TIMEOUT_MS });
    return { ...result, job, quality: 'model' };
  }
}

const exportListeners = new Set();

const toolResult = async tool => ({ tool, tools: await loadLibrary() });
const pendingProjects = new Map(); // token → project folder waiting for its main file

async function startProjectImport(entries) {
  const project = await readProjectFolder(entries);
  if (project.scadFiles.length === 1) return toolResult(importProject(project, project.scadFiles[0].path));
  const token = crypto.randomUUID();
  pendingProjects.clear(); // only the latest folder can still be finished
  pendingProjects.set(token, project);
  return { chooseEntry: { token, folder: project.name, candidates: project.scadFiles, suggested: suggestEntry(project) } };
}

export const formforge = {
  async initialState() {
    return {
      tools: await loadLibrary(),
      settings: readSettings(),
      openscadAvailable: true,
      desktop: '',
      version: __APP_VERSION__,
      platform: 'web',
      // WEB: false in Firefox/Safari, where exports are downloads instead of a native save dialog.
      saveDialog: hasSaveDialog()
    };
  },
  async listFonts() {
    return BUNDLED_FONTS;
  },

  async render(toolId, values) {
    const tool = await getTool(toolId);
    if (isGeneratorTool(tool)) {
      const result = await renderLithophane(tool, values, '3mf', { preview: true, channel: 'preview', timeoutMs: PREVIEW_TIMEOUT_MS });
      return { mesh: result.output, bytes: result.output.byteLength, items: parseItemEchoes(result.itemEchoes), plates: null, quality: 'export', cached: false, info: result.info, renderMs: result.renderMs };
    }
    const job = await prepareRenderJob(toolId, values);
    const quality = previewQuality(job);
    // Preview as 3MF so model colors show in the viewer (same as the desktop).
    const result = await render(job, '3mf', quality, { channel: 'preview', timeoutMs: PREVIEW_TIMEOUT_MS });
    recordPreview(job, quality, result);
    return {
      mesh: result.output,
      bytes: result.output.byteLength,
      items: parseItemEchoes(result.itemEchoes),
      plates: parsePlateCount(result.itemEchoes),
      // 'model' = the tool sets its own $fn/$fa/$fs, which preview and export both keep.
      quality: quality === null ? 'model' : quality === EXPORT_QUALITY ? 'export' : 'preview',
      cached: Boolean(result.cached)
    };
  },

  async export(toolId, values, format, transformPayload, options = {}) {
    if (!['stl', '3mf'].includes(format)) throw new Error('Unsupported export format. Choose STL or 3MF.');
    if (options !== null && (typeof options !== 'object' || Array.isArray(options))) throw new Error('Invalid export options.');
    const perPlate = options?.perPlate === true;
    const transform = normalizeTransformPayload(transformPayload);
    const tool = await getTool(toolId);
    const plateParameter = (tool.parameters || []).find(parameter => parameter.name === 'export_plate' && parameter.type === 'number');
    if (perPlate && !plateParameter) throw new Error('This tool cannot export its plates separately (it has no export_plate parameter).');
    const baseName = sanitizeName(tool.name);
    // The save dialog opens first, while the click still counts as a user gesture.
    const target = await chooseTarget(perPlate ? `${baseName} - plates.zip` : `${baseName}.${format}`, perPlate ? 'zip' : format);
    if (!target) return { canceled: true };
    // mesh-transform pulls in the Buffer polyfill; load it only when exporting.
    const { applyMeshTransform, groupObjectsAsParts } = await import('../shared/mesh-transform.js');
    const finish = rendered => {
      const grouped = format === '3mf' && rendered.job.separateObjects ? groupObjectsAsParts(rendered.output, tool.name) : rendered.output;
      return new Uint8Array(applyMeshTransform(grouped, format, transform));
    };
    const mime = format === 'stl' ? 'model/stl' : 'model/3mf';
    if (!perPlate) {
      const rendered = await renderExport(toolId, values, format);
      const output = finish(rendered);
      const { download } = await writeTarget(target, output, mime);
      return { canceled: false, filePath: target.name, quality: rendered.quality, bytes: output.byteLength, download };
    }
    const { zipSync } = await import('fflate');
    const entries = {};
    const files = [];
    let quality = 'maximum';
    let count = 1;
    for (let plate = 1; plate <= count; plate++) {
      if (Number.isFinite(plateParameter.max) && plate > plateParameter.max) break;
      exportListeners.forEach(listener => listener({ plate, count: plate === 1 ? null : count }));
      const rendered = await renderExport(toolId, { ...values, export_plate: plate }, format);
      if (plate === 1) count = Math.min(parsePlateCount(rendered.itemEchoes) || 1, MAX_EXPORT_PLATES);
      if (rendered.quality !== 'maximum') quality = rendered.quality;
      const output = finish(rendered);
      const name = `${baseName} - plate ${plate}.${format}`;
      entries[name] = [output, { level: 0 }];
      files.push({ filePath: name, bytes: output.byteLength });
    }
    const zip = zipSync(entries);
    const { download } = await writeTarget(target, zip, 'application/zip');
    return { canceled: false, files, filePath: target.name, quality, bytes: zip.byteLength, download };
  },
  onExportProgress(callback) {
    exportListeners.add(callback);
    return () => exportListeners.delete(callback);
  },

  async saveSettings(settings) {
    return writeSettings(settings);
  },
  async chooseExportDirectory() {
    return '';
  },
  async openExportDirectory() {},

  // Images and icons (tools:choose-parameter-file, save-icon-asset, save-heightmap-asset, trace-image and
  // icons:* in the desktop main.cjs). Everything stays in this tab's memory (session-files.js).
  async chooseParameterFile(kind) {
    if (kind !== 'icon' && kind !== 'relief') throw new Error('Unsupported parameter file type.');
    const allowedExtensions = kind === 'relief' ? ['.png', '.jpg', '.jpeg', '.webp'] : ['.svg', '.png', '.jpg', '.jpeg', '.webp'];
    const [file] = await pickFiles({ accept: allowedExtensions.join(',') });
    if (!file) return null;
    if (file.size > MAX_PARAMETER_FILE_BYTES) throw new Error('The selected file exceeds the 10 MB limit.');
    const extension = (file.name.match(/\.[^.]+$/)?.[0] || '').toLowerCase();
    if (!allowedExtensions.includes(extension)) throw new Error('The selected file type is not supported.');
    return { fileName: file.name, extension, data: new Uint8Array(await file.arrayBuffer()) };
  },
  async saveIconAsset(toolId, parameterName, svg) {
    if (!['icon_left_file', 'icon_right_file', 'decorative_layers'].includes(parameterName)
      || typeof svg !== 'string'
      || new TextEncoder().encode(svg).length > 5 * 1024 * 1024
      || !/<svg(?:\s|>)/i.test(svg)) {
      throw new Error('The selected icon could not be saved as a valid SVG.');
    }
    const tool = await getTool(toolId);
    const parameter = tool.parameters.find(item => item.name === parameterName);
    if (!parameter || (parameter.type !== 'string' && !(parameterName === 'decorative_layers' && parameter.type === 'nested-tree'))) {
      throw new Error('The selected icon parameter is not available.');
    }
    return { reference: addToolAsset(toolId, '.svg', new TextEncoder().encode(svg)) };
  },
  async saveHeightmapAsset(toolId, parameterName, png) {
    if (parameterName !== 'relief_image_file' && parameterName !== LITHOPHANE_IMAGE_PARAMETER) throw new Error('The selected relief parameter is not available.');
    // Lithophane images feed the JavaScript generator, which handles more pixels than surface().
    const { data } = validateHeightmapPng(png, parameterName === LITHOPHANE_IMAGE_PARAMETER ? LITHOPHANE_LIMITS : undefined);
    const tool = await getTool(toolId);
    const parameter = tool.parameters.find(item => item.name === parameterName);
    if (!parameter || parameter.type !== 'string') throw new Error('The selected relief parameter is not available.');
    return { reference: addToolAsset(toolId, '.png', new Uint8Array(data)) };
  },
  async traceImage(rgba, width, height, options) {
    return traceImage(rgba, width, height, options);
  },
  async iconIndex() {
    return iconIndex();
  },
  async readIcons(items) {
    if (!Array.isArray(items) || items.length > 200) throw new Error('Too many icons were requested at once.');
    return Promise.all(items.map(item => readIcon(item?.pack, item?.path).catch(() => null)));
  },
  async readIcon(pack, path) {
    return readIcon(pack, path);
  },
  // The desktop opens its icon folder; the web version asks for a folder of SVG files instead.
  async openIconFolder() {
    const files = await pickFiles({ directory: true });
    return { added: addIconFiles(files) };
  },

  // Importing tools (tools:import-* in the desktop main.cjs). Imported tools stay in this tab's memory only.
  async importFile() {
    const [file] = await pickFiles({ accept: '.scad' });
    if (!file) return null;
    return toolResult(await importScadFile(file));
  },
  // A folder with one .scad file is imported right away. With several, the result asks the renderer to
  // let the person choose the main file: { chooseEntry: { token, folder, candidates, suggested } }, then
  // importProjectEntry(token, path) finishes the import.
  async importProject() {
    const files = await pickFiles({ directory: true });
    if (!files.length) return null;
    return startProjectImport(files.map(file => ({ path: file.webkitRelativePath || file.name, file })));
  },
  async importProjectEntry(token, entry) {
    const project = pendingProjects.get(token);
    if (!project) throw new Error('The selected folder is no longer available. Choose it again.');
    const tool = importProject(project, entry);
    pendingProjects.delete(token);
    return toolResult(tool);
  },
  // Files or a folder dropped onto the window: entries [{ path, file }] (src/web/drop-import.js).
  async importDropped(entries) {
    if (!Array.isArray(entries) || !entries.length) return null;
    const scad = entries.filter(entry => /\.scad$/i.test(entry.file?.name || ''));
    if (!scad.length) throw new Error('Drop an OpenSCAD file (.scad) or a project folder.');
    const single = entries.length === 1 && !String(entries[0].path).includes('/');
    if (single) return toolResult(await importScadFile(entries[0].file));
    return startProjectImport(entries);
  },
  async importUrl(url) {
    return toolResult(await importFromUrl(url));
  },
  async deleteTool(toolId) {
    const tool = await getTool(toolId);
    if (isGeneratorTool(tool)) throw new Error('The built-in Lithophane generator cannot be deleted.');
    if (!isSessionTool(toolId)) throw new Error('Built-in tools cannot be deleted.');
    deleteSessionTool(toolId);
    forgetToolAssets(toolId);
    previewStats.delete(toolId);
    return { deleted: true, tools: await loadLibrary() };
  },
  // Kept for this session; applies to built-in tools too, like the desktop.
  async addParameter(toolId, parameter) {
    addCustomParameter(await getTool(toolId), parameter);
    return toolResult(await getTool(toolId));
  }
};

// Start downloading the engine once the page is idle, so the first render does not wait for it.
export function warmUpEngine() {
  const start = () => loadEngine().catch(() => {});
  if ('requestIdleCallback' in window) requestIdleCallback(start, { timeout: 1500 });
  else setTimeout(start, 300);
}
