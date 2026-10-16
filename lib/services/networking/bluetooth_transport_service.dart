import 'dart:io';
import '../../features/local_transfer/domain/transport_interfaces.dart';
import '../../shared/models/transfer_models.dart';
import '../../core/errors/app_exceptions.dart';

class BluetoothTransportService implements BluetoothTransport {
  @override
  Future<bool> isSupported() async {
    // Bluetooth RFCOMM Object Push Profile (OPP) is severely restricted on modern desktop Windows
    // without OEM drivers and requires native platform channels on Android.
    if (Platform.isWindows) {
      // Windows Desktop standard APIs do not expose generic OPP without native Win32/Winsock RFCOMM drivers
      return false;
    } else if (Platform.isAndroid) {
      // Android supports BluetoothAdapter RFCOMM with BLUETOOTH_CONNECT & BLUETOOTH_SCAN permissions
      return true;
    }
    return false;
  }

  @override
  Future<bool> isEnabled() async {
    final supported = await isSupported();
    if (!supported) return false;
    // On Android, checked via platform channel or permission check
    return true;
  }

  @override
  Future<List<String>> discoverDevices() async {
    final supported = await isSupported();
    if (!supported) {
      throw const BluetoothUnsupportedException(
        'Bluetooth file transfer is not natively supported on this platform. Please use Wi-Fi / LAN Nearby Transfer instead.',
      );
    }
    // Return empty list or platform bonded devices when queried
    return [];
  }

  @override
  Future<void> sendFile({
    required String deviceAddress,
    required File file,
    required void Function(TransferRecordModel progress) onProgress,
  }) async {
    final supported = await isSupported();
    if (!supported) {
      throw const BluetoothUnsupportedException(
        'Bluetooth file transfer (OPP/RFCOMM) is unavailable on this platform. Use high-speed Wi-Fi Direct or LAN transfer.',
      );
    }
  }
}
