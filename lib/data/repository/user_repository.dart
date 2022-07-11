import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../models/models.dart';

abstract class UserRepository {
  Future<auth.User?> signInEmailAndPassword(
    String email,
    String password,
  );
  Future<auth.User?> signUpWithEmailAndPassword(
    String email,
    String password,
  );
  Future<void> sendForgotPasswordEmail(String email);
  Future<void> signOut();
  Future<auth.User?> signInWithGoogle();
  Future<auth.User?> signInWithFacebook();
  Future<bool> changeEmailAddress(String newEmail, String currentPassword);
  Future<bool> changePassword(String currentPassword, String newPassword);
  bool get isSignedIn;
  auth.User? get currentUser;
  Stream<auth.User?> get userChanges;
  Future<User?> getUser({String? uid});
  bool isOwned(String userId);
  Future<bool> isFavorited(String id);
  Future<void> updateHost(Map<String, dynamic> host, File? image);
}

class UserRepositoryImpl implements UserRepository {
  final auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;
  final InternetConnectionChecker _connectionChecker;
  final FirebaseStorage _firebaseStorage;
  UserRepositoryImpl({
    auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firebaseFirestore,
    FirebaseStorage? firebaseStorage,
    required InternetConnectionChecker connectionChecker,
  })  : _firebaseAuth = firebaseAuth ?? auth.FirebaseAuth.instance,
        _firebaseFirestore = firebaseFirestore ?? FirebaseFirestore.instance,
        _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance,
        _connectionChecker = connectionChecker;

  @override
  Future<auth.User?> signInEmailAndPassword(
    String email,
    String password,
  ) async {
    final auth = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return auth.user;
  }

  @override
  Future<void> signOut() async {
    final googleSignedIn = await GoogleSignIn().isSignedIn();
    if (googleSignedIn) await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
  }

  @override
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  @override
  auth.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<auth.User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }
    final auth = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (auth.user != null) {
      _firebaseFirestore.collection('users').doc(auth.user!.uid).set({
        'uid': auth.user!.uid,
        'email': auth.user!.email,
      });
    }

    return auth.user;
  }

  @override
  Future<void> sendForgotPasswordEmail(String email) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<auth.User?> signInWithGoogle() async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }
    final googleUser = await GoogleSignIn().signIn();
    final googleAuth = await googleUser?.authentication;

    late final auth.OAuthCredential credential;
    try {
      credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
    } catch (err) {
      return null;
    }

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      await _firebaseFirestore.collection('users').doc(user.uid).get().then(
        (doc) {
          if (doc.exists) {
            doc.reference.set({
              'uid': user.uid,
              'displayName': user.displayName,
              'email': user.email,
            });
          }
        },
      );
    }

    return user;
  }

  @override
  Future<auth.User?> signInWithFacebook() async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }
    final loginResult = await FacebookAuth.instance.login();

    if (loginResult.accessToken == null) return null;

    final facebookAuthCredential = auth.FacebookAuthProvider.credential(
      loginResult.accessToken!.token,
    );

    final credential = await _firebaseAuth.signInWithCredential(
      facebookAuthCredential,
    );

    return credential.user;
  }

  @override
  Future<bool> changeEmailAddress(
    String newEmail,
    String currentPassword,
  ) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }
    bool success = false;

    final user = _firebaseAuth.currentUser;
    final credential = auth.EmailAuthProvider.credential(
      email: user!.email!,
      password: currentPassword,
    );

    final newCredential = await user.reauthenticateWithCredential(credential);
    final newUser = newCredential.user;

    if (newUser != null) {
      await newCredential.user!.updateEmail(newEmail);
      success = true;
    }
    return success;
  }

  @override
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }
    bool success = false;

    final user = _firebaseAuth.currentUser;
    final credential = auth.EmailAuthProvider.credential(
      email: user!.email!,
      password: currentPassword,
    );

    final newCredential = await user.reauthenticateWithCredential(credential);
    final newUser = newCredential.user;

    if (newUser != null) {
      await newCredential.user!.updatePassword(newPassword);
      success = true;
    }
    return success;
  }

  @override
  Stream<auth.User?> get userChanges => _firebaseAuth.userChanges();

  @override
  Future<User?> getUser({String? uid}) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }
    final authUser = _firebaseAuth.currentUser;

    if (authUser == null) {
      return null;
    }

    final userId = uid ?? authUser.uid;
    final doc = await _firebaseFirestore.collection('users').doc(userId).get();

    return User.fromJson(doc.data()!);
  }

  @override
  Future<bool> isFavorited(String id) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }

    final user = _firebaseAuth.currentUser;

    if (user == null) return false;

    final doc = await _firebaseFirestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(id)
        .get();
    return doc.exists;
  }

  @override
  bool isOwned(String userId) {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    return user.uid == userId;
  }

  @override
  Future<void> updateHost(Map<String, dynamic> host, File? image) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }

    final userId = currentUser?.uid;

    throwIf(userId == null, 'Couldn\'t retrieve user info.');

    String? url;
    if (image != null) {
      url = await (await _firebaseStorage
              .ref('$userId/${image.hashCode}.png')
              .putFile(image))
          .ref
          .getDownloadURL();
    }

    await _firebaseFirestore.collection('users').doc(userId).update({
      'hostName': host['hostName'],
      'hostPhone': host['hostPhone'],
      if (url != null) 'hostAvatar': url,
    });
  }
}
