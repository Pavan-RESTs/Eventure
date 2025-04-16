import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:eventure/src/bottom_navigation_screen.dart';
import 'package:eventure/src/data_repository/event_model.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ICloudHelperFunctions {
  static final _supabase = Supabase.instance.client;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<AuthResponse?> loginWithEmail(
      String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      IDeviceUtils.showSnackBar("Success", "Login Successful");

      Get.offAll(const BottomNavigationScreen());
      return response;
    } on AuthException catch (e) {
      IDeviceUtils.showSnackBar("Error", e.message);
    } catch (e) {
      IDeviceUtils.showSnackBar("Error", "Something went wrong");
    }

    return null;
  }

  static Stream<List<EventModel>> streamEvents() {
    return _firestore
        .collection('Event Table')
        .snapshots()
        .asyncMap((snapshot) async {
      List<EventModel> events = [];

      for (var doc in snapshot.docs) {
        try {
          final event = EventModel.fromFirestore(doc);
          await event.initializeAdditionalData();
          events.add(event);
        } catch (e) {}
      }

      return events;
    });
  }

  static Future<String?> getUserId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("No Supabase user signed in");

      return user.id;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> hasUserLikedEvent(String userId, String eventId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('User Table')
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final likedEventsRaw = userDoc.data()?['liked_events'];

      final likedEvents = List<String>.from(likedEventsRaw ?? []);
      for (var id in likedEvents) {
        if (id == eventId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateEventLikes(String eventId, bool increment) async {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }

    try {
      final eventRef =
          FirebaseFirestore.instance.collection('Event Table').doc(eventId);

      // Verify document exists first
      final doc = await eventRef.get();
      if (!doc.exists) {
        throw Exception('Event document does not exist');
      }

      // Get current like count to prevent negative values
      final currentLikes = (doc.data()?['likes'] as int?) ?? 0;
      if (!increment && currentLikes <= 0) {
        return;
      }

      // Perform the update
      await eventRef.update({
        'likes': increment ? FieldValue.increment(1) : FieldValue.increment(-1)
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to update likes: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update likes: $e');
    }
  }
}
