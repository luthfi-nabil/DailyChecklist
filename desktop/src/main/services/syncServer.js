const http = require('node:http');
const crypto = require('node:crypto');
const EventEmitter = require('node:events');

class SyncServer extends EventEmitter {
  constructor(db, repository) {
    super();
    this.db = db;
    this.repository = repository;
    this.server = null;
    this.port = 47800;
    this.failedPairAttempts = [];
  }

  start(preferredPort = 47800) {
    return new Promise((resolve, reject) => {
      let currentPort = preferredPort;

      const tryListen = () => {
        this.server = http.createServer((req, res) => this.handleRequest(req, res));

        this.server.once('error', (err) => {
          if (err.code === 'EADDRINUSE' && currentPort < 47810) {
            currentPort++;
            tryListen();
          } else {
            reject(err);
          }
        });

        this.server.listen(currentPort, '0.0.0.0', () => {
          this.port = this.server.address().port;
          resolve(this.port);
        });
      };

      tryListen();
    });
  }

  stop() {
    return new Promise((resolve) => {
      if (this.server) {
        const srv = this.server;
        this.server = null;
        if (typeof srv.closeAllConnections === 'function') {
          srv.closeAllConnections();
        }
        srv.close(() => resolve());
      } else {
        resolve();
      }
    });
  }

  sendJson(res, statusCode, data) {
    const json = JSON.stringify(data);
    res.writeHead(statusCode, {
      'Content-Type': 'application/json; charset=utf-8',
      'Content-Length': Buffer.byteLength(json),
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    });
    res.end(json);
  }

  parseBody(req) {
    return new Promise((resolve, reject) => {
      let body = '';
      req.on('data', chunk => {
        body += chunk;
        if (body.length > 5 * 1024 * 1024) {
          reject(new Error('Payload too large'));
        }
      });
      req.on('end', () => {
        try {
          resolve(body ? JSON.parse(body) : {});
        } catch (e) {
          reject(new Error('Invalid JSON'));
        }
      });
      req.on('error', reject);
    });
  }

