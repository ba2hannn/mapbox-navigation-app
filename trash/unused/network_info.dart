// Path: lib/core/platform/network_info.dart

import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    // `.none` dışındaki her durum bağlı kabul edilebilir.
    return result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi);
  }
}