// A one-line description of a tool for the gallery: the first sentence of the comment block at the top of
// its .scad file. Used by scripts/build-library.mjs (built-in tools) and session-tools.js (imports).
const MAX_LENGTH = 140;

export function scadDescription(source) {
  const lines = [];
  for (const raw of String(source || '').replace(/\r\n?/g, '\n').split('\n')) {
    const line = raw.trim();
    if (!line && !lines.length) continue;
    const comment = line.match(/^\/\/\s?(.*)$/);
    if (!comment) break;
    const text = comment[1].trim();
    if (!text) {
      if (lines.length) break; // the first paragraph only
      continue;
    }
    if (text.startsWith('@')) continue; // // @formforge-… directives
    lines.push(text);
  }
  // A line that ends without punctuation, followed by one starting with a capital, ends a sentence too
  // ("Parametric name keychain" / "Recreated from …").
  let text = '';
  for (const [index, line] of lines.entries()) {
    text += (index ? ' ' : '') + line;
    const next = lines[index + 1];
    if (next && !/[.,;:!?—–(-]$/.test(line) && /^[A-Z]/.test(next)) { text += '.'; break; }
  }
  const sentence = (text.match(/^.*?[.!?](?=\s|$)/)?.[0] || text).trim();
  if (sentence.length <= MAX_LENGTH) return sentence;
  return sentence.slice(0, MAX_LENGTH).replace(/\s+\S*$/, '') + '…';
}
