// Saving exported files: the native save dialog where the browser has the File System Access API
// (Chrome/Edge), a regular download elsewhere (Firefox/Safari).
const TYPES = {
  stl: { description: 'STL mesh', accept: { 'model/stl': ['.stl'] } },
  '3mf': { description: '3MF model', accept: { 'model/3mf': ['.3mf'] } },
  zip: { description: 'ZIP archive', accept: { 'application/zip': ['.zip'] } }
};

export function sanitizeName(name) {
  return String(name || 'model').replace(/[<>:"/\\|?*\x00-\x1f]/g, '-').trim().slice(0, 80) || 'model';
}

// Must run right after the user's click (the save dialog needs a fresh user gesture), before rendering.
// Returns null when the user cancels.
export async function chooseTarget(fileName, kind) {
  if (typeof window.showSaveFilePicker === 'function') {
    try {
      const handle = await window.showSaveFilePicker({ suggestedName: fileName, types: [TYPES[kind]] });
      return { handle, name: handle.name };
    } catch (error) {
      if (error?.name === 'AbortError') return null;
      // SecurityError (gesture expired, cross-origin frame…): fall back to a download.
    }
  }
  return { handle: null, name: fileName };
}

export async function writeTarget(target, bytes, mime) {
  if (target.handle) {
    const writable = await target.handle.createWritable();
    await writable.write(bytes);
    await writable.close();
    return;
  }
  const url = URL.createObjectURL(new Blob([bytes], { type: mime }));
  const link = document.createElement('a');
  link.href = url;
  link.download = target.name;
  link.rel = 'noopener';
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 30000);
}
