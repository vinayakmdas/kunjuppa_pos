import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/printer_provider.dart';
import '../providers/settings_provider.dart';
import 'bluetooth_helper.dart';

class PrinterConfigModal extends StatefulWidget {
  const PrinterConfigModal({super.key});

  @override
  State<PrinterConfigModal> createState() => _PrinterConfigModalState();
}

class _PrinterConfigModalState extends State<PrinterConfigModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _scanWithBluetooth();
    });
  }

  /// Ensures Bluetooth is on, then scans for paired printers.
  /// Identical to the Settings → Pair Bluetooth Printer flow.
  Future<void> _scanWithBluetooth() async {
    if (!mounted) return;
    final ok = await BluetoothHelper.ensureOn();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth is off or permission denied.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Bluetooth is ready — scan for paired printers
    context.read<PrinterProvider>().scanPrinters();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final printerProv = context.watch<PrinterProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final settings = settingsProv.settings;
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: AppColors.darkCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: screenSize.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title Header ────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.printer, color: AppColors.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Thermal Printer Hardware',
                          style: TextStyle(color: AppColors.darkText, fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Scan, pair & print ESC/POS receipts',
                          style: TextStyle(color: AppColors.darkSubtext, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: AppColors.darkSubtext, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Connection Status Banner ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkInputBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: printerProv.status == PrinterStatus.connected
                            ? AppColors.success
                            : printerProv.status == PrinterStatus.connecting
                                ? AppColors.warning
                                : AppColors.darkSubtext,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            printerProv.status == PrinterStatus.connected
                                ? 'Connected: ${printerProv.deviceName ?? "Thermal Printer"}'
                                : printerProv.status == PrinterStatus.connecting
                                    ? 'Connecting to printer...'
                                    : 'No Bluetooth Printer Connected',
                            style: TextStyle(
                              color: printerProv.status == PrinterStatus.connected
                                  ? AppColors.primaryLight
                                  : AppColors.darkText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            printerProv.status == PrinterStatus.connected
                                ? 'ESC/POS Direct Ready'
                                : 'Select a printer below to connect',
                            style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    if (printerProv.status == PrinterStatus.connected)
                      TextButton(
                        onPressed: () async {
                          await printerProv.disconnectPrinter();
                          _showSnackBar('Printer disconnected.');
                        },
                        child: const Text('Disconnect', style: TextStyle(color: AppColors.danger, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Available Bluetooth Printers ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Bluetooth Devices',
                    style: TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  InkWell(
                    onTap: printerProv.isScanning ? null : _scanWithBluetooth,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.refreshCw,
                            size: 13,
                            color: printerProv.isScanning ? AppColors.darkSubtext : AppColors.primaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            printerProv.isScanning ? 'Scanning...' : 'Refresh List',
                            style: TextStyle(
                              color: printerProv.isScanning ? AppColors.darkSubtext : AppColors.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bluetooth permission/status info banner
              if (printerProv.status == PrinterStatus.unsupported)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: const [
                      Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bluetooth is disabled or permissions denied. Enable Bluetooth in device Settings.',
                          style: TextStyle(color: AppColors.warning, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

              // Printers list container
              Container(
                height: _listHeight(printerProv),
                decoration: BoxDecoration(
                  color: AppColors.darkInputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: printerProv.isScanning
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.primaryLight, strokeWidth: 2),
                            SizedBox(height: 8),
                            Text('Scanning for Bluetooth printers...', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
                          ],
                        ),
                      )
                    : printerProv.availablePrinters.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(LucideIcons.bluetooth, color: AppColors.darkSubtext, size: 28),
                                SizedBox(height: 6),
                                Text('No paired Bluetooth printers found.',
                                    style: TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
                                SizedBox(height: 4),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Pair your thermal printer in Android Bluetooth Settings first, then tap Refresh List.',
                                    style: TextStyle(color: AppColors.darkSubtext, fontSize: 9),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: printerProv.availablePrinters.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.darkCardBorder),
                            itemBuilder: (context, idx) {
                              final device = printerProv.availablePrinters[idx];
                              final isThisConnected = printerProv.connectedDevice?.macAddress == device.macAddress;

                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: Icon(
                                  LucideIcons.bluetooth,
                                  color: isThisConnected ? AppColors.primaryLight : AppColors.darkSubtext,
                                  size: 18,
                                ),
                                title: Text(
                                  device.name,
                                  style: TextStyle(
                                    color: isThisConnected ? AppColors.primaryLight : AppColors.darkText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  device.macAddress,
                                  style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10, fontFamily: 'monospace'),
                                ),
                                trailing: isThisConnected
                                    ? const Icon(LucideIcons.checkCircle, color: AppColors.primaryLight, size: 18)
                                    : printerProv.status == PrinterStatus.connecting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primaryLight,
                                            ),
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              minimumSize: const Size(70, 32),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            onPressed: () async {
                                              final res = await printerProv.connectPrinter(device);
                                              _showSnackBar(res['message'], isError: res['success'] != true);
                                            },
                                            child: const Text('Connect', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),

              // ── Paper Roll Width Config ──────────────────────────────
              const Text(
                'Paper Roll Width Profile',
                style: TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildWidthOption(
                      label: '58 mm',
                      subtitle: '32 char layout',
                      value: '58mm',
                      selected: settings.receiptWidth == '58mm',
                      onTap: () => settingsProv.updateSettings(settings.copyWith(receiptWidth: '58mm')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildWidthOption(
                      label: '80 mm',
                      subtitle: '48 char layout',
                      value: '80mm',
                      selected: settings.receiptWidth == '80mm',
                      onTap: () => settingsProv.updateSettings(settings.copyWith(receiptWidth: '80mm')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Actions: Print Test Slip & Close ────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (printerProv.status == PrinterStatus.connected)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkText,
                        side: const BorderSide(color: AppColors.darkCardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: printerProv.isPrinting
                          ? null
                          : () async {
                              final res = await printerProv.printTestSlip(settings);
                              _showSnackBar(res['message'], isError: res['success'] != true);
                            },
                      icon: const Icon(LucideIcons.refreshCw, size: 14),
                      label: const Text('Print Test Slip', style: TextStyle(fontSize: 11)),
                    ),
                  if (printerProv.status == PrinterStatus.connected)
                    const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkCardBorder,
                      foregroundColor: AppColors.darkText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dynamic height for the printer list based on how many devices are found
  double _listHeight(PrinterProvider printerProv) {
    if (printerProv.isScanning) return 100;
    if (printerProv.availablePrinters.isEmpty) return 110;
    // Clamp: show at most 4 items before scrolling
    final count = printerProv.availablePrinters.length.clamp(1, 4);
    return count * 60.0;
  }

  Widget _buildWidthOption({
    required String label,
    required String subtitle,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.darkInputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.darkCardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  color: selected ? AppColors.primaryLight : AppColors.darkText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
