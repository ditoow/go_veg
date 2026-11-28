export function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-api-key',
  });
  res.end(body);
}

/**
 * Matches the Flutter FE's `ApiResponse<T>` envelope: { success, message, data }.
 */
export function ok(res, message, data = null, statusCode = 200) {
  return sendJson(res, statusCode, {
    success: true,
    message,
    data,
  });
}

export function fail(res, message, statusCode = 400, data = null) {
  return sendJson(res, statusCode, {
    success: false,
    message,
    data,
  });
}

function parseJsonText(rawText) {
  const trimmed = rawText.trim();
  if (!trimmed) return {};
  try {
    return JSON.parse(trimmed);
  } catch {
    const err = new Error('Invalid JSON payload');
    err.statusCode = 400;
    throw err;
  }
}

export async function readJsonBody(req, maxBytes = 1024 * 1024) {
  // Vercel's Node.js runtime may pre-parse req.body and consume the request stream.
  if (req.body !== undefined) {
    if (typeof req.body === 'string') return parseJsonText(req.body);
    if (Buffer.isBuffer(req.body)) return parseJsonText(req.body.toString('utf8'));
    if (typeof req.body === 'object' && req.body !== null) return req.body;
  }

  const chunks = [];
  let size = 0;

  for await (const chunk of req) {
    size += chunk.length;
    if (size > maxBytes) {
      const err = new Error('Request body too large');
      err.statusCode = 413;
      throw err;
    }
    chunks.push(chunk);
  }

  return parseJsonText(Buffer.concat(chunks).toString('utf8'));
}
