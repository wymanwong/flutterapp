import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class FirestoreService<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath;

  FirestoreService(this.collectionPath);

  CollectionReference<Map<String, dynamic>> get collection =>
      _firestore.collection(collectionPath);

  T fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc);
  Map<String, dynamic> toFirestore(T item);

  // Create
  Future<String> create(T item) async {
    final docRef = await collection.add(toFirestore(item));
    return docRef.id;
  }

  // Read
  Future<T?> get(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists) return null;
    return fromFirestore(doc);
  }

  Future<List<T>> getAll() async {
    final querySnapshot = await collection.get();
    return querySnapshot.docs.map(fromFirestore).toList();
  }

  Stream<List<T>> streamAll() {
    return collection.snapshots().map(
          (snapshot) => snapshot.docs.map(fromFirestore).toList(),
        );
  }

  Stream<T?> streamOne(String id) {
    return collection.doc(id).snapshots().map(
          (doc) => doc.exists ? fromFirestore(doc) : null,
        );
  }

  // Update
  Future<void> update(String id, T item) async {
    await collection.doc(id).update(toFirestore(item));
  }

  Future<void> set(String id, T item) async {
    await collection.doc(id).set(toFirestore(item));
  }

  // Delete
  Future<void> delete(String id) async {
    await collection.doc(id).delete();
  }

  // Query
  Query<Map<String, dynamic>> where(
    String field, {
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
    bool? isNull,
  }) {
    return collection.where(
      field,
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      arrayContains: arrayContains,
      arrayContainsAny: arrayContainsAny,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
      isNull: isNull,
    );
  }

  Future<List<T>> query(
    Query<Map<String, dynamic>> query, {
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    Query<Map<String, dynamic>> finalQuery = query;

    if (orderBy != null) {
      finalQuery = finalQuery.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      finalQuery = finalQuery.limit(limit);
    }

    final querySnapshot = await finalQuery.get();
    return querySnapshot.docs.map(fromFirestore).toList();
  }

  Stream<List<T>> streamQuery(
    Query<Map<String, dynamic>> query, {
    int? limit,
    String? orderBy,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> finalQuery = query;

    if (orderBy != null) {
      finalQuery = finalQuery.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      finalQuery = finalQuery.limit(limit);
    }

    return finalQuery.snapshots().map(
          (snapshot) => snapshot.docs.map(fromFirestore).toList(),
        );
  }
} 