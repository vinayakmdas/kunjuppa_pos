import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kunjuppa_pos/main.dart';
import 'package:kunjuppa_pos/providers/auth_provider.dart';
import 'package:kunjuppa_pos/providers/cart_provider.dart';
import 'package:kunjuppa_pos/providers/customer_provider.dart';
import 'package:kunjuppa_pos/providers/order_provider.dart';
import 'package:kunjuppa_pos/providers/printer_provider.dart';
import 'package:kunjuppa_pos/providers/product_provider.dart';
import 'package:kunjuppa_pos/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CustomerProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => PrinterProvider()),
        ],
        child: const KunjuppaPosApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  });
}
