import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class UserProfileRepository {
  static const String _projectId = 'csen268-s26-g4';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection('users').doc(userId);

  FirebaseStorage _storageForBucket(String bucket) {
    return FirebaseStorage.instanceFor(bucket: bucket);
  }

  List<String> get _bucketCandidates {
    final configured = Firebase.app().options.storageBucket;
    final candidates = <String>[
      if (configured != null && configured.isNotEmpty) configured,
      '$_projectId.firebasestorage.app',
      '$_projectId.appspot.com',
    ];
    return candidates.toSet().toList();
  }

  Future<void> ensureUserDocument({
    required String userId,
    required String email,
  }) async {
    final ref = _userRef(userId);
    if ((await ref.get()).exists) return;

    final handleBase = email.split('@').first;
    await ref.set({
      'email': email,
      'name': handleBase,
      'handle': '@$handleBase',
      'friends': <String>[],
      'pending_invites': <String>[],
      'trips': <String>[],
      'locations_visited': <String>[],
      'equipment_images': <String>[],
      'profile_image': '',
    });
  }

  Future<String> uploadProfileImage({
    required String userId,
    required String localPath,
  }) async {
    final raw = await _readPhotoBytes(localPath);
    final bytes = await compute(
      _compressImageWorker,
      _CompressRequest(raw, profileAvatar: true),
    );
    return _uploadBytes(
      userId: userId,
      bytes: bytes,
      storagePath: 'users/$userId/profile',
      arrayField: null,
      setFields: (url) => {'profile_image': url},
    );
  }

  Future<String> addEquipmentImage({
    required String userId,
    required String localPath,
  }) async {
    final raw = await _readPhotoBytes(localPath);
    final bytes = await compute(
      _compressImageWorker,
      _CompressRequest(raw, profileAvatar: false),
    );
    return _uploadBytes(
      userId: userId,
      bytes: bytes,
      storagePath: 'users/$userId/equipment',
      arrayField: 'equipment_images',
      setFields: null,
    );
  }

  Future<void> removeEquipmentImage({
    required String userId,
    required String imageUrl,
  }) async {
    await _userRef(userId).update({
      'equipment_images': FieldValue.arrayRemove([imageUrl]),
    });

    if (imageUrl.startsWith('data:')) return;
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    } catch (_) {}
  }

  Future<void> updateProfileText({
    required String userId,
    String? name,
    String? handle,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (handle != null) {
      var h = handle.trim();
      if (h.isNotEmpty && !h.startsWith('@')) h = '@$h';
      updates['handle'] = h;
    }
    if (updates.isEmpty) return;
    await _userRef(userId).update(updates);
  }

  Future<String> _uploadBytes({
    required String userId,
    required Uint8List bytes,
    required String storagePath,
    required String? arrayField,
    required Map<String, dynamic> Function(String url)? setFields,
  }) async {
    if (bytes.isEmpty) throw Exception('Image file is empty.');

    final userRef = _userRef(userId);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    Object? lastError;

    for (final bucket in _bucketCandidates) {
      try {
        final storageRef = _storageForBucket(bucket)
            .ref()
            .child('$storagePath/$fileName');

        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask;

        if (snapshot.state != TaskState.success) {
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'upload-failed',
            message: 'Upload did not finish (state: ${snapshot.state}).',
          );
        }

        final downloadUrl = await snapshot.ref.getDownloadURL();
        await _applyUrl(
          userRef: userRef,
          url: downloadUrl,
          arrayField: arrayField,
          setFields: setFields,
        );
        return downloadUrl;
      } on FirebaseException catch (e) {
        lastError = e;
        if (_shouldTryNextBucket(e)) continue;
        rethrow;
      } catch (e) {
        lastError = e;
        if (_isStorageNotFoundError(e)) continue;
        rethrow;
      }
    }

    debugPrint(
      'Profile storage upload failed ($lastError). Saving image in Firestore instead.',
    );
    return _saveToFirestoreAsDataUrl(
      userRef: userRef,
      bytes: bytes,
      arrayField: arrayField,
      setFields: setFields,
    );
  }

  Future<String> _saveToFirestoreAsDataUrl({
    required DocumentReference<Map<String, dynamic>> userRef,
    required Uint8List bytes,
    required String? arrayField,
    required Map<String, dynamic> Function(String url)? setFields,
  }) async {
    if (bytes.length > 900000) {
      throw Exception(
        'Photo is too large for Firestore. Enable Firebase Storage in the console (Build > Storage > Get started).',
      );
    }
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    await _applyUrl(
      userRef: userRef,
      url: dataUrl,
      arrayField: arrayField,
      setFields: setFields,
    );
    return dataUrl;
  }

  Future<void> _applyUrl({
    required DocumentReference<Map<String, dynamic>> userRef,
    required String url,
    required String? arrayField,
    required Map<String, dynamic> Function(String url)? setFields,
  }) async {
    if (arrayField != null) {
      await userRef.update({arrayField: FieldValue.arrayUnion([url])});
    } else if (setFields != null) {
      await userRef.update(setFields(url));
    }
  }

  bool _shouldTryNextBucket(FirebaseException e) {
    return e.code == 'object-not-found' ||
        e.code == 'bucket-not-found' ||
        e.code == 'not-found';
  }

  bool _isStorageNotFoundError(Object e) {
    final message = e.toString().toLowerCase();
    return message.contains('object-not-found') ||
        message.contains('no object exists') ||
        message.contains('bucket-not-found');
  }

  Future<Uint8List> _readPhotoBytes(String localPath) async {
    if (kIsWeb) {
      return XFile(localPath).readAsBytes();
    }
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Image file not found.');
    }
    return file.readAsBytes();
  }
}

class _CompressRequest {
  const _CompressRequest(this.bytes, {required this.profileAvatar});

  final Uint8List bytes;
  final bool profileAvatar;
}

Uint8List _compressImageWorker(_CompressRequest request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) return request.bytes;

  final maxWidth = request.profileAvatar ? 480 : 960;
  final quality = request.profileAvatar ? 70 : 78;

  final resized = img.copyResize(
    decoded,
    width: decoded.width > maxWidth ? maxWidth : decoded.width,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
}
