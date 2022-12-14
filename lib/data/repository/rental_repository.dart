import 'dart:io';

import 'package:algolia/algolia.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../models/models.dart';

abstract class RentalRepository {
  Future<List<Rental>> getRentals(Map<String, dynamic> filters);
  Future<Rental> addRental(
    Rental rental,
    List<File?> images,
  );
  Future<Rental> updateRental(
    String id,
    Rental rental,
    List<File?>? images,
  );
  Future<void> archiveRental(String id);
  Future<void> unarchiveRental(String id);
  Future<List<Rental>> getSearchResults(String keyword);
  Future<void> setFavorited(Rental rental);
  Future<void> removeFavorited(Rental rental);
  Future<List<Rental>> getList({required String collection, String? userId});
  Future<void> deleteRental(String id);
}

class RentalRepositoryImpl implements RentalRepository {
  final InternetConnectionChecker _connectionChecker;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final Algolia _aloglia;

  RentalRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    FirebaseStorage? storage,
    required InternetConnectionChecker connectionChecker,
    required Algolia algolia,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _connectionChecker = connectionChecker,
        _aloglia = algolia;

  @override
  Future<List<Rental>> getRentals(Map<String, dynamic> filters) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }

    var query = _firestore
        .collection('rentals')
        .where('publishStatus', isEqualTo: PublishStatus.approved.name)
        .where(
          'propertyType',
          isEqualTo: (filters['propertyType'] as PropertyType?)?.value,
        )
        .where(
          'governorate',
          isEqualTo: (filters['governorate'] as Governorate?)?.value,
        )
        .where(
          'rentPeriod',
          isEqualTo: (filters['rentPeriod'] as RentPeriod?)?.value,
        )
        .where('region', isEqualTo: filters['region']);

    if (filters['priceTo'] != null || filters['priceFrom'] != null) {
      query = query
          .where(
            'price',
            isGreaterThanOrEqualTo: filters['priceFrom'],
            isLessThanOrEqualTo: filters['priceTo'],
          )
          .orderBy('price');
    }

    query = query.orderBy('createdAt', descending: true);

    return (await query.get())
        .docs
        .map((doc) => Rental.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<Rental> addRental(
    Rental rental,
    List<File?> imageFiles,
  ) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }
    final uid = _auth.currentUser!.uid;
    final doc = _firestore.collection('rentals').doc();

    final imageUrls = <String>[];
    for (final f in imageFiles) {
      if (f != null) {
        final task = await _storage
            .ref(
              '${doc.id}/${f.hashCode}.png',
            )
            .putFile(f);

        final url = await task.ref.getDownloadURL();
        imageUrls.add(url);
      }
    }

    final data = {
      ...rental.toJson(),
      'id': doc.id,
      'images': imageUrls,
      'userId': uid,
      'createdAt': Timestamp.now(),
      'publishStatus': PublishStatus.pending.name,
    };

    final batch = _firestore.batch();
    batch.set(doc, data);

    final userDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('rentals')
        .doc(doc.id);

    batch.set(userDoc, data);

    final result = batch.commit().then((_) async {
      final data = (await doc.get()).data();
      return Rental.fromJson(data!);
    });

    return result;
  }

  @override
  Future<Rental> updateRental(
    String id,
    Rental rental,
    List<File?>? imageFiles,
  ) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }

    final user = _auth.currentUser!;

    final imageUrls = rental.images;
    if (imageFiles != null) {
      for (final f in imageFiles) {
        if (f != null) {
          final task = await _storage
              .ref(
                '$id/${f.hashCode}.png',
              )
              .putFile(f);

          final url = await task.ref.getDownloadURL();
          imageUrls.add(url);
        }
      }
    }

    final doc = _firestore.collection('rentals').doc(id);

    final data = {
      ...rental.toJson(),
      'rejectReason': null,
      'publishStatus': PublishStatus.pending.name,
      'images': imageUrls,
    };

    final batch = _firestore.batch();
    batch.update(doc, data);

    final userDoc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rentals')
        .doc(id);
    batch.update(userDoc, data);

    final result = await batch.commit().then((_) async {
      final data = (await doc.get()).data();
      return Rental.fromJson(data!);
    });

    return result;
  }

  @override
  Future<void> archiveRental(String id) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }

    final uid = _auth.currentUser!.uid;
    final doc = _firestore.collection('rentals').doc(id);

    final batch = _firestore.batch();
    final data = {'publishStatus': PublishStatus.archived.name};
    batch.update(doc, data);

    final userDoc =
        _firestore.collection('users').doc(uid).collection('rentals').doc(id);
    batch.update(userDoc, data);

    await batch.commit();
  }

  @override
  Future<void> unarchiveRental(String id) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }
    final uid = _auth.currentUser!.uid;
    final doc = _firestore.collection('rentals').doc(id);

    final batch = _firestore.batch();
    final data = {'publishStatus': PublishStatus.approved.name};
    batch.update(doc, data);

    final userDoc =
        _firestore.collection('users').doc(uid).collection('rentals').doc(id);
    batch.update(userDoc, data);

    await batch.commit();
  }

  @override
  Future<List<Rental>> getSearchResults(String keyword) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }
    final snap =
        await _aloglia.instance.index('rentals').query(keyword).getObjects();

    return (snap.toMap()['hits'] as List)
        .where((element) => element['publishStatus'] == 'approved')
        .map((e) {
      return Rental.fromJson(
        e
          ..['createdAt'] = Timestamp.fromMillisecondsSinceEpoch(
            e['createdAt'],
          ),
      );
    }).toList();
  }

  @override
  Future<void> setFavorited(Rental rental) async {
    final user = _auth.currentUser;
    await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(rental.id)
        .set(rental.toJson());
  }

  @override
  Future<void> removeFavorited(Rental rental) async {
    final user = _auth.currentUser;
    await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(rental.id)
        .delete();
  }

  @override
  Future<List<Rental>> getList({
    required String collection,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser!.uid;
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection(collection)
        .where(
          'publishStatus',
          isEqualTo: userId != null ? PublishStatus.approved.name : null,
        )
        .get();
    return snap.docs.map((doc) => Rental.fromJson(doc.data())).toList();
  }

  @override
  Future<void> deleteRental(String id) async {
    if (!await _connectionChecker.hasConnection) {
      throw Exception('No internet connection');
    }

    final uid = _auth.currentUser!.uid;
    final doc = _firestore.collection('rentals').doc(id);

    final batch = _firestore.batch();
    final data = {'publishStatus': PublishStatus.deleted.name};
    batch.update(doc, data);

    final userDoc =
        _firestore.collection('users').doc(uid).collection('rentals').doc(id);
    batch.delete(userDoc);

    await batch.commit();
  }
}
