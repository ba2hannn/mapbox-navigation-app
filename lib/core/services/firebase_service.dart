import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;
  FirebaseStorage get storage => _storage;

  // Current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Collections
  CollectionReference get vehicles => _firestore.collection('vehicles');
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get routes => _firestore.collection('routes');
  CollectionReference get tollBooths => _firestore.collection('toll_booths');

  // User-specific collections
  CollectionReference userVehicles(String userId) =>
      users.doc(userId).collection('vehicles');

  CollectionReference userRoutes(String userId) =>
      users.doc(userId).collection('routes');

  CollectionReference userFavorites(String userId) =>
      users.doc(userId).collection('favorites');
}
