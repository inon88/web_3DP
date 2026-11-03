// Validates a render request before it reaches OpenSCAD. Ported from prepareRenderJob() and
// validateNestedTree() in the desktop main.cjs; keep the two in step.
import { NESTED_TREE_ICONS, isFontParameterName } from '../shared/parameters.js';
import { exportsSeparateObjects } from '../shared/scad-assets.js';
import { getTool, toolFiles, toolSource } from './library.js';
import { findFont } from './fonts.js';
import { referencedToolAssets } from './session-files.js';

export function validateNestedTree(value, maxDepth, label, icons = NESTED_TREE_ICONS) {
  if (!Array.isArray(value) || value.length < 1 || value.length > 200) throw new Error(label + ' must contain between 1 and 200 elements.');
  const fonts = new Set();
  let nodeCount = 0;
  const encodeList = (nodes, depth, prefix = '') => {
    if (!nodes.length) return [];
    if (depth > maxDepth) throw new Error(label + ' exceeds the maximum nesting depth of ' + maxDepth + '.');
    return nodes.map((node, index) => {
      const elementName = 'element ' + prefix + (index + 1);
      nodeCount++;
      if (nodeCount > 200) throw new Error(label + ' cannot contain more than 200 elements.');
      if (!node || typeof node !== 'object' || Array.isArray(node)) throw new Error(label + ' contains an invalid element.');
      const { type, text, font, icon, svgPath, x, y, size, thickness, bold, placement, overlap, color, children } = node;
      const rotation = node.rotation ?? 0;
      if (!['Text', 'SVG', 'Icon'].includes(type)) throw new Error(label + ' has an unsupported element type.');
      if (typeof color !== 'string' || !/^#[0-9a-f]{6}$/i.test(color)) throw new Error(label + ' has an invalid color. Choose a color from the element palette.');
      for (const [key, number, min, max, unit] of [['X position', x, -128, 128, 'mm'], ['Y position', y, -128, 128, 'mm'], ['size', size, 1, 210, 'mm'], ['thickness', thickness, 0.4, 20, 'mm'], ['bold', bold, 0, 8, 'mm'], ['inset depth', overlap, 0, 20, 'mm'], ['rotation', rotation, -180, 180, '°']]) {
        if (!Number.isFinite(number) || number < min || number > max) {
          throw new Error(label + ' › ' + elementName + ': ' + key + ' must be between ' + min + ' and ' + max + ' ' + unit + '.');
        }
      }
      if (!['Above', 'Inset'].includes(placement)) throw new Error(label + ' has an invalid Z placement.');
      if (!Array.isArray(children)) throw new Error(label + ' contains an invalid nested element list.');
      if (type === 'Text') {
        if (typeof text !== 'string' || text.length > 500) throw new Error(label + ' has invalid text.');
        if (typeof font !== 'string' || font.length > 250) throw new Error(label + ' has an invalid font.');
        fonts.add(font);
      }
      if (type === 'Icon' && !icons.includes(icon)) throw new Error(label + ' has an unsupported icon.');
      if (type === 'SVG' && (typeof svgPath !== 'string' || (svgPath && (!/^user-assets\/[A-Za-z0-9._-]+\.svg$/i.test(svgPath) || svgPath.includes('..'))))) throw new Error(label + ' has an invalid SVG path. Choose an SVG using the file picker.');
      return [type, text || '', font || '', icon || icons[0], svgPath || '', x, y, size, thickness, bold, placement, overlap, encodeList(children, depth + 1, prefix + (index + 1) + '.'), color, rotation];
    });
  };
  return { encoded: encodeList(value, 1), fonts: [...fonts] };
}

function requireFont(name, what) {
  const font = findFont(name);
  if (!font) throw new Error(`The font chosen for ${what} is not available in the web version. Choose a font from the list (Liberation or Google Fonts).`);
  return font;
}

// Checks every value against the tool's parameters (type, range, options); defaults fill the gaps.
// Shared with the Lithophane generator (platform/lithophane.js).
export function validateParameterValues(tool, values) {
  const params = {};
  const nestedParameterOverrides = {};
  let nestedFontNames = [];
  for (const parameter of tool.parameters || []) {
    const label = parameter.label || parameter.name;
    const value = Object.hasOwn(values || {}, parameter.name) ? values[parameter.name] : parameter.default;
    if (parameter.type === 'nested-tree') {
      const { encoded, fonts } = validateNestedTree(value, parameter.maxDepth || 4, label, parameter.icons?.length ? parameter.icons : NESTED_TREE_ICONS);
      params[parameter.name] = encoded;
      nestedParameterOverrides[parameter.name] = encoded;
      nestedFontNames = fonts;
      continue;
    } else if (parameter.type === 'number') {
      if (!Number.isFinite(value)) throw new Error('Parameter "' + label + '" must be a number.');
      if ((Number.isFinite(parameter.min) && value < parameter.min) || (Number.isFinite(parameter.max) && value > parameter.max)) {
        throw new Error('Parameter "' + label + '" is outside the allowed range.');
      }
    } else if (parameter.type === 'boolean' && typeof value !== 'boolean') {
      throw new Error('Parameter "' + label + '" must be a true/false value.');
    } else if (parameter.type === 'vector' && (!Array.isArray(value) || value.some(item => !Number.isFinite(item)))) {
      throw new Error('Parameter "' + label + '" must be a numeric vector.');
    } else if (parameter.type === 'string' && (typeof value !== 'string' || value.length > 10000)) {
      throw new Error('Parameter "' + label + '" is invalid.');
    }
    if (parameter.options && !parameter.options.includes(value)) {
      throw new Error('Parameter "' + label + '" is not one of the available options.');
    }
    params[parameter.name] = value;
  }
  return { params, nestedParameterOverrides, nestedFontNames };
}

export async function prepareRenderJob(toolId, values) {
  const tool = await getTool(toolId);
  const source = await toolSource(tool);
  const { params, nestedParameterOverrides, nestedFontNames } = validateParameterValues(tool, values);

  // Font parameters are rewritten to the bundled font's exact name, so fontconfig finds it.
  const fonts = new Map();
  for (const parameter of tool.parameters || []) {
    if (parameter.type !== 'string' || !isFontParameterName(parameter.name) || !params[parameter.name]) continue;
    const font = requireFont(params[parameter.name], '"' + (parameter.label || parameter.name) + '"');
    params[parameter.name] = font.name;
    fonts.set(font.name, font);
  }
  for (const name of nestedFontNames) {
    const font = requireFont(name, 'a nested text element');
    fonts.set(font.name, font);
  }
  // Encoded nested elements: [type, text, font, …, children (index 12), …].
  const renameFonts = list => list.forEach(element => {
    if (element[0] === 'Text') element[2] = findFont(element[2]).name;
    renameFonts(element[12]);
  });
  for (const encoded of Object.values(nestedParameterOverrides)) renameFonts(encoded);

  return {
    tool,
    entry: tool.entry,
    // Images added in this session (icons, traced images, reliefs) sit next to the tool's own files.
    files: [...await toolFiles(tool), ...referencedToolAssets(tool.id, params)],
    params,
    nestedParameterOverrides,
    fonts: [...fonts.values()],
    sourceSetsResolution: /\$(?:fn|fa|fs)\s*=/m.test(source),
    separateObjects: exportsSeparateObjects(source)
  };
}
