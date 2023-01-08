import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialgame/services/auth.dart';
import 'package:socialgame/ui/pages/home_page.dart';
import 'package:socialgame/ui/pages/login_signup_page.dart';

class App extends ConsumerWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(AuthService.authStateChangesProvider);

    return authStateAsync.when(
      data: (user) => user != null ? const HomePage() : const LoginSignupPage(),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
