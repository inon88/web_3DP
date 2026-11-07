// WEB: the library gallery (rancangan.md §5): one card per tool with its picture, name and description.
// It opens at start-up and from the Browse button; choosing a card switches to that tool.
const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, character => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
})[character]);

const PLACEHOLDER = '<svg viewBox="0 0 64 64" aria-hidden="true"><path d="m32 7 23 13v25L32 58 9 45V20L32 7Z"/><path d="m9 20 23 14 23-14M32 34v24"/></svg>';

function card(tool, { activeId, sourceLabel }) {
  const parameters = (tool.parameters || []).filter(parameter => parameter.group !== 'Transform').length;
  const picture = tool.thumbnail
    // The picture is decorative; a missing one falls back to the placeholder (onerror in bindGallery).
    ? `<img src="${escapeHtml(tool.thumbnail)}" alt="" loading="lazy" decoding="async" width="320" height="240">`
    : '';
  return `<button class="gallery-card${tool.id === activeId ? ' is-active' : ''}" type="button" data-gallery-tool="${escapeHtml(tool.id)}"
      data-search="${escapeHtml(`${tool.name} ${tool.description || ''} ${sourceLabel(tool)}`.toLowerCase())}">
    <span class="gallery-picture">${picture}<span class="gallery-placeholder"${picture ? ' hidden' : ''}>${PLACEHOLDER}</span></span>
    <span class="gallery-text">
      <strong>${escapeHtml(tool.name)}</strong>
      ${tool.description ? `<small>${escapeHtml(tool.description)}</small>` : ''}
      <span class="gallery-meta">${escapeHtml(sourceLabel(tool))}${parameters ? ` · ${parameters} parameter${parameters === 1 ? '' : 's'}` : ''}</span>
    </span>
  </button>`;
}

// tools: built-in generator first, then the library and this session's imports (in that order).
export function galleryMarkup(tools, options) {
  return `
    <div class="gallery-toolbar">
      <label class="gallery-search"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="6"/><path d="m20 20-4.5-4.5"/></svg>
        <input id="gallerySearch" type="search" placeholder="Search tools" aria-label="Search tools" autocomplete="off"></label>
      <button class="button button-secondary button-compact" type="button" data-gallery-add>
        <svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Add your own</button>
    </div>
    <div class="gallery-grid" role="list">${tools.map(tool => card(tool, options)).join('')}</div>
    <p id="galleryEmpty" class="gallery-empty" hidden>No tools match your search.</p>`;
}

export function bindGallery(container, { onChoose, onAdd }) {
  container.querySelectorAll('.gallery-picture img').forEach(image => image.addEventListener('error', () => {
    image.nextElementSibling.hidden = false;
    image.remove();
  }, { once: true }));
  container.querySelectorAll('[data-gallery-tool]').forEach(button => button.addEventListener('click', () => onChoose(button.dataset.galleryTool)));
  container.querySelector('[data-gallery-add]')?.addEventListener('click', onAdd);
  const search = container.querySelector('#gallerySearch');
  search?.addEventListener('input', () => {
    const words = search.value.toLowerCase().split(/\s+/).filter(Boolean);
    let shown = 0;
    container.querySelectorAll('[data-gallery-tool]').forEach(button => {
      const match = words.every(word => button.dataset.search.includes(word));
      button.hidden = !match;
      if (match) shown++;
    });
    container.querySelector('#galleryEmpty').hidden = shown > 0;
  });
  // Arrow keys move between cards, as in a grid of tiles.
  container.querySelector('.gallery-grid')?.addEventListener('keydown', event => {
    if (!['ArrowRight', 'ArrowLeft', 'ArrowDown', 'ArrowUp'].includes(event.key)) return;
    const cards = [...container.querySelectorAll('[data-gallery-tool]:not([hidden])')];
    const index = cards.indexOf(document.activeElement);
    if (index < 0) return;
    const columns = Math.max(1, Math.round(container.querySelector('.gallery-grid').clientWidth / cards[0].offsetWidth));
    const step = { ArrowRight: 1, ArrowLeft: -1, ArrowDown: columns, ArrowUp: -columns }[event.key];
    const next = cards[Math.min(cards.length - 1, Math.max(0, index + step))];
    event.preventDefault();
    next?.focus();
  });
}
