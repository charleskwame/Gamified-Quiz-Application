import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://sjvkriacpjhakxvnsypj.supabase.co',
    publishableKey: 'sb_publishable_tANIawXiusflqGzO53cjKg_j5plgJIC',
  );

  // Wait for Firebase Auth to restore any persisted session before the UI
  // renders. Without this, _auth.currentUser is null on cold start even
  // though a valid encrypted token exists on disk, causing the app to
  // present the guest/unauth UI briefly before resolving — or permanently
  // if R8 has stripped the KeyStore/crypto classes needed for persistence.
  await AuthService().waitForSessionRestore();

  runApp(const MyApp());
}
