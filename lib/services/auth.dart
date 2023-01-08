import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialgame/player.dart';

import 'firestore.dart';

class AuthService {
  static String? get uid => FirebaseAuth.instance.currentUser?.uid;

  static final authStateChangesProvider =
      StreamProvider.autoDispose<User?>((ref) {
    // get FirebaseAuth from the provider below
    final userStream =
        ref.watch(Provider((ref) => FirebaseAuth.instance.authStateChanges()));
    // call a method that returns a Stream<User?>
    return userStream;
  });

  ///Takes uid as parameter
  static final appUserStreamProvider =
      StreamProvider.autoDispose.family<Player?, String>(
    (ref, uid) {
      final stream = FirestoreAPI.userRef(uid).snapshots();
      return stream
          .map((doc) => Player.fromJson(doc.data() as Map<String, dynamic>));
    },
  );

  static Future<Player> currentAppUser() =>
      FirestoreAPI.getUser(FirebaseAuth.instance.currentUser?.uid ?? '');

  static Future signUp(BuildContext context,
      {required String email,
      required String password,
      required String displayName}) async {
    //create user in firebase auth
    FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password)
        .then(
      (userCredential) {
        final uid = userCredential.user?.uid ?? '';
        return FirestoreAPI.userRef(uid).set(
          {
            'created_at': Timestamp.now(),
            'display_name': displayName,
            'email': email,
            'uid': uid,
          },
        );
      },
    ).catchError((e) {
      if (kDebugMode) {
        print(e);
      }
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(e.message.toString()),
          );
        },
      );
    });
  }
}
