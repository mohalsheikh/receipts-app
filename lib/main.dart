import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Locker',
      debugShowCheckedModeBanner: false,
      theme: buildModernTheme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<User?> _ensureAuth;

  Future<User?> _signIn() async {
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      return cred.user;
    } catch (e) {
      debugPrint('Firebase anonymous auth error: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureAuth = _signIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _ensureAuth,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sign-in failed. Check Firebase config and enable Anonymous sign-in.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _ensureAuth = _signIn();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return AppShell(uid: user.uid);
      },
    );
  }
}
