import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:nsd/nsd.dart' as nsd;
import '../repositories/checklist_repository.dart';

enum SyncStatus {
  idle,
  discovering,
  syncing,
  connected,
  notFound,
  unauthorized,
  error,
}

class DiscoveredServer {
  final String host;
  final int port;
  final String deviceId;
  final String deviceName;

  DiscoveredServer({
    required this.host,
    required this.port,
    required this.deviceId,
    required this.deviceName,
  });
}

class SyncService {
  final ChecklistRepository repository;
  final http.Client httpClient;
  final Future<DiscoveredServer?> Function()? customDiscovery;

  SyncStatus status = SyncStatus.idle;
  DiscoveredServer? currentServer;
  int? lastSyncTime;
  int? tokenExpiresAt;
  String? errorMessage;
  bool autoSyncEnabled = true;
  bool useManualEndpoint = false;
  String manualHost = '';
  int manualPort = 47800;

  static const String metaManualEnabled = 'manual_sync_enabled';
  static const String metaManualHost = 'manual_sync_host';
  static const String metaManualPort = 'manual_sync_port';

  static String normalizeHost(String raw) {
    var h = raw.trim();
    h = h.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    final slash = h.indexOf('/');
    if (slash >= 0) h = h.substring(0, slash);
    final colon = h.lastIndexOf(':');
    if (colon > 0 && !h.contains(']')) {
      final maybePort = int.tryParse(h.substring(colon + 1));
      if (maybePort != null && maybePort >= 1 && maybePort <= 65535) {
        h = h.substring(0, colon);
      }
    }
    return h.trim();
  }

  static int? parsePort(String raw) {
    final p = int.tryParse(raw.trim());
    if (p == null || p < 1 || p > 65535) return null;
    return p;
  }

  Timer? _periodicTimer;
  Timer? _debounceTimer;
  bool _isSyncing = false;

  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncService({
    required this.repository,
    http.Client? httpClient,
    this.customDiscovery,
  }) : httpClient = httpClient ?? http.Client();

  /// Returns local non-loopback IPv4 interfaces (Wi-Fi/LAN prioritized).
  /// Uses OS socket interface enumeration and requires no extra permissions.
  Future<List<({String iface, String address})>> getLocalIpAddresses() async {
    try {
      final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final list = <({String iface, String address})>[];
      for (final nic in ifaces) {
        for (final addr in nic.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            list.add((iface: nic.name, address: addr.address));
          }
        }
      }
      int score(String name) {
        final low = name.toLowerCase();
        if (low.contains('wlan') || low.contains('wi-fi') || low.contains('wifi')) return 0;
        if (low.startsWith('en') || low.startsWith('eth')) return 1;
        return 2;
      }
      list.sort((a, b) => score(a.iface).compareTo(score(b.iface)));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<String?> primaryLocalIp() async {
    final ips = await getLocalIpAddresses();
    return ips.isNotEmpty ? ips.first.address : null;
  }

  Future<void> init() async {
    final savedAuto = await repository.getMeta('auto_sync');
    autoSyncEnabled = savedAuto != 'false';
    final savedTime = await repository.getMeta('last_sync_time');
    if (savedTime != null) {
      lastSyncTime = int.tryParse(savedTime);
    }
    final savedExp = await repository.getMeta('token_expires_at');
    if (savedExp != null && savedExp.isNotEmpty) {
      tokenExpiresAt = int.tryParse(savedExp);
    }
    useManualEndpoint = (await repository.getMeta(metaManualEnabled)) == 'true';
    manualHost = (await repository.getMeta(metaManualHost)) ?? '';
    manualPort = parsePort((await repository.getMeta(metaManualPort)) ?? '') ?? 47800;
    _startPeriodicSync();
  }

  Future<void> setManualEndpoint({
    required bool enabled,
    required String host,
    required int port,
  }) async {
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Port must be between 1 and 65535');
    }
    final cleanHost = normalizeHost(host);
    if (enabled && cleanHost.isEmpty) {
      throw ArgumentError.value(host, 'host', 'IP address or host cannot be empty');
    }
    useManualEndpoint = enabled;
    manualHost = cleanHost;
    manualPort = port;
    await repository.setMeta(metaManualEnabled, enabled ? 'true' : 'false');
    await repository.setMeta(metaManualHost, cleanHost);
    await repository.setMeta(metaManualPort, port.toString());
    currentServer = null;
    errorMessage = null;
  }

