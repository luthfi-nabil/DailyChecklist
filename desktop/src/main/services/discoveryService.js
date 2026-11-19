const dgram = require('node:dgram');
const { Bonjour } = require('bonjour-service');

class DiscoveryService {
  constructor(db, syncPort) {
    this.db = db;
    this.syncPort = syncPort;
    this.udpSocket = null;
    this.bonjour = null;
    this.bonjourService = null;
  }

  start() {
    this.startUdp();
    this.startMdns();
  }

  startUdp() {
    try {
      this.udpSocket = dgram.createSocket({ type: 'udp4', reuseAddr: true });

      this.udpSocket.on('error', (err) => {
        console.warn('UDP Discovery socket error:', err.message);
      });

      this.udpSocket.on('message', (msg, rinfo) => {
        const text = msg.toString('utf8');
        if (text.startsWith('LANGKAH_DISCOVER')) {
          const response = JSON.stringify({
            app: 'langkah-kecil',
            v: 1,
            device_id: this.db.getMeta('device_id'),
            device_name: this.db.getMeta('device_name') || 'Desktop',
            port: this.syncPort
          });
          const buf = Buffer.from(response, 'utf8');
          this.udpSocket.send(buf, 0, buf.length, rinfo.port, rinfo.address, (err) => {
            if (err) console.warn('Failed to reply to discovery:', err);
          });
        }
      });

      this.udpSocket.bind(47899, '0.0.0.0', () => {
        try {
          this.udpSocket.setBroadcast(true);
        } catch (e) {}
      });
    } catch (err) {
      console.warn('Could not start UDP discovery responder:', err.message);
    }
  }

  startMdns() {
    try {
      this.bonjour = new Bonjour();
      const deviceName = this.db.getMeta('device_name') || 'Desktop';
      const deviceId = this.db.getMeta('device_id');

      this.bonjourService = this.bonjour.publish({
        name: `LangkahKecil-${deviceName}`,
        type: 'langkahkecil',
        protocol: 'tcp',
        port: this.syncPort,
        txt: {
          id: deviceId,
          v: '1'
        }
      });
    } catch (err) {
      console.warn('Could not start mDNS service:', err.message);
    }
  }

  updatePort(newPort) {
    const parsed = parseInt(newPort, 10);
    if (!Number.isInteger(parsed) || parsed < 1 || parsed > 65535) return;
    if (this.syncPort === parsed) return;
    this.syncPort = parsed;
    if (this.bonjourService) {
      try {
        this.bonjourService.stop();
      } catch (e) {}
      this.bonjourService = null;
    }
    if (this.bonjour) {
      try {
        this.bonjour.destroy();
      } catch (e) {}
      this.bonjour = null;
    }
    this.startMdns();
  }

  stop() {
    if (this.udpSocket) {
      try {
        this.udpSocket.close();
      } catch (e) {}
      this.udpSocket = null;
    }
    if (this.bonjourService) {
      try {
        this.bonjourService.stop();
      } catch (e) {}
      this.bonjourService = null;
    }
    if (this.bonjour) {
      try {
        this.bonjour.destroy();
      } catch (e) {}
      this.bonjour = null;
    }
  }
}

module.exports = { DiscoveryService };
