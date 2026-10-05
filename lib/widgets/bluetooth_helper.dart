import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothHelper {
  /// Asks for permissions and turns Bluetooth ON if it is off.
  /// Returns true when Bluetooth is ready to use.
  static Future<bool> ensureOn() async {
    if (!await FlutterBluePlus.isSupported) return false;

    if (Platform.isAndroid) {
      final result = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      if (result[Permission.bluetoothConnect]?.isGranted != true) return false;
    }

    if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on) {
      return true;
    }

    if (Platform.isAndroid) {
      try {
        // Shows the system "Allow app to turn on Bluetooth?" prompt
        await FlutterBluePlus.turnOn();
        await FlutterBluePlus.adapterState
            .firstWhere((s) => s == BluetoothAdapterState.on)
            .timeout(const Duration(seconds: 10));
        return true;
      } catch (_) {
        return false;
      }
    }
    return false; // iOS cannot turn Bluetooth on from an app
  }
}