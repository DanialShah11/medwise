import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'modules/auth_module/login.dart';
import 'services/local_notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Medwise/modules/expiry_alerts/controller/expiry_controller.dart';
import 'utils/theme.dart'; // ✅ Import your theme file
import 'package:Medwise/modules/medicine_tracking/screens/view_medicines_screen.dart';
import 'package:Medwise/modules/report_generation/screens/report_home_screen.dart';
import 'package:Medwise/modules/barcode_scanning/screens/barcode_home_screen.dart';
import 'package:Medwise/modules/expiry_alerts/screens/expiry_alerts_screen.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      LocalNotificationService.initialize(context);
      await ExpiryController().scheduleAllNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy Inventory',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      // theme: appTheme, // ✅ Apply the global app theme
      home: const LogIn(),
    );
  }
}
