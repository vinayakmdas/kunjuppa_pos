import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/printer_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/printer_config_modal.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => MainShellScreenState();
}

class MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  // GlobalKey to control the Scaffold drawer programmatically
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    PosScreen(),
    ProductsScreen(),
    CustomersScreen(),
    OrdersScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const [
    'Billing Dashboard',
    'POS Sales Counter',
    'Product Inventory',
    'Customer Directory',
    'Order History',
    'Settings & Hardware',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final printerProv = context.watch<PrinterProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        // On mobile, show a hamburger button that opens the drawer
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.menu, color: AppColors.darkText, size: 22),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Text(_titles[_currentIndex]),
        actions: [
          // Bluetooth Hardware Modal Shortcut Button
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const PrinterConfigModal(),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: printerProv.status == PrinterStatus.connected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.darkInputBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: printerProv.status == PrinterStatus.connected
                      ? AppColors.primaryLight
                      : AppColors.darkCardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.bluetooth,
                    size: 14,
                    color: printerProv.status == PrinterStatus.connected
                        ? AppColors.primaryLight
                        : AppColors.darkSubtext,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    printerProv.status == PrinterStatus.connected
                        ? (printerProv.deviceName ?? 'Printer')
                        : 'No Printer',
                    style: TextStyle(
                      color: printerProv.status == PrinterStatus.connected
                          ? AppColors.primaryLight
                          : AppColors.darkSubtext,
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
      // Drawer is always provided; on desktop it won't be triggered unless we call openDrawer()
      drawer: Drawer(
        backgroundColor: AppColors.darkCard,
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: const BoxDecoration(
                  color: AppColors.darkCard,
                  border: Border(bottom: BorderSide(color: AppColors.darkCardBorder)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.store, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.businessName,
                            style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.user?.name ?? 'Admin',
                            style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  children: [
                    _buildDrawerTile(0, 'Dashboard', LucideIcons.layoutDashboard),
                    _buildDrawerTile(1, 'POS Sales Counter', LucideIcons.shoppingCart),
                    _buildDrawerTile(2, 'Products Catalog', LucideIcons.package),
                    _buildDrawerTile(3, 'Customer Directory', LucideIcons.users),
                    _buildDrawerTile(4, 'Order History', LucideIcons.receipt),
                    _buildDrawerTile(5, 'Settings & Hardware', LucideIcons.settings),
                  ],
                ),
              ),

              const Divider(color: AppColors.darkCardBorder, height: 1),

              // Logout
              ListTile(
                leading: const Icon(LucideIcons.logOut, color: AppColors.danger, size: 20),
                title: const Text('Logout', style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.bold)),
                onTap: () {
                  // Close drawer first, then logout
                  Navigator.of(context).pop();
                  auth.logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          // Sidebar on Desktop / Tablet wide screen
          if (isDesktop)
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: AppColors.darkCard,
                border: Border(right: BorderSide(color: AppColors.darkCardBorder)),
              ),
              child: Column(
                children: [
                  // App Brand
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.store, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                settings.businessName,
                                style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text('POS Engine', style: TextStyle(color: AppColors.darkSubtext, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.darkCardBorder),

                  // Menu
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      children: [
                        _buildDesktopSidebarTile(0, 'Dashboard', LucideIcons.layoutDashboard),
                        _buildDesktopSidebarTile(1, 'POS Counter', LucideIcons.shoppingCart),
                        _buildDesktopSidebarTile(2, 'Products', LucideIcons.package),
                        _buildDesktopSidebarTile(3, 'Customers', LucideIcons.users),
                        _buildDesktopSidebarTile(4, 'Orders', LucideIcons.receipt),
                        _buildDesktopSidebarTile(5, 'Settings', LucideIcons.settings),
                      ],
                    ),
                  ),

                  // Footer Logout
                  const Divider(height: 1, color: AppColors.darkCardBorder),
                  ListTile(
                    dense: true,
                    leading: const Icon(LucideIcons.logOut, color: AppColors.danger, size: 18),
                    title: const Text('Sign Out', style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                    onTap: () {
                      auth.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

          // Main View Body
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),

      // Mobile Bottom Bar
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _navigateToIndex,
              backgroundColor: AppColors.darkCard,
              selectedItemColor: AppColors.primaryLight,
              unselectedItemColor: AppColors.darkSubtext,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              items: const [
                BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard, size: 20), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.shoppingCart, size: 20), label: 'POS'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.package, size: 20), label: 'Products'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.users, size: 20), label: 'Customers'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.receipt, size: 20), label: 'Orders'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.settings, size: 20), label: 'Settings'),
              ],
            ),
    );
  }

  /// Drawer tile – used inside the Drawer widget (safe to use Navigator.pop for drawer close)
  Widget _buildDrawerTile(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(icon, color: isSelected ? AppColors.primaryLight : AppColors.darkSubtext, size: 18),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primaryLight : AppColors.darkText,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        _navigateToIndex(index);
        // Pop the drawer route
        Navigator.of(context).pop();
      },
    );
  }

  /// Desktop sidebar tile – NOT inside a Drawer, so no Navigator.pop for drawer close
  Widget _buildDesktopSidebarTile(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(icon, color: isSelected ? AppColors.primaryLight : AppColors.darkSubtext, size: 18),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primaryLight : AppColors.darkText,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => _navigateToIndex(index),
    );
  }
}
