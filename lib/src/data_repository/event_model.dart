import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  DateTime created_at;
  String name;
  String description;
  String event_id;
  String user_id;
  String department_id;
  String venue_id;
  int likes;
  DateTime start_timestamp;
  DateTime end_timestamp;
  String status;
  String user = '';
  String department = '';
  String venue = '';
  String brochureImageUrl = '';
  List<dynamic> galleryImageUrls = [];

  EventModel(
      {required this.created_at,
      required this.name,
      required this.description,
      required this.event_id,
      required this.user_id,
      required this.department_id,
      required this.venue_id,
      required this.likes,
      required this.start_timestamp,
      required this.end_timestamp,
      required this.brochureImageUrl,
      required this.galleryImageUrls})
      : status = _determineStatus(start_timestamp, end_timestamp);

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EventModel(
      created_at: (data['created_at'] as Timestamp).toDate(),
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      event_id: doc.id,
      user_id: data['user_id'] ?? '',
      department_id: data['department_id'] ?? '',
      venue_id: data['venue_id'] ?? '',
      likes: data['likes'] ?? 0,
      start_timestamp: (data['start_timestamp'] as Timestamp).toDate(),
      end_timestamp: (data['end_timestamp'] as Timestamp).toDate(),
      brochureImageUrl: data['brochureImageUrl'] ?? '',
      galleryImageUrls: data['galleryImageFolderUrl'] ?? '',
    );
  }

  static String _determineStatus(DateTime start, DateTime end) {
    final now = DateTime.now();
    if (now.isBefore(start)) {
      return 'upcoming';
    } else if (now.isAfter(end)) {
      return 'completed';
    } else {
      return 'live';
    }
  }

  Future<void> initializeAdditionalData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('User Table')
          .doc(user_id)
          .get();
      if (userDoc.exists) {
        user = userDoc['name'] ?? 'Unknown User';
      }

      DocumentSnapshot departmentDoc = await FirebaseFirestore.instance
          .collection('Department Table')
          .doc(department_id)
          .get();
      if (departmentDoc.exists) {
        department = departmentDoc['name'] ?? 'Unknown Department';
      }

      DocumentSnapshot venueDoc = await FirebaseFirestore.instance
          .collection('Venue Table')
          .doc(venue_id)
          .get();
      if (venueDoc.exists) {
        venue = venueDoc['name'] ?? 'Unknown Venue';
      }
    } catch (e) {
      print('Error fetching additional data: $e');
    }
  }
}
