// Entry: install the browser implementation of window.formforge, then start the shared UI.
import './styles.css';
import './web.css';
import { formforge, warmUpEngine } from './platform/web-api.js';
import { engineEvents } from './platform/engine.js';
import { forgetStoredData } from './platform/session-store.js';

forgetStoredData();
Object.defineProperty(window, 'formforge', { value: Object.freeze(formforge), writable: false, configurable: false });
window.bonastudioEngine = engineEvents;
warmUpEngine();
await import('./renderer.js');
const { startFontPreview } = await import('./web/font-preview.js');
startFontPreview();
