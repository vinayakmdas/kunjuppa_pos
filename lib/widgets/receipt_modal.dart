import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/order.dart';
import '../models/pending_order.dart';
import '../providers/printer_provider.dart';
import '../providers/settings_provider.dart';
import 'bluetooth_helper.dart';
import 'printer_config_modal.dart';

class ReceiptModal extends StatefulWidget {
  final dynamic order; // Order or PendingOrder
  final Function(PendingOrder)? onSavePendingOrder;
  final Function(String)? onMarkPrinted;

  const ReceiptModal({
    super.key,
    required this.order,
    this.onSavePendingOrder,
    this.onMarkPrinted,
  });

  @override
  State<ReceiptModal> createState() => _ReceiptModalState();
}

class _ReceiptModalState extends State<ReceiptModal> {
  late String _activeWidth;
  bool _hasPrintedLocally = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _activeWidth = settings.receiptWidth;
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

  void _recordPrintSuccess() {
    setState(() {
      _hasPrintedLocally = true;
    });
    if (widget.order is PendingOrder && widget.onMarkPrinted != null) {
      widget.onMarkPrinted!(widget.order.id);
    }
  }

  /// Opens printer pairing modal with automatic Bluetooth enable prompt —
  /// identical to the Settings → Pair Bluetooth Printer flow.
  Future<void> _openPrinterModal() async {
    final ok = await BluetoothHelper.ensureOn();
    if (!mounted) return;
    if (!ok) {
      _showSnackBar('Bluetooth is off or permission denied.', isError: true);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => const PrinterConfigModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();
    final printerProv = context.watch<PrinterProvider>();
    final settings = settingsProv.settings.copyWith(receiptWidth: _activeWidth);
    final screenSize = MediaQuery.of(context).size;
    final isNarrow = screenSize.width < 700;

    final bool isPending = widget.order is PendingOrder;
    final String billIdentifier = isPending
        ? (widget.order as PendingOrder).label
        : (widget.order as Order).orderNumber;

    final String custName = widget.order.customerName;
    final String? custPhone = widget.order.customerPhone;
    final String paymentMethod = widget.order.paymentMethod.toString().toUpperCase();
    final String createdAt = widget.order.createdAt;
    final List itemsList = widget.order.items;
    final double subtotal = widget.order.subtotal;
    final double discountAmount = widget.order.discountAmount;
    final String discountType = widget.order.discountType;
    final double discountValue = widget.order.discountValue;
    final double grandTotal = widget.order.grandTotal;
    final int itemCount = widget.order.itemCount;
    final int totalQuantity = widget.order.totalQuantity;

    final bool isPrinted = isPending ? ((widget.order as PendingOrder).isPrinted || _hasPrintedLocally) : true;

    return Dialog(
      backgroundColor: AppColors.darkCard,
      // Responsive inset padding – more room on mobile
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 10 : 24,
        vertical: isNarrow ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: screenSize.height * 0.92,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header bar ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.receipt, color: AppColors.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPending ? 'Print Draft Bill & Save' : 'Print & Receipt Preview',
                          style: const TextStyle(color: AppColors.darkText, fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$billIdentifier • ${Formatters.formatDate(createdAt)}',
                          style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11),
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

              // ── Content Area ─────────────────────────────────────────────
              Flexible(
                child: isNarrow
                    // MOBILE: Single column, scrollable
                    ? _buildMobileLayout(context, printerProv, settings, isPending, isPrinted,
                        billIdentifier, custName, custPhone, paymentMethod, createdAt, itemsList,
                        subtotal, discountAmount, discountType, discountValue, grandTotal, itemCount, totalQuantity)
                    // DESKTOP/WIDE: Side-by-side
                    : _buildWideLayout(context, printerProv, settings, isPending, isPrinted,
                        billIdentifier, custName, custPhone, paymentMethod, createdAt, itemsList,
                        subtotal, discountAmount, discountType, discountValue, grandTotal, itemCount, totalQuantity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wide layout (tablet/desktop) – receipt preview on left, controls on right
  Widget _buildWideLayout(
    BuildContext context,
    PrinterProvider printerProv,
    dynamic settings,
    bool isPending,
    bool isPrinted,
    String billIdentifier,
    String custName,
    String? custPhone,
    String paymentMethod,
    String createdAt,
    List itemsList,
    double subtotal,
    double discountAmount,
    String discountType,
    double discountValue,
    double grandTotal,
    int itemCount,
    int totalQuantity,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Thermal Receipt preview
        Expanded(
          flex: 6,
          child: _buildReceiptPreviewColumn(settings, isPending, isPrinted, billIdentifier, custName,
              custPhone, paymentMethod, createdAt, itemsList, subtotal, discountAmount, discountType,
              discountValue, grandTotal, itemCount, totalQuantity),
        ),

        const SizedBox(width: 16),

        // Right: Printer controls
        Expanded(
          flex: 4,
          child: _buildControlsColumn(context, printerProv, settings, isPending),
        ),
      ],
    );
  }

  /// Mobile layout – single column
  Widget _buildMobileLayout(
    BuildContext context,
    PrinterProvider printerProv,
    dynamic settings,
    bool isPending,
    bool isPrinted,
    String billIdentifier,
    String custName,
    String? custPhone,
    String paymentMethod,
    String createdAt,
    List itemsList,
    double subtotal,
    double discountAmount,
    String discountType,
    double discountValue,
    double grandTotal,
    int itemCount,
    int totalQuantity,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Printer controls at top on mobile
          _buildControlsColumn(context, printerProv, settings, isPending),
          const SizedBox(height: 16),

          // Receipt preview below controls
          _buildReceiptPreviewColumn(settings, isPending, isPrinted, billIdentifier, custName,
              custPhone, paymentMethod, createdAt, itemsList, subtotal, discountAmount, discountType,
              discountValue, grandTotal, itemCount, totalQuantity),
        ],
      ),
    );
  }

