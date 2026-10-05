import 'package:flutter/material.dart';
import 'package:kunjuppa_pos/widgets/bluetooth_helper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/business_settings.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/printer_config_modal.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final _currencySymbolController = TextEditingController();
  final _currencyCodeController = TextEditingController();
  final _receiptFooterController = TextEditingController();
  final _lowStockController = TextEditingController();
  String _receiptWidth = '80mm';

  @override
  void initState() {
    super.initState();
    _fillFromSettings(context.read<SettingsProvider>().settings);
  }

  void _fillFromSettings(BusinessSettings s) {
    _businessNameController.text = s.businessName;
    _phoneController.text = s.phone;
    _addressController.text = s.address;
    _emailController.text = s.email;
    _gstinController.text = s.gstin ?? '';
    _currencySymbolController.text = s.currencySymbol;
    _currencyCodeController.text = s.currencyCode;
    _receiptFooterController.text = s.receiptFooter;
    _lowStockController.text = s.lowStockThreshold.toString();
    _receiptWidth = s.receiptWidth;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _currencySymbolController.dispose();
    _currencyCodeController.dispose();
    _receiptFooterController.dispose();
    _lowStockController.dispose();
    super.dispose();
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

  void _handleSaveSettings() {
    final settingsProv = context.read<SettingsProvider>();
    final newSettings = BusinessSettings(
      businessName: _businessNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
      gstin: _gstinController.text.trim().isEmpty
          ? null
          : _gstinController.text.trim(),
      currencySymbol: _currencySymbolController.text.trim(),
      currencyCode: _currencyCodeController.text.trim(),
      receiptWidth: _receiptWidth,
      receiptFooter: _receiptFooterController.text,
      lowStockThreshold: int.tryParse(_lowStockController.text) ?? 15,
      defaultPaymentMethod: settingsProv.settings.defaultPaymentMethod,
    );

    settingsProv.updateSettings(newSettings);
    _showSnackBar('Store settings saved successfully!');
  }

  void _handleResetData() async {
    await StorageService.resetAllData();
    if (!mounted) return;

    context.read<SettingsProvider>().loadSettings();
    context.read<ProductProvider>().loadProducts();
    context.read<CustomerProvider>().loadCustomers();
    context.read<OrderProvider>().loadOrders();

    final s = context.read<SettingsProvider>().settings;
    setState(() => _fillFromSettings(s));

    _showSnackBar('Database reset to initial AED sample catalog.');
  }

  /// Turns Bluetooth on automatically (system prompt on Android),
  /// then opens the printer pairing dialog.
  Future<void> _openPrinterModal() async {
    final ok = await BluetoothHelper.ensureOn();
    if (!mounted) return;
    if (!ok) {
      _showSnackBar('Bluetooth is off or permission denied.', isError: true);
      return;
    }
    showDialog(context: context, builder: (_) => const PrinterConfigModal());
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  InputDecoration _inputDeco(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.darkSubtext, fontSize: 12),
      floatingLabelStyle:
          const TextStyle(color: AppColors.primaryLight, fontSize: 12),
      hintStyle: TextStyle(
          color: AppColors.darkSubtext.withOpacity(0.5), fontSize: 12),
      prefixIcon: Icon(icon, size: 18, color: AppColors.primaryLight),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                    color: AppColors.darkSubtext, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Two fields side by side on wide screens, stacked on narrow phones.
  Widget _twoCols(Widget a, Widget b) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 420) {
        return Column(children: [a, const SizedBox(height: 14), b]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _card(
                child: _sectionTitle(
                  LucideIcons.settings,
                  'System & Hardware Configuration',
                  'Store profile, printer layout and database backups',
                ),
              ),
              const SizedBox(height: 16),

              // Store profile
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      LucideIcons.store,
                      'Retail Store Profile',
                      'Shown on receipts and reports',
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _businessNameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                          color: AppColors.darkText, fontSize: 14),
                      decoration: _inputDeco(
                          'Business / Store Name *', LucideIcons.building2),
                    ),
                    const SizedBox(height: 14),
                    _twoCols(
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            color: AppColors.darkText, fontSize: 14),
                        decoration:
                            _inputDeco('Contact Phone *', LucideIcons.phone),
                      ),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                            color: AppColors.darkText, fontSize: 14),
                        decoration:
                            _inputDeco('Store Email', LucideIcons.mail),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      minLines: 1,
                      style: const TextStyle(
                          color: AppColors.darkText, fontSize: 14),
                      decoration:
                          _inputDeco('Store Address *', LucideIcons.mapPin),
                    ),
                    const SizedBox(height: 14),
                    _twoCols(
                      TextField(
                        controller: _gstinController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        decoration:
                            _inputDeco('GSTIN / Tax ID', LucideIcons.receipt),
                      ),
                      TextField(
                        controller: _lowStockController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: AppColors.darkText, fontSize: 14),
                        decoration: _inputDeco(
                            'Low Stock Limit *', LucideIcons.packageMinus),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Receipt & hardware
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      LucideIcons.printer,
                      'Receipt & Hardware',
                      'Printer, paper size and footer',
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _openPrinterModal,
                        icon: const Icon(LucideIcons.bluetooth, size: 16),
                        label: const Text(
                          'Pair Bluetooth Printer',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _twoCols(
                      TextField(
                        controller: _currencySymbolController,
                        style: const TextStyle(
                            color: AppColors.darkText, fontSize: 14),
                        decoration: _inputDeco(
                            'Currency Symbol *', LucideIcons.badgeDollarSign),
                      ),
                      DropdownButtonFormField<String>(
                        value: _receiptWidth,
                        isExpanded: true,
                        dropdownColor: AppColors.darkCard,
                        style: const TextStyle(
                            color: AppColors.darkText, fontSize: 14),
                        decoration: _inputDeco(
                            'Receipt Roll Width *', LucideIcons.ruler),
                        items: const [
                          DropdownMenuItem(
                              value: '58mm', child: Text('58 mm (2-inch)')),
                          DropdownMenuItem(
                              value: '80mm', child: Text('80 mm (3-inch)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _receiptWidth = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _receiptFooterController,
                      maxLines: 2,
                      style: const TextStyle(
                          color: AppColors.darkText, fontSize: 14),
                      decoration: _inputDeco(
                        'Receipt Footer Message',
                        LucideIcons.messageSquare,
                        hint: 'Thank you, visit again!',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _handleSaveSettings,
                  icon: const Icon(LucideIcons.save, size: 16),
                  label: const Text(
                    'Save Store Settings',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Data & account
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      LucideIcons.database,
                      'Data Reset & Account',
                      'Reset to sample AED catalog or sign out',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => ConfirmDialog(
                                title: 'Reset All Data',
                                message:
                                    'Reset all products, orders, and customers to default seed catalog?',
                                onConfirm: _handleResetData,
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.rotateCcw, size: 14),
                          label: const Text('Reset Sample Data'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            auth.logout();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          },
                          icon: const Icon(LucideIcons.logOut, size: 14),
                          label: const Text('Sign Out',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}