  async handleRequest(req, res) {
    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
      });
      res.end();
      return;
    }

    const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

    try {
      if (req.method === 'GET' && url.pathname === '/api/v1/ping') {
        const pairedDevices = JSON.parse(this.db.getMeta('paired_devices') || '[]');
        this.sendJson(res, 200, {
          app: 'langkah-kecil',
          v: 1,
          device_id: this.db.getMeta('device_id'),
          device_name: this.db.getMeta('device_name') || 'Desktop',
          paired: pairedDevices.length > 0
        });
        return;
      }

      if (req.method === 'POST' && url.pathname === '/api/v1/pair') {
        const now = Date.now();
        this.failedPairAttempts = this.failedPairAttempts.filter(t => now - t < 60000);
        if (this.failedPairAttempts.length >= 5) {
          this.repository.logAudit({
            source: 'Desktop',
            category: 'auth',
            level: 'warn',
            endpoint: 'POST /api/v1/pair',
            statusCode: 429,
            errorCode: 'too_many_attempts',
            message: 'Terlalu banyak percobaan kode pairing gagal (dibatasi 5/menit).',
            details: { remoteAddress: req.socket?.remoteAddress || null }
          });
          this.sendJson(res, 429, { error: 'too_many_attempts' });
          return;
        }

        const body = await this.parseBody(req);
        const pairingCode = this.db.getMeta('pairing_code');

        if (!body.code || String(body.code).trim() !== String(pairingCode).trim()) {
          this.failedPairAttempts.push(now);
          this.repository.logAudit({
            source: 'Desktop',
            category: 'auth',
            level: 'warn',
            endpoint: 'POST /api/v1/pair',
            statusCode: 403,
            errorCode: 'bad_code',
            message: 'Kode pairing tidak cocok.',
            details: { device_id: body.device_id || null, device_name: body.device_name || null }
          });
          this.sendJson(res, 403, { error: 'bad_code' });
          return;
        }

        const token = crypto.randomBytes(24).toString('hex');
        const pairedDevices = JSON.parse(this.db.getMeta('paired_devices') || '[]');
        const device_id = body.device_id || crypto.randomUUID();
        const device_name = body.device_name || 'Ponsel';
        const ttlDays = Math.min(7, Math.max(3, parseInt(this.db.getMeta('token_ttl_days') || '7', 10) || 7));
        const expires_at = now + ttlDays * 24 * 60 * 60 * 1000;

        const idx = pairedDevices.findIndex(d => d.device_id === device_id);
        const deviceInfo = { device_id, device_name, token, paired_at: now, expires_at };
        if (idx >= 0) {
          pairedDevices[idx] = deviceInfo;
        } else {
          pairedDevices.push(deviceInfo);
        }

        this.db.setMeta('paired_devices', JSON.stringify(pairedDevices));
        const newCode = Math.floor(100000 + Math.random() * 900000).toString();
        this.db.setMeta('pairing_code', newCode);

        this.emit('device_paired', { device_id, device_name, paired_at: now, expires_at });
        this.sendJson(res, 200, { token, expires_at });
        return;
      }

      if (req.method === 'POST' && url.pathname === '/api/v1/sync') {
        const auth = req.headers['authorization'];
        if (!auth || !auth.startsWith('Bearer ')) {
          this.repository.logAudit({
            source: 'Desktop',
            category: 'auth',
            level: 'warn',
            endpoint: 'POST /api/v1/sync',
            statusCode: 401,
            errorCode: 'unauthorized',
            message: 'Header Authorization Bearer tidak ditemukan pada permintaan sinkronisasi.'
          });
          this.sendJson(res, 401, { error: 'unauthorized' });
          return;
        }

        const token = auth.slice(7).trim();
        const pairedDevices = JSON.parse(this.db.getMeta('paired_devices') || '[]');
        const matched = pairedDevices.find(d => d.token === token);
        if (!matched) {
          this.repository.logAudit({
            source: 'Desktop',
            category: 'auth',
            level: 'warn',
            endpoint: 'POST /api/v1/sync',
            statusCode: 401,
            errorCode: 'unauthorized',
            message: 'Token sinkronisasi tidak dikenal atau sudah dicabut.'
          });
          this.sendJson(res, 401, { error: 'unauthorized' });
          return;
        }

        const ttlDays = Math.min(7, Math.max(3, parseInt(this.db.getMeta('token_ttl_days') || '7', 10) || 7));
        const expiresAt = matched.expires_at || (matched.paired_at + ttlDays * 24 * 60 * 60 * 1000);
        if (Date.now() > expiresAt) {
          const remaining = pairedDevices.filter(d => d.token !== token);
          this.db.setMeta('paired_devices', JSON.stringify(remaining));
          this.repository.logAudit({
            source: 'Desktop',
            category: 'auth',
            level: 'warn',
            endpoint: 'POST /api/v1/sync',
            statusCode: 401,
            errorCode: 'token_expired',
            message: `Token untuk perangkat ${matched.device_name || matched.device_id} kedaluwarsa.`,
            details: { device_id: matched.device_id, expires_at: expiresAt }
          });
          this.sendJson(res, 401, { error: 'token_expired' });
          return;
        }

        const body = await this.parseBody(req);
        let since = parseInt(body.since || 0, 10);
        const currentServerSeqBefore = parseInt(this.db.getMeta('server_seq') || '0', 10);
        if (Number.isNaN(since) || since < 0 || since > currentServerSeqBefore) {
          since = 0;
        }
        const incomingChanges = body.changes || {};
        const clientDeviceId = body.device_id || matched.device_id;

        const acceptedKeys = this.repository.applyChanges(incomingChanges, clientDeviceId);
        const outChanges = this.repository.getChangesSince(since, acceptedKeys);
        const currentCursor = parseInt(this.db.getMeta('server_seq') || '0', 10);

        matched.last_synced_at = Date.now();
        this.db.setMeta('paired_devices', JSON.stringify(pairedDevices));

        this.emit('sync_completed', {
          device: {
            device_id: matched.device_id,
            device_name: matched.device_name,
            last_synced_at: matched.last_synced_at
          }
        });

        this.sendJson(res, 200, {
          cursor: currentCursor,
          changes: outChanges,
          server_time: Date.now(),
          token_expires_at: expiresAt
        });
        return;
      }

      this.sendJson(res, 404, { error: 'not_found' });
    } catch (err) {
      console.error('SyncServer error:', err);
      this.repository.logAudit({
        source: 'Desktop',
        category: 'api',
        level: 'error',
        endpoint: `${req.method} ${url.pathname}`,
        statusCode: 500,
        errorCode: err.code || 'internal_error',
        message: err.message || 'Internal server error',
        details: { stack: String(err.stack || '').slice(0, 600) }
      });
      this.sendJson(res, 500, { error: 'internal_error' });
    }
  }
}

module.exports = { SyncServer };