  Widget _buildReceiptPreviewColumn(
    dynamic settings,
    bool isPending,
    bool isPrinted,
    String billIdentifier,
    String custName,
    String? custPhone,
    String paymentMethod,
    String createdAt,
    List itemsList,
    double subtotal,
    double discountAmount,
    String discountType,
    double discountValue,
    double grandTotal,
    int itemCount,
    int totalQuantity,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls row: width toggle + print status tag
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Preview', style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                if (isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPrinted
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPrinted ? 'Printed' : 'Unprinted',
                      style: TextStyle(
                        color: isPrinted ? AppColors.primaryLight : AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // 58mm / 80mm toggle
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.darkInputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _activeWidth = '58mm'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _activeWidth == '58mm' ? AppColors.darkCard : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '58 mm',
                        style: TextStyle(
                          color: _activeWidth == '58mm' ? AppColors.darkText : AppColors.darkSubtext,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _activeWidth = '80mm'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _activeWidth == '80mm' ? AppColors.darkCard : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '80 mm',
                        style: TextStyle(
                          color: _activeWidth == '80mm' ? AppColors.darkText : AppColors.darkSubtext,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Thermal Paper Visual Box – limited height on wide layout, auto on mobile
        SizedBox(
          height: 360,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: _activeWidth == '58mm' ? 260 : 340,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF7),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Store Header
                    Text(
                      settings.businessName.toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      settings.address,
                      style: const TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Tel: ${settings.phone}',
                      style: const TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                    if (settings.gstin != null && settings.gstin!.isNotEmpty)
                      Text(
                        'GSTIN: ${settings.gstin}',
                        style: const TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'monospace'),
                        textAlign: TextAlign.center,
                      ),
                    const Divider(color: Colors.black54, thickness: 1),

                    // Bill Metadata
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('Bill: $billIdentifier',
                              style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(Formatters.formatTime(createdAt),
                            style: const TextStyle(color: Colors.black, fontSize: 9, fontFamily: 'monospace')),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${Formatters.formatDate(createdAt)}',
                            style: const TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'monospace')),
                        Text(paymentMethod,
                            style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Cust: $custName',
                          style: const TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (custPhone != null && custPhone.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Ph: $custPhone',
                            style: const TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'monospace')),
                      ),
                    const Divider(color: Colors.black54, thickness: 1),

                    // Table Headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('ITEM', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        Text('QTY  TOTAL', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ],
                    ),
                    const Divider(color: Colors.black38, thickness: 1),

                    // Items List
                    ...itemsList.map((item) {
                      final String name = (item is OrderItem) ? item.productName : item.name;
                      final int qty = item.quantity;
                      final String unit = item.unit;
                      final double unitPrice = item.unitPrice;
                      final double total = item.lineTotal;
                      final bool isCustom = item.isCustomPrice;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCustom)
                                  const Text(' (Spl)', style: TextStyle(color: Colors.green, fontSize: 8, fontFamily: 'monospace')),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '  $qty $unit @ ${settings.currencySymbol} ${unitPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.black87, fontSize: 8, fontFamily: 'monospace'),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${settings.currencySymbol} ${total.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(color: Colors.black54, thickness: 1),

                    // Totals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'monospace')),
                        Text('${settings.currencySymbol} ${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'monospace')),
                      ],
                    ),
                    if (discountAmount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Discount (${discountType == "percentage" ? "$discountValue%" : "Flat"}):',
                              style: const TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('-${settings.currencySymbol} ${discountAmount.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'monospace')),
                        ],
                      ),
                    const Divider(color: Colors.black, thickness: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL:', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        Text('${settings.currencySymbol} ${grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ],
                    ),
                    const Divider(color: Colors.black, thickness: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Items: $itemCount', style: const TextStyle(color: Colors.black54, fontSize: 8, fontFamily: 'monospace')),
                        Text('Total Qty: $totalQuantity', style: const TextStyle(color: Colors.black54, fontSize: 8, fontFamily: 'monospace')),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Footer
                    Text(
                      settings.receiptFooter,
                      style: const TextStyle(color: Colors.black87, fontSize: 8, fontStyle: FontStyle.italic, fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text('*** Powered by POS ***', style: TextStyle(color: Colors.black54, fontSize: 7, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsColumn(
    BuildContext context,
    PrinterProvider printerProv,
    dynamic settings,
    bool isPending,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hardware Connection Status Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkInputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hardware Status',
                      style: TextStyle(color: AppColors.darkSubtext, fontSize: 11, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: printerProv.status == PrinterStatus.connected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.darkCardBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      printerProv.status == PrinterStatus.connected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: printerProv.status == PrinterStatus.connected
                            ? AppColors.primaryLight
                            : AppColors.darkSubtext,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (printerProv.status == PrinterStatus.connected) ...[
                Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, color: AppColors.primaryLight, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        printerProv.deviceName ?? 'Thermal Printer',
                        style: const TextStyle(color: AppColors.darkText, fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('ESC/POS Direct Ready', style: TextStyle(color: AppColors.darkSubtext, fontSize: 9)),
              ] else ...[
                const Text('No Bluetooth thermal printer connected.',
                    style: TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _openPrinterModal,
                    icon: const Icon(LucideIcons.bluetooth, size: 14),
                    label: const Text('Pair Printer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Bluetooth Direct Print Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (printerProv.status != PrinterStatus.connected || printerProv.isPrinting)
                ? null
                : () async {
                    final res = await printerProv.printReceipt(
                      order: widget.order,
                      settings: settings,
                    );
                    if (res['success'] == true) {
                      _showSnackBar(res['message']);
                      _recordPrintSuccess();
                    } else {
                      _showSnackBar(res['message'], isError: true);
                    }
                  },
            icon: const Icon(LucideIcons.printer, size: 16),
            label: Text(
              printerProv.isPrinting ? 'Printing...' : 'Print via Bluetooth (ESC/POS)',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Save to Permanent Orders (Draft orders only)
        if (isPending && widget.onSavePendingOrder != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ready to Finalize?',
                    style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Deduct stock and record into permanent Orders history.',
                  style: TextStyle(color: AppColors.darkSubtext, fontSize: 10),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      widget.onSavePendingOrder!(widget.order as PendingOrder);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(LucideIcons.save, size: 14),
                    label: const Text('Save to Orders Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Close button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkText,
              side: const BorderSide(color: AppColors.darkCardBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}
