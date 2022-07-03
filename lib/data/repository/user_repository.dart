import 'package:flutter/material.dart';
//import 'package:FirebaseUserSignIn/utils/error_codes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class UserRepository {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  UserRepository({required this.firebaseAuth});

// signin with email and password
  Future<User?> signInEmailAndPassword(String email, String password) async {
    try {
      var auth = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return auth.user;
    } catch (e) {
      print(e.toString());
    }
  }

  // // sign In with google
  // Future<UserCredential> signInWithGoogle() async {
  //   // Trigger the authentication flow
  //   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

  //   // Obtain the auth details from the request
  //   final GoogleSignInAuthentication? googleAuth =
  //       await googleUser?.authentication;

  //   // Create a new credential
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth?.accessToken,
  //     idToken: googleAuth?.idToken,
  //   );

  //   // Once signed in, return the UserCredential
  //   return await FirebaseAuth.instance.signInWithCredential(credential);
  // }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // check signIn
  bool isSignedIn() {
    final currentUser = firebaseAuth.currentUser;
    return currentUser != null;
  }

  // get current user
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }
}