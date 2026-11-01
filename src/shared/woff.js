// WOFF 1.0 → TrueType/OpenType (sfnt), plus the fix that lets OpenSCAD WASM read unhinted fonts.
// WOFF stores the same tables, each optionally zlib-compressed, so the conversion is lossless.
// https://www.w3.org/TR/WOFF/
import { unzlibSync } from 'fflate';
import { fontSupportsOpenScadWasm } from './font-name.js';

const tagNumber = text => [...text].reduce((value, char) => value * 256 + char.charCodeAt(0), 0);

export function isWoff(bytes) {
  return bytes.length >= 4 && bytes[0] === 0x77 && bytes[1] === 0x4f && bytes[2] === 0x46 && bytes[3] === 0x46; // 'wOFF'
}

// tables: [{ tag, checksum, data }] → sfnt bytes with tables sorted by tag and 4-byte aligned.
function writeSfnt(flavor, tables) {
  tables = [...tables].sort((a, b) => a.tag - b.tag);
  const count = tables.length;
  const headerLength = 12 + count * 16;
  const total = tables.reduce((sum, table) => sum + ((table.data.length + 3) & ~3), headerLength);
  const output = new Uint8Array(total);
  const out = new DataView(output.buffer);
  let power = 1;
  let log = 0;
  while (power * 2 <= count) { power *= 2; log++; }
  out.setUint32(0, flavor);
  out.setUint16(4, count);
  out.setUint16(6, power * 16);
  out.setUint16(8, log);
  out.setUint16(10, count * 16 - power * 16);
  let position = headerLength;
  tables.forEach((table, index) => {
    const record = 12 + index * 16;
    out.setUint32(record, table.tag);
    out.setUint32(record + 4, table.checksum);
    out.setUint32(record + 8, position);
    out.setUint32(record + 12, table.data.length);
    output.set(table.data, position);
    position += (table.data.length + 3) & ~3;
  });
  return output;
}

function readSfnt(bytes) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const count = view.getUint16(4);
  if (12 + count * 16 > bytes.length) throw new Error('Damaged font table directory.');
  const tables = [];
  for (let index = 0; index < count; index++) {
    const record = 12 + index * 16;
    const offset = view.getUint32(record + 8);
    const length = view.getUint32(record + 12);
    if (offset + length > bytes.length) throw new Error('Damaged font table.');
    tables.push({ tag: view.getUint32(record), checksum: view.getUint32(record + 4), data: bytes.subarray(offset, offset + length) });
  }
  return { flavor: view.getUint32(0), tables };
}

export function woffToSfnt(input) {
  const bytes = input instanceof Uint8Array ? input : new Uint8Array(input);
  if (!isWoff(bytes) || bytes.length < 44) throw new Error('Not a WOFF font.');
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const numTables = view.getUint16(12);
  if (!numTables || 44 + numTables * 20 > bytes.length) throw new Error('Damaged WOFF table directory.');
  const tables = [];
  for (let index = 0; index < numTables; index++) {
    const entry = 44 + index * 20;
    const offset = view.getUint32(entry + 4);
    const compLength = view.getUint32(entry + 8);
    const origLength = view.getUint32(entry + 12);
    if (offset + compLength > bytes.length) throw new Error('Damaged WOFF table.');
    const stored = bytes.subarray(offset, offset + compLength);
    const data = compLength < origLength ? unzlibSync(stored) : stored;
    if (data.length !== origLength) throw new Error('WOFF table has the wrong size after decompression.');
    tables.push({ tag: view.getUint32(entry), checksum: view.getUint32(entry + 16), data });
  }
  return writeSfnt(view.getUint32(4), tables);
}

// OpenSCAD WASM traps ("function signature mismatch") on TrueType fonts without a font program:
// FreeType then runs its auto-hinter, which is broken in that build. A font program that does nothing
// (PUSHB[0] 0, POP) makes FreeType use the bytecode interpreter instead; outlines are unchanged.
// Verified in the engine with Dancing Script, Poppins, Playfair Display, Caveat and Oswald.
const NO_OP_FONT_PROGRAM = new Uint8Array([0xb0, 0x00, 0x21]);

export function makeOpenScadCompatible(sfnt) {
  if (fontSupportsOpenScadWasm(sfnt)) return sfnt;
  const { flavor, tables } = readSfnt(sfnt);
  const fpgm = tagNumber('fpgm');
  const fixed = writeSfnt(flavor, [...tables.filter(table => table.tag !== fpgm), { tag: fpgm, checksum: 0, data: NO_OP_FONT_PROGRAM }]);
  if (!fontSupportsOpenScadWasm(fixed)) throw new Error('This font cannot be used by OpenSCAD.');
  return fixed;
}

// WOFF or TTF/OTF bytes → bytes OpenSCAD WASM can load.
export function fontForOpenScad(input) {
  const bytes = input instanceof Uint8Array ? input : new Uint8Array(input);
  return makeOpenScadCompatible(isWoff(bytes) ? woffToSfnt(bytes) : bytes);
}
