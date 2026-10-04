import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/printer_provider.dart';
import '../providers/settings_provider.dart';

class PrinterConfigModal extends StatefulWidget {
  const PrinterConfigModal({super.key});

  @override
  State<PrinterConfigModal> createState() => _PrinterConfigModalState();
}

class _PrinterConfigModalState extends State<PrinterConfigModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().scanPrinters();
    });
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

    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Thermal Printer Hardware',
                          style: TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Scan, pair & print ESC/POS receipts',
                          style: TextStyle(color: AppColors.darkSubtext, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.darkSubtext, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Connection Status Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkInputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      Column(
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
                          ),
                          Text(
                            printerProv.status == PrinterStatus.connected
                                ? 'ESC/POS Direct Ready'
                                : 'Select a printer below to connect',
                            style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
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

            // Available Bluetooth Printers List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Bluetooth Devices',
                  style: TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: printerProv.isScanning ? null : () => printerProv.scanPrinters(),
                  child: Row(
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
              ],
            ),
            const SizedBox(height: 8),

            Container(
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.darkInputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: printerProv.isScanning
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight, strokeWidth: 2))
                  : printerProv.availablePrinters.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(LucideIcons.bluetooth, color: AppColors.darkSubtext, size: 24),
                              SizedBox(height: 4),
                              Text('No paired thermal printers found.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11)),
                              Text('Pair your printer in Android Bluetooth Settings first.', style: TextStyle(color: AppColors.darkSubtext, fontSize: 9)),
                            ],
                          ),
                        )
                      : ListView.separated(
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
                              ),
                              subtitle: Text(
                                device.macAddress,
                                style: const TextStyle(color: AppColors.darkSubtext, fontSize: 10, fontFamily: 'monospace'),
                              ),
                              trailing: isThisConnected
                                  ? const Icon(LucideIcons.checkCircle, color: AppColors.primaryLight, size: 18)
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

            // Paper Roll Width Config
            const Text(
              'Paper Roll Width Profile',
              style: TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      settingsProv.updateSettings(settings.copyWith(receiptWidth: '58mm'));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: settings.receiptWidth == '58mm'
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.darkInputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: settings.receiptWidth == '58mm'
                              ? AppColors.primaryLight
                              : AppColors.darkCardBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('58 mm (2-inch roll)', style: TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('32 character column layout', style: TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      settingsProv.updateSettings(settings.copyWith(receiptWidth: '80mm'));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: settings.receiptWidth == '80mm'
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.darkInputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: settings.receiptWidth == '80mm'
                              ? AppColors.primaryLight
                              : AppColors.darkCardBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('80 mm (3-inch roll)', style: TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('48 character standard layout', style: TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions: Print Test Slip & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  )
                else
                  const SizedBox(),
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
    );
  }
}
