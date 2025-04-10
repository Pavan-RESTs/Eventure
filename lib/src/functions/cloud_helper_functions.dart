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

      Get.offAll(BottomNavigationScreen());
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
          print("Loaded event: ${event.name}");
        } catch (e) {
          print("❌ Error creating EventModel: $e");
        }
      }

      return events;
    });
  }

  static Future<String> getPublicBrochureUrl(String path) async {
    final String publicUrl = Supabase.instance.client.storage
        .from('event-bucket')
        .getPublicUrl(path);
    return publicUrl;
  }

  static Future<String?> getUserId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("No Supabase user signed in");

      return user.id;
    } catch (e) {
      print('Error getting Supabase user ID: $e');
      return null;
    }
  }

  static Future<bool> hasUserLikedEvent(String userId, String eventId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('User Table')
          .doc(userId)
          .get();

      print("UserDoc Exists: ${userDoc.exists}");
      print("User Data: ${userDoc.data()}");

      if (!userDoc.exists) return false;

      final likedEventsRaw = userDoc.data()?['liked_events'];
      print("Raw liked_events: $likedEventsRaw");

      final likedEvents = List<String>.from(likedEventsRaw ?? []);
      print("Parsed liked_events: $likedEvents");
      print("Checking if likedEvents contains eventId: '$eventId'");
      for (var id in likedEvents) {
        if (id == eventId) {
          print("YUess");
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking liked event: $e');
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
        print('Like count already at minimum (0)');
        return;
      }

      // Perform the update
      await eventRef.update({
        'likes': increment ? FieldValue.increment(1) : FieldValue.increment(-1)
      });

      print(
          'Successfully ${increment ? 'incremented' : 'decremented'} likes for event $eventId');
    } on FirebaseException catch (e) {
      print('Firestore error updating likes: ${e.code} - ${e.message}');
      throw Exception('Failed to update likes: ${e.message}');
    } catch (e) {
      print('Unexpected error updating likes: $e');
      throw Exception('Failed to update likes: $e');
    }
  }
}