  Future<DiscoveredServer?> connectManual({String? host, int? port}) async {
    final targetHost = normalizeHost(host ?? manualHost);
    final targetPort = port ?? manualPort;
    if (targetHost.isEmpty || targetPort < 1 || targetPort > 65535) {
      _setStatus(SyncStatus.notFound, error: 'Invalid IP or port');
      return null;
    }
    _setStatus(SyncStatus.discovering);
    final verified = await _verifyServer(targetHost, targetPort);
    if (verified != null) {
      currentServer = verified;
      await _saveDiscoveredServer(verified);
      _setStatus(SyncStatus.connected);
      return verified;
    }
    _setStatus(SyncStatus.notFound, error: 'Cannot reach $targetHost:$targetPort');
    await repository.logAudit(
      category: 'discovery',
      level: 'error',
      endpoint: '$targetHost:$targetPort',
      errorCode: 'MANUAL_UNREACHABLE',
      message: 'Server Desktop tidak dapat dijangkau pada $targetHost:$targetPort.',
      details: {'host': targetHost, 'port': targetPort, 'manual': true},
    );
    return null;
  }

  void dispose() {
    _periodicTimer?.cancel();
    _debounceTimer?.cancel();
    _statusController.close();
  }

  void _setStatus(SyncStatus newStatus, {String? error}) {
    status = newStatus;
    errorMessage = error;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<void> setAutoSync(bool enabled) async {
    autoSyncEnabled = enabled;
    await repository.setMeta('auto_sync', enabled ? 'true' : 'false');
    if (enabled) {
      _startPeriodicSync();
    } else {
      _periodicTimer?.cancel();
    }
  }

  void _startPeriodicSync() {
    _periodicTimer?.cancel();
    if (!autoSyncEnabled) return;
    _periodicTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (autoSyncEnabled) sync();
    });
  }

  void triggerDebouncedSync() {
    if (!autoSyncEnabled) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (autoSyncEnabled) sync();
    });
  }

  Future<DiscoveredServer?> discoverDesktop({Duration timeout = const Duration(seconds: 3)}) async {
    _setStatus(SyncStatus.discovering);

    if (customDiscovery != null) {
      final found = await customDiscovery!();
      if (found != null) {
        currentServer = found;
        _setStatus(SyncStatus.connected);
        return found;
      }
      _setStatus(SyncStatus.notFound);
      return null;
    }

    // 0. Manual IP & Port override when enabled (Milestone 7)
    if (useManualEndpoint && manualHost.isNotEmpty) {
      return await connectManual(host: manualHost, port: manualPort);
    }

    // 1. Try remembered host & port first
    final lastHost = await repository.getMeta('last_sync_host');
    final lastPortStr = await repository.getMeta('last_sync_port');
    final lastDeviceId = await repository.getMeta('last_sync_device_id');
    if (lastHost != null && lastPortStr != null) {
      final port = int.tryParse(lastPortStr) ?? 47800;
      final verified = await _verifyServer(lastHost, port);
      if (verified != null && (lastDeviceId == null || lastDeviceId == verified.deviceId)) {
        currentServer = verified;
        _setStatus(SyncStatus.connected);
        return verified;
      }
    }

    // 2. Race mDNS (_langkahkecil._tcp) and UDP broadcast (47899) in parallel
    final foundCompleter = Completer<DiscoveredServer?>();
    int pending = 2;

    void onCandidate(DiscoveredServer? s) {
      if (s != null && !foundCompleter.isCompleted) {
        foundCompleter.complete(s);
      } else {
        pending--;
        if (pending == 0 && !foundCompleter.isCompleted) {
          foundCompleter.complete(null);
        }
      }
    }

    _discoverViaMdns(timeout: timeout).then(onCandidate);
    _discoverViaUdp(timeout: timeout).then(onCandidate);

    final discovered = await foundCompleter.future;
    if (discovered != null) {
      currentServer = discovered;
      await _saveDiscoveredServer(discovered);
      _setStatus(SyncStatus.connected);
      return discovered;
    }

    _setStatus(SyncStatus.notFound);
    await repository.logAudit(
      category: 'discovery',
      level: 'error',
      endpoint: 'UDP 47899 / mDNS',
      errorCode: 'NOT_FOUND',
      message: 'Desktop sync server tidak ditemukan di jaringan lokal.',
      details: {'timeoutSeconds': timeout.inSeconds},
    );
    return null;
  }

  Future<void> _saveDiscoveredServer(DiscoveredServer server) async {
    final prevId = await repository.getMeta('last_sync_device_id');
    if (prevId != null && prevId != server.deviceId) {
      await repository.setMeta('last_sync_cursor', '0');
    }
    await repository.setMeta('last_sync_host', server.host);
    await repository.setMeta('last_sync_port', server.port.toString());
    await repository.setMeta('last_sync_device_id', server.deviceId);
  }

  Future<DiscoveredServer?> _discoverViaMdns({Duration timeout = const Duration(seconds: 3)}) async {
    nsd.Discovery? discovery;
    try {
      discovery = await nsd.startDiscovery('_langkahkecil._tcp');
      final completer = Completer<DiscoveredServer?>();

      discovery.addServiceListener((service, status) async {
        if (status == nsd.ServiceStatus.found && !completer.isCompleted) {
          try {
            final resolved = await nsd.resolve(service);
            String? host;
            final addrs = resolved.addresses;
            if (addrs != null && addrs.isNotEmpty) {
              final ipv4 = addrs.where((a) => a.type == InternetAddressType.IPv4).toList();
              host = ipv4.isNotEmpty ? ipv4.first.address : addrs.first.address;
            }
            host ??= resolved.host;
            final port = resolved.port;
            if (host != null && port != null) {
              final verified = await _verifyServer(host, port);
              if (verified != null && !completer.isCompleted) {
                completer.complete(verified);
              }
            }
          } catch (_) {}
        }
      });

      return await completer.future.timeout(timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    } finally {
      if (discovery != null) {
        try {
          await nsd.stopDiscovery(discovery);
        } catch (_) {}
      }
    }
  }

  Future<DiscoveredServer?> _discoverViaUdp({Duration timeout = const Duration(seconds: 3)}) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final message = utf8.encode('LANGKAH_DISCOVER?v=1');
      socket.send(message, InternetAddress('255.255.255.255'), 47899);

      try {
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final parts = addr.address.split('.');
            if (parts.length == 4 && !addr.isLoopback) {
              final bcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              socket.send(message, InternetAddress(bcast), 47899);
            }
          }
        }
      } catch (_) {}

      final completer = Completer<DiscoveredServer?>();

      socket.listen((event) async {
        if (event == RawSocketEvent.read) {
          final dg = socket?.receive();
          if (dg != null) {
            try {
              final jsonStr = utf8.decode(dg.data);
              final map = json.decode(jsonStr) as Map<String, dynamic>;
              if (map['app'] == 'langkah-kecil') {
                final host = dg.address.address;
                final port = (map['port'] as num).toInt();
                final verified = await _verifyServer(host, port);
                if (verified != null && !completer.isCompleted) {
                  completer.complete(verified);
                }
              }
            } catch (_) {}
          }
        }
      });

      return await completer.future.timeout(timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    } finally {
      socket?.close();
    }
  }

  Future<DiscoveredServer?> _verifyServer(String host, int port) async {
    try {
      final uri = Uri.parse('http://$host:$port/api/v1/ping');
      final res = await httpClient.get(uri).timeout(const Duration(milliseconds: 1500));
      if (res.statusCode == 200) {
        final map = json.decode(res.body) as Map<String, dynamic>;
        if (map['app'] == 'langkah-kecil') {
          return DiscoveredServer(
            host: host,
            port: port,
            deviceId: map['device_id'] as String,
            deviceName: map['device_name'] as String? ?? 'Desktop',
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> pair(String code) async {
    var server = currentServer ?? await discoverDesktop();
    if (server == null) return false;

    try {
      final uri = Uri.parse('http://${server.host}:${server.port}/api/v1/pair');
      final myDeviceId = await repository.getMeta('device_id') ?? 'mobile-1';
      final myDeviceName = await repository.getMeta('device_name') ?? 'Ponsel';

      final res = await httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'code': code.trim(),
              'device_id': myDeviceId,
              'device_name': myDeviceName,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final token = body['token'] as String;
        await repository.setMeta('paired_token', token);
        await repository.setMeta('last_sync_cursor', '0');
        final exp = (body['expires_at'] as num?)?.toInt();
        if (exp != null) {
          tokenExpiresAt = exp;
          await repository.setMeta('token_expires_at', exp.toString());
        }
        _setStatus(SyncStatus.connected);
        await sync();
        return true;
      } else if (res.statusCode == 403) {
        _setStatus(SyncStatus.unauthorized, error: 'Kode pairing salah');
        await repository.logAudit(
          category: 'auth',
          level: 'warn',
          endpoint: 'POST /api/v1/pair',
          statusCode: 403,
          errorCode: 'bad_code',
          message: 'Kode pairing salah saat menyambungkan ke Desktop.',
          details: {'host': server.host, 'port': server.port},
        );
      } else {
        _setStatus(SyncStatus.error, error: 'Gagal menyambungkan');
        await repository.logAudit(
          category: 'api',
          level: 'error',
          endpoint: 'POST /api/v1/pair',
          statusCode: res.statusCode,
          errorCode: 'HTTP_${res.statusCode}',
          message: 'Permintaan pairing gagal dengan status HTTP ${res.statusCode}.',
          details: {'host': server.host, 'port': server.port},
        );
      }
    } catch (e) {
      _setStatus(SyncStatus.error, error: e.toString());
      await repository.logAudit(
        category: 'api',
        level: 'error',
        endpoint: 'POST /api/v1/pair',
        errorCode: 'EXCEPTION',
        message: 'Error jaringan saat pairing: $e',
        details: {'host': server.host, 'port': server.port},
      );
    }
    return false;
  }

  Future<bool> sync() async {
    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      var server = currentServer;
      if (server == null) {
        server = await discoverDesktop();
        if (server == null) return false;
      }

      final token = await repository.getMeta('paired_token');
      if (token == null || token.isEmpty) {
        _setStatus(SyncStatus.unauthorized);
        return false;
      }

      final expStr = await repository.getMeta('token_expires_at');
      final expMs = tokenExpiresAt ?? (expStr != null ? int.tryParse(expStr) : null);
      if (expMs != null && DateTime.now().millisecondsSinceEpoch > expMs) {
        tokenExpiresAt = null;
        await repository.setMeta('paired_token', '');
        await repository.setMeta('token_expires_at', '');
        _setStatus(SyncStatus.unauthorized, error: 'Sesi kedaluwarsa, silakan sambungkan ulang');
        await repository.logAudit(
          category: 'auth',
          level: 'warn',
          endpoint: 'POST /api/v1/sync',
          statusCode: 401,
          errorCode: 'token_expired_local',
          message: 'Token sinkronisasi lokal kedaluwarsa. Perlu pairing ulang.',
        );
        return false;
      }

      final hadPriorError = errorMessage != null || status == SyncStatus.error || status == SyncStatus.notFound;
      _setStatus(SyncStatus.syncing);

      final uri = Uri.parse('http://${server.host}:${server.port}/api/v1/sync');
      final cursorStr = await repository.getMeta('last_sync_cursor') ?? '0';
      final cursor = int.tryParse(cursorStr) ?? 0;
      final myDeviceId = await repository.getMeta('device_id') ?? 'mobile-1';
      final dirtyChanges = await repository.getDirtyChanges();

      final res = await httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'since': cursor,
              'device_id': myDeviceId,
              'changes': dirtyChanges,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final incomingChanges = body['changes'] as Map<String, dynamic>;
        final newCursor = (body['cursor'] as num).toInt();

        await repository.applyIncomingChanges(incomingChanges, server.deviceId);
        await repository.clearDirtyFlags(dirtyChanges);
        await repository.setMeta('last_sync_cursor', newCursor.toString());

        lastSyncTime = DateTime.now().millisecondsSinceEpoch;
        await repository.setMeta('last_sync_time', lastSyncTime.toString());
        final serverExp = (body['token_expires_at'] as num?)?.toInt();
        if (serverExp != null) {
          tokenExpiresAt = serverExp;
          await repository.setMeta('token_expires_at', serverExp.toString());
        }
        _setStatus(SyncStatus.connected);
        if (hadPriorError) {
          await repository.logAudit(
            category: 'sync',
            level: 'info',
            endpoint: 'POST /api/v1/sync',
            statusCode: 200,
            errorCode: 'OK',
            message: 'Sinkronisasi berhasil dipulihkan.',
            details: {'cursor': newCursor, 'host': server.host},
          );
        }
        return true;
      } else if (res.statusCode == 401) {
        tokenExpiresAt = null;
        await repository.setMeta('paired_token', '');
        await repository.setMeta('token_expires_at', '');
        _setStatus(SyncStatus.unauthorized, error: 'Sesi berakhir, perlu disambungkan ulang');
        await repository.logAudit(
          category: 'auth',
          level: 'warn',
          endpoint: 'POST /api/v1/sync',
          statusCode: 401,
          errorCode: 'unauthorized',
          message: 'Server menolak token sinkronisasi (401). Perlu pairing ulang.',
          details: {'host': server.host, 'port': server.port},
        );
      } else {
        // Might have changed IP; clear currentServer so next attempt re-discovers
        final prevHost = server.host;
        currentServer = null;
        _setStatus(SyncStatus.error, error: 'HTTP ${res.statusCode}');
        await repository.logAudit(
          category: 'sync',
          level: 'error',
          endpoint: 'POST /api/v1/sync',
          statusCode: res.statusCode,
          errorCode: 'HTTP_${res.statusCode}',
          message: 'Sinkronisasi gagal dengan HTTP ${res.statusCode}.',
          details: {'host': prevHost},
        );
      }
    } catch (e) {
      currentServer = null;
      _setStatus(SyncStatus.notFound, error: e.toString());
      await repository.logAudit(
        category: 'sync',
        level: 'error',
        endpoint: 'POST /api/v1/sync',
        errorCode: 'SYNC_FAILED',
        message: 'Sinkronisasi gagal: $e',
      );
    } finally {
      _isSyncing = false;
    }
    return false;
  }
}
