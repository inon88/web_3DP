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
  if (hasSaveDialog()) {
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

export const hasSaveDialog = () => typeof window.showSaveFilePicker === 'function';

// A download started from script only works reliably while the click that asked for it still counts as a
// user gesture (Safari blocks it afterwards). Exports render first, often for longer than that.
// Browsers without navigator.userActivation get the automatic download.
const gestureActive = () => !navigator.userActivation || navigator.userActivation.isActive;

export function clickDownload(url, name) {
  const link = document.createElement('a');
  link.href = url;
  link.download = name;
  link.rel = 'noopener';
  link.hidden = true;
  document.body.append(link);
  link.click();
  link.remove();
}

// Returns { download: null } when the file was saved or its download started, or
// { download: { url, name, size } } when the person has to start the download with a click of their own
// (the renderer shows a Download button; it revokes the URL when that dialog closes).
export async function writeTarget(target, bytes, mime) {
  if (target.handle) {
    const writable = await target.handle.createWritable();
    await writable.write(bytes);
    await writable.close();
    return { download: null };
  }
  const url = URL.createObjectURL(new Blob([bytes], { type: mime }));
  if (!gestureActive()) return { download: { url, name: target.name, size: bytes.byteLength } };
  clickDownload(url, target.name);
  // Firefox and Safari read the blob after the click returns; keep it long enough for slow disks.
  setTimeout(() => URL.revokeObjectURL(url), 60000);
  return { download: null };
}
