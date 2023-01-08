import 'package:flutter/material.dart';
import 'package:socialgame/ui/pages/login_page.dart';
import 'package:socialgame/ui/pages/signup_page.dart';

class LoginSignupPage extends StatelessWidget {
  const LoginSignupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('OWO'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Login'),
              Tab(text: 'Signup'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LoginPage(),
            SignupPage(),
          ],
        ),
      ),
    );
  }
}
