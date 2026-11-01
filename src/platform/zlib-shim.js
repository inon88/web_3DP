// The subset of node:zlib used by the synced mesh-transform module, backed by fflate.
import { Buffer } from 'buffer';
import { inflateSync, deflateSync } from 'fflate';

export const zlib = {
  inflateRawSync: data => Buffer.from(inflateSync(data)),
  deflateRawSync: (data, options = {}) => Buffer.from(deflateSync(data, { level: options.level ?? 6 }))
  // No crc32: mesh-transform falls back to its own table.
};
