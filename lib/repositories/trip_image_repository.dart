import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class TripImageRepository {
  static const String _projectId = 'csen268-s26-g4';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<String> uploadTripImage({
    required String tripId,
    required String localPath,
  }) async {
    final tripRef = _firestore.collection('trips').doc(tripId);
    final tripSnap = await tripRef.get();
    if (!tripSnap.exists) {
      throw Exception('Trip not found. Create or select a trip and try again.');
    }

    final bytes = _compressForUpload(await _readPhotoBytes(localPath));
    if (bytes.isEmpty) {
      throw Exception('Photo file is empty. Please take the picture again.');
    }

    Object? lastError;
    for (final bucket in _bucketCandidates) {
      try {
        return await _uploadToStorage(
          tripRef: tripRef,
          tripId: tripId,
          bytes: bytes,
          bucket: bucket,
        );
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

    // Firebase Storage not set up or blocked — save in Firestore so the app still works.
    debugPrint(
      'Storage upload failed ($lastError). Saving image in Firestore instead.',
    );
    return _saveToFirestoreAsDataUrl(tripRef, bytes);
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

  Future<String> _uploadToStorage({
    required DocumentReference<Map<String, dynamic>> tripRef,
    required String tripId,
    required Uint8List bytes,
    required String bucket,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef =
        _storageForBucket(bucket).ref().child('trips/$tripId/$fileName');

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
    await tripRef.update({
      'images': FieldValue.arrayUnion([downloadUrl]),
    });
    return downloadUrl;
  }

  Future<String> _saveToFirestoreAsDataUrl(
    DocumentReference<Map<String, dynamic>> tripRef,
    Uint8List jpegBytes,
  ) async {
    if (jpegBytes.length > 900000) {
      throw Exception(
        'Photo is too large for Firestore. Enable Firebase Storage in the console (Build > Storage > Get started).',
      );
    }
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(jpegBytes)}';
    await tripRef.update({
      'images': FieldValue.arrayUnion([dataUrl]),
    });
    return dataUrl;
  }

  Uint8List _compressForUpload(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final resized = img.copyResize(
      decoded,
      width: decoded.width > 1280 ? 1280 : decoded.width,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }

  Future<Uint8List> _readPhotoBytes(String localPath) async {
    if (kIsWeb) {
      return XFile(localPath).readAsBytes();
    }
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Photo file not found. Please take the picture again.');
    }
    return file.readAsBytes();
  }

  Future<void> removeTripImage({
    required String tripId,
    required String imageUrl,
  }) async {
    await _firestore.collection('trips').doc(tripId).update({
      'images': FieldValue.arrayRemove([imageUrl]),
    });

    if (imageUrl.startsWith('data:')) return;

    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    } catch (_) {
      // Storage file may already be gone.
    }
  }
}
