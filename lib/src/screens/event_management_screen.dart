import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:eventure/src/functions/cloud_helper_functions.dart';
import 'package:eventure/src/widgets/create_event_popup.dart';
import 'package:eventure/src/widgets/custom_app_bar.dart';
import 'package:eventure/src/widgets/event_card.dart';
import 'package:eventure/src/widgets/event_details_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax/iconsax.dart';
import 'package:searchable_listview/searchable_listview.dart';

import '../data_repository/event_model.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  TextEditingController searchTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bool isDark = IDeviceUtils.isDarkMode(context);
    final double screenHeight = IDeviceUtils.getScreenHeight(context);
    final double screenWidth = IDeviceUtils.getScreenWidth(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showCreateEventPopup(context);
        },
        backgroundColor: IColors.primary,
        child: Icon(
          Iconsax.calendar_add,
          color: IColors.grey,
        ),
      ),
      appBar: CustomAppBar(
        isDark: isDark,
        onRefreshPressed: () {
          setState(() {});
        },
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: StreamBuilder<List<EventModel>>(
          stream:
              ICloudHelperFunctions.streamEvents() as Stream<List<EventModel>>,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: SpinKitWaveSpinner(
                size: 90,
                waveColor: Colors.lightBlueAccent,
                color: IColors.primary,
              ));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyWidget();
            }

            final events = snapshot.data!;

            return SearchableList<EventModel>(
                searchTextController: searchTextController,
                displayClearIcon: false,
                displaySearchIcon: false,
                searchFieldPadding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
                initialList: events,
                filter: (query) => events
                    .where((event) =>
                        event.name
                            .toLowerCase()
                            .contains(query.toLowerCase()) ||
                        event.description
                            .toLowerCase()
                            .contains(query.toLowerCase()) ||
                        event.venue
                            .toLowerCase()
                            .contains(query.toLowerCase()) ||
                        event.status
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                    .toList(),
                emptyWidget: _buildEmptyWidget(),
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 800));
                  setState(() {});
                },
                inputDecoration: InputDecoration(
                  hintText: "Search events, locations...",
                  hintStyle: TextStyle(
                    color: isDark ? IColors.grey : IColors.darkGrey,
                    fontSize: 15,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Iconsax.search_normal_1,
                      color: IColors.primary,
                      size: 22,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      searchTextController.clear();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: IColors.primary,
                      size: 22,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark ? IColors.darkContainer : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: IColors.primary,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: IColors.primary,
                      width: 1,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: IColors.grey,
                      width: 1,
                    ),
                  ),
                ),
                cursorColor: IColors.primary,
                textStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
                searchFieldHeight: 50,
                closeKeyboardWhenScrolling: true,
                // In your itemBuilder within EventManagementScreen:
                itemBuilder: (event) {
                  return FutureBuilder<String>(
                    future: ICloudHelperFunctions.getPublicBrochureUrl(
                        event.brochureImageUrl),
                    builder: (context, imageSnapshot) {
                      return FutureBuilder<String?>(
                        future: ICloudHelperFunctions.getUserId(),
                        builder: (context, userIdSnapshot) {
                          return FutureBuilder<bool>(
                            future: ICloudHelperFunctions.hasUserLikedEvent(
                                userIdSnapshot.data ?? '', event.event_id),
                            builder: (context, likeSnapshot) {
                              return EventCard(
                                imageUrl: imageSnapshot.data ?? '',
                                title: event.name,
                                description: event.description,
                                likeCount: event.likes,
                                location: event.venue,
                                status: event.status,
                                isLiked: likeSnapshot.data ?? false,
                                eventId: event.event_id,
                                onViewDetails: () {
                                  showEventDetailsPopup(
                                      context, event, imageSnapshot.data ?? '');
                                },
                                onLikeToggled: (isLiked) async {
                                  try {
                                    final userId = userIdSnapshot.data;
                                    if (userId == null) return;

                                    final userRef = FirebaseFirestore.instance
                                        .collection('User Table')
                                        .doc(userId);

                                    if (isLiked) {
                                      ICloudHelperFunctions.updateEventLikes(
                                          event.event_id, true);
                                      await userRef.update({
                                        'liked_events': FieldValue.arrayUnion(
                                            [event.event_id])
                                      });
                                    } else {
                                      ICloudHelperFunctions.updateEventLikes(
                                          event.event_id, false);
                                      await userRef.update({
                                        'liked_events': FieldValue.arrayRemove(
                                            [event.event_id])
                                      });
                                    }
                                  } catch (e) {
                                    throw e; // This will trigger the error handling in EventCard
                                  }
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.calendar_remove,
            size: 64,
            color: IColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            "No events found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Try adjusting your search",
            style: TextStyle(
              fontSize: 14,
              color: IColors.darkerGrey,
            ),
          ),
        ],
      ),
    );
  }
}
