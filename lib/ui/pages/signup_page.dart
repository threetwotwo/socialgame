import 'package:flutter/material.dart';
import 'package:socialgame/services/auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Name',
            ),
          ),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              hintText: 'Email',
            ),
          ),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(
              hintText: 'Password',
            ),
          ),
          TextButton(
            onPressed: () async {
              // try {
              //   await FirebaseAuth.instance.signInWithEmailAndPassword(
              //     email: emailController.text,
              //     password: passwordController.text,
              //   );
              // } on FirebaseAuthException catch (e) {
              //   print(e);
              //   showDialog(
              //     context: context,
              //     builder: (_) {
              //       return AlertDialog(
              //         title: Text(e.message.toString()),
              //       );
              //     },
              //   );
              // }
              AuthService.signUp(
                context,
                email: emailController.text,
                password: passwordController.text,
                displayName: nameController.text,
              );
            },
            child: const Text('Sign up'),
          ),
        ],
      ),
    );
  }
}
