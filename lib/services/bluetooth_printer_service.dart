import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/business_settings.dart';
import '../models/order.dart';
import '../models/pending_order.dart';

class PrinterDevice {
  final String name;
  final String macAddress;
  final BluetoothDevice rawDevice;

  PrinterDevice({
    required this.name,
    required this.macAddress,
    required this.rawDevice,
  });
}

class BluetoothPrinterService {
  static final BluetoothPrinterService instance = BluetoothPrinterService._internal();
  BluetoothPrinterService._internal();

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  PrinterDevice? _connectedDevice;
  bool _isConnected = false;

  PrinterDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;

  /// Request required Bluetooth & Location permissions on Android / iOS
  Future<bool> requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetooth,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();

        bool isGranted = (statuses[Permission.bluetoothConnect]?.isGranted ?? true) &&
            (statuses[Permission.bluetoothScan]?.isGranted ?? true);
        return isGranted;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting Bluetooth permissions: $e');
      return false;
    }
  }

  /// Check if Bluetooth is enabled on the device
  Future<bool> isBluetoothEnabled() async {
    try {
      final bool? isOn = await _bluetooth.isOn;
      return isOn ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Scan for paired / bonded Bluetooth thermal printers
  Future<List<PrinterDevice>> getBluetoothPrinters() async {
    try {
      final List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      return devices
          .map((d) => PrinterDevice(
                name: (d.name != null && d.name!.isNotEmpty) ? d.name! : 'Thermal Printer',
                macAddress: d.address ?? '',
                rawDevice: d,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting Bluetooth printers: $e');
      return [];
    }
  }

  /// Connect to selected Bluetooth printer
  Future<Map<String, dynamic>> connect(PrinterDevice device) async {
    try {
      await _bluetooth.connect(device.rawDevice);
      _connectedDevice = device;
      _isConnected = true;
      return {
        'success': true,
        'message': 'Connected to ${device.name} successfully!',
      };
    } catch (e) {
      _isConnected = false;
      _connectedDevice = null;
      return {
        'success': false,
        'message': 'Error connecting to printer: ${e.toString()}',
      };
    }
  }

  /// Disconnect current printer
  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _isConnected = false;
  }

  /// Update / verify connection status
  Future<bool> checkConnectionStatus() async {
    try {
      final bool? status = await _bluetooth.isConnected;
      _isConnected = status ?? false;
      if (!_isConnected) _connectedDevice = null;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      _connectedDevice = null;
      return false;
    }
  }

  /// Print raw ESC/POS bytes to connected Bluetooth printer
  Future<Map<String, dynamic>> printRawBytes(List<int> bytes) async {
    final status = await checkConnectionStatus();
    if (!status) {
      return {
        'success': false,
        'message': 'Printer is not connected. Connect via Bluetooth first.',
      };
    }

    try {
      final Uint8List data = Uint8List.fromList(bytes);
      await _bluetooth.writeBytes(data);
      return {'success': true, 'message': 'Printed successfully via Bluetooth!'};
    } catch (e) {
      return {'success': false, 'message': 'Print error: ${e.toString()}'};
    }
  }

  /// Print receipt for Order or PendingOrder
  Future<Map<String, dynamic>> printReceipt({
    required dynamic order, // Order or PendingOrder
    required BusinessSettings settings,
  }) async {
    final bytes = generateEscPosReceiptBytes(order: order, settings: settings);
    return await printRawBytes(bytes);
  }

  /// Print a test slip to verify printer formatting
  Future<Map<String, dynamic>> printTestSlip(BusinessSettings settings) async {
    final bytes = generateTestSlipBytes(settings);
    return await printRawBytes(bytes);
  }

  // Helper string pad function
  static String padBetween(String left, String right, int width) {
    final l = left.trim();
    final r = right.trim();
    final totalLen = l.length + r.length;
    if (totalLen >= width) {
      final available = width - r.length - 1;
      return '${available > 0 ? l.substring(0, available) : ''} $r';
    }
    final spaces = ' ' * (width - totalLen);
    return l + spaces + r;
  }

  static String centerText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final leftPadding = (width - text.length) ~/ 2;
    return (' ' * leftPadding) + text;
  }

  /// Generate ESC/POS byte commands for orders matching original Next.js receipt structure
  static List<int> generateEscPosReceiptBytes({
    required dynamic order, // Order or PendingOrder
    required BusinessSettings settings,
  }) {
    List<int> bytes = [];

    // Initialize printer (ESC @)
    bytes.addAll([0x1B, 0x40]);

    final bool is58mm = settings.receiptWidth == '58mm';
    final int width = is58mm ? 32 : 48;
    final String divider = '-' * width;
    final String doubleDivider = '=' * width;

    final String billId = (order is Order) ? order.orderNumber : (order as PendingOrder).label;
    final String custName = order.customerName;
    final String? custPhone = order.customerPhone;
    final String paymentMethod = order.paymentMethod.toString().toUpperCase();
    final String createdAt = order.createdAt;

    // Center Align (ESC a 1)
    bytes.addAll([0x1B, 0x61, 0x01]);
    // Bold On (ESC E 1)
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(utf8.encode('${settings.businessName.toUpperCase()}\n'));
    // Bold Off (ESC E 0)
    bytes.addAll([0x1B, 0x45, 0x00]);

    bytes.addAll(utf8.encode('${settings.address}\n'));
    bytes.addAll(utf8.encode('Tel: ${settings.phone}\n'));
    if (settings.gstin != null && settings.gstin!.isNotEmpty) {
      bytes.addAll(utf8.encode('GSTIN: ${settings.gstin}\n'));
    }
    bytes.addAll(utf8.encode('$divider\n'));

    // Left Align (ESC a 0)
    bytes.addAll([0x1B, 0x61, 0x00]);
    bytes.addAll(utf8.encode('Bill No: $billId\n'));

    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      bytes.addAll(utf8.encode('Date: $dateStr\n'));
    } catch (_) {
      bytes.addAll(utf8.encode('Date: $createdAt\n'));
    }

    bytes.addAll(utf8.encode('Customer: $custName\n'));
    if (custPhone != null && custPhone.isNotEmpty) {
      bytes.addAll(utf8.encode('Contact: $custPhone\n'));
    }
    bytes.addAll(utf8.encode('Payment: $paymentMethod\n'));
    bytes.addAll(utf8.encode('$divider\n'));

    // Table Header
    bytes.addAll([0x1B, 0x45, 0x01]); // Bold
    if (is58mm) {
      bytes.addAll(utf8.encode('ITEM              QTY      TOTAL\n'));
    } else {
      bytes.addAll(utf8.encode('ITEM                   QTY      PRICE      TOTAL\n'));
    }
    bytes.addAll([0x1B, 0x45, 0x00]); // Bold Off
    bytes.addAll(utf8.encode('$divider\n'));

    // Items
    final List itemsList = order.items;
    for (var item in itemsList) {
      final String itemName = (item is OrderItem)
          ? item.productName
          : (item.name ?? 'Item');
      final double unitPrice = item.unitPrice;
      final int qty = item.quantity;
      final String unit = item.unit;
      final double lineTotal = item.lineTotal;

      final String totalStr = 'Rs.${lineTotal.toStringAsFixed(2)}';
      final String qtyStr = '$qty $unit';

      if (is58mm) {
        final String truncatedName = itemName.length > 32 ? itemName.substring(0, 32) : itemName;
        bytes.addAll(utf8.encode('$truncatedName\n'));
        final String leftPart = '  $qtyStr x ${unitPrice.toStringAsFixed(0)}';
        bytes.addAll(utf8.encode('${padBetween(leftPart, totalStr, width)}\n'));
      } else {
        final String namePart = itemName.length > 20
            ? '${itemName.substring(0, 20)}..'
            : itemName.padRight(22);
        final String qPart = qtyStr.padRight(8);
        final String pPart = 'Rs.${unitPrice.toStringAsFixed(0)}'.padRight(9);
        final String line = '$namePart $qPart $pPart ${totalStr.padLeft(7)}';
        bytes.addAll(utf8.encode('$line\n'));
      }
    }
    bytes.addAll(utf8.encode('$divider\n'));

    // Totals
    final double subtotal = order.subtotal;
    final double discountAmount = order.discountAmount;
    final String discountType = order.discountType;
    final double discountValue = order.discountValue;
    final double grandTotal = order.grandTotal;
    final int itemCount = order.itemCount;
    final int totalQuantity = order.totalQuantity;

    bytes.addAll(utf8.encode('${padBetween("Subtotal:", "Rs.${subtotal.toStringAsFixed(2)}", width)}\n'));
    if (discountAmount > 0) {
      final String discLabel = 'Discount (${discountType == "percentage" ? "${discountValue.toStringAsFixed(0)}%" : "Flat"}):';
      bytes.addAll(utf8.encode('${padBetween(discLabel, "-Rs.${discountAmount.toStringAsFixed(2)}", width)}\n'));
    }

    bytes.addAll(utf8.encode('$doubleDivider\n'));
    bytes.addAll([0x1B, 0x45, 0x01]); // Bold
    bytes.addAll(utf8.encode('${padBetween("TOTAL AMOUNT:", "Rs.${grandTotal.toStringAsFixed(2)}", width)}\n'));
    bytes.addAll([0x1B, 0x45, 0x00]); // Bold Off
    bytes.addAll(utf8.encode('$doubleDivider\n'));
    bytes.addAll(utf8.encode('${padBetween("Items: $itemCount", "Total Qty: $totalQuantity", width)}\n'));
    bytes.addAll(utf8.encode('$divider\n'));

    // Footer
    bytes.addAll([0x1B, 0x61, 0x01]); // Center Align
    if (settings.receiptFooter.isNotEmpty) {
      final lines = settings.receiptFooter.split('\n');
      for (var line in lines) {
        bytes.addAll(utf8.encode('${line.trim()}\n'));
      }
    }
    bytes.addAll(utf8.encode('*** Powered by POS ***\n\n\n'));

    // Feed & Cut Paper (ESC d 3, GS V 0)
    bytes.addAll([0x1B, 0x64, 0x03]);
    bytes.addAll([0x1D, 0x56, 0x00]);

    return bytes;
  }

  /// Generate Test Slip ESC/POS Bytes
  static List<int> generateTestSlipBytes(BusinessSettings settings) {
    List<int> bytes = [];

    bytes.addAll([0x1B, 0x40]); // Init
    final bool is58mm = settings.receiptWidth == '58mm';
    final int width = is58mm ? 32 : 48;
    final String divider = '=' * width;

    // Center Align
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll([0x1B, 0x45, 0x01]); // Bold
    bytes.addAll(utf8.encode('${settings.businessName.toUpperCase()}\n'));
    bytes.addAll([0x1B, 0x45, 0x00]); // Bold Off
    bytes.addAll(utf8.encode('THERMAL PRINTER TEST RECEIPT\n'));
    bytes.addAll(utf8.encode('$divider\n'));

    // Left Align
    bytes.addAll([0x1B, 0x61, 0x00]);
    bytes.addAll(utf8.encode('Date: ${DateTime.now().toString().substring(0, 19)}\n'));
    bytes.addAll(utf8.encode('Currency: ${settings.currencyCode} (${settings.currencySymbol})\n'));
    bytes.addAll(utf8.encode('Width Profile: ${settings.receiptWidth}\n'));
    bytes.addAll(utf8.encode('ESC/POS Commands: OK\n'));
    bytes.addAll(utf8.encode('Character Set: ASCII / CP437\n'));
    bytes.addAll(utf8.encode('$divider\n'));

    // Center Align
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll([0x1B, 0x45, 0x01]); // Bold
    bytes.addAll(utf8.encode('*** PRINTER TEST PASSED ***\n\n\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);

    // Cut
    bytes.addAll([0x1B, 0x64, 0x03]);
    bytes.addAll([0x1D, 0x56, 0x00]);

    return bytes;
  }
}
