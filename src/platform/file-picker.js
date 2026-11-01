// Opens the browser's file dialog. Must be called from a click (user activation), like the desktop dialogs.
// Resolves with the chosen File list, or [] when the dialog is closed without a choice.
export function pickFiles({ accept = '', multiple = false, directory = false } = {}) {
  return new Promise(resolve => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = accept;
    input.multiple = multiple;
    if (directory) input.webkitdirectory = true;
    input.hidden = true;
    const done = files => { input.remove(); resolve(files); };
    input.addEventListener('change', () => done([...(input.files || [])]), { once: true });
    input.addEventListener('cancel', () => done([]), { once: true });
    document.body.append(input);
    input.click();
  });
}
