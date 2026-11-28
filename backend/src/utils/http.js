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

export async function readJsonBody(req, maxBytes = 1024 * 1024) {
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

  const raw = Buffer.concat(chunks).toString('utf8').trim();
  if (!raw) return {};

  try {
    return JSON.parse(raw);
  } catch {
    const err = new Error('Invalid JSON payload');
    err.statusCode = 400;
    throw err;
  }
}
