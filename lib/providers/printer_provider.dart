import 'package:flutter/foundation.dart';
import '../models/business_settings.dart';
import '../services/bluetooth_printer_service.dart';

enum PrinterStatus { disconnected, connecting, connected, unsupported }

class PrinterProvider extends ChangeNotifier {
  PrinterDevice? _connectedDevice;
  PrinterStatus _status = PrinterStatus.disconnected;
  List<PrinterDevice> _availablePrinters = [];
  bool _isScanning = false;
  bool _isPrinting = false;

  PrinterDevice? get connectedDevice => _connectedDevice;
  PrinterStatus get status => _status;
  List<PrinterDevice> get availablePrinters => _availablePrinters;
  bool get isScanning => _isScanning;
  bool get isPrinting => _isPrinting;

  String? get deviceName => _connectedDevice?.name;

  Future<void> scanPrinters() async {
    _isScanning = true;
    notifyListeners();

    final hasPermission = await BluetoothPrinterService.instance
        .requestPermissions();
    if (!hasPermission) {
      _isScanning = false;
      notifyListeners();
      return;
    }

    final isBtEnabled = await BluetoothPrinterService.instance
        .isBluetoothEnabled();
    if (!isBtEnabled) {
      _status = PrinterStatus.unsupported;
      _isScanning = false;
      notifyListeners();
      return;
    }

    _availablePrinters = await BluetoothPrinterService.instance
        .getBluetoothPrinters();
    _isScanning = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> connectPrinter(PrinterDevice device) async {
    _status = PrinterStatus.connecting;
    notifyListeners();

    final result = await BluetoothPrinterService.instance.connect(device);
    if (result['success'] == true) {
      _connectedDevice = device;
      _status = PrinterStatus.connected;
    } else {
      _connectedDevice = null;
      _status = PrinterStatus.disconnected;
    }
    notifyListeners();
    return result;
  }

  Future<void> disconnectPrinter() async {
    await BluetoothPrinterService.instance.disconnect();
    _connectedDevice = null;
    _status = PrinterStatus.disconnected;
    notifyListeners();
  }

  Future<Map<String, dynamic>> printReceipt({
    required dynamic order,
    required BusinessSettings settings,
  }) async {
    _isPrinting = true;
    notifyListeners();

    try {
      final res = await BluetoothPrinterService.instance.printReceipt(
        order: order,
        settings: settings,
      );
      return res;
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> printTestSlip(BusinessSettings settings) async {
    _isPrinting = true;
    notifyListeners();

    try {
      final res = await BluetoothPrinterService.instance.printTestSlip(
        settings,
      );
      return res;
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }
}
