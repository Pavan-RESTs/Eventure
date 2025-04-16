import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:eventure/src/data_repository/event_model.dart';
import 'package:eventure/src/functions/cloud_helper_functions.dart';
import 'package:eventure/src/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  String _filterStatus = 'All';
  final List<String> _statusOptions = [
    'All',
    'Upcoming',
    'Live',
    'Completed',
    'Cancelled'
  ];
  bool _isLoading = false;
  final _maxGalleryImages = 5;

  @override
  Widget build(BuildContext context) {
    final bool isDark = IDeviceUtils.isDarkMode(context);
    final double screenWidth = IDeviceUtils.getScreenWidth(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: "My Events",
        isDark: isDark,
        onRefreshPressed: () {
          setState(() {});
        },
      ),
      body: Column(
        children: [
          _buildStatusFilter(isDark),
          Expanded(
            child: FutureBuilder<String?>(
              future: ICloudHelperFunctions.getUserId(),
              builder: (context, userIdSnapshot) {
                if (userIdSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SpinKitWaveSpinner(
                      size: 90,
                      waveColor: Colors.lightBlueAccent,
                      color: IColors.primary,
                    ),
                  );
                }

                if (!userIdSnapshot.hasData || userIdSnapshot.data == null) {
                  return const Center(
                    child: Text("Please login to view your events"),
                  );
                }

                final userId = userIdSnapshot.data!;
                return StreamBuilder<List<EventModel>>(
                  stream: _getUserEvents(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SpinKitWaveSpinner(
                          size: 90,
                          waveColor: Colors.lightBlueAccent,
                          color: IColors.primary,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyWidget();
                    }

                    var events = snapshot.data!;
                    if (_filterStatus != 'All') {
                      events = events
                          .where((event) =>
                              event.status.toLowerCase() ==
                              _filterStatus.toLowerCase())
                          .toList();
                    }

                    return _isLoading
                        ? const Center(
                            child: SpinKitWaveSpinner(
                              size: 90,
                              waveColor: Colors.lightBlueAccent,
                              color: IColors.primary,
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04, vertical: 12),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              return _buildEventListItem(
                                  event, isDark, context);
                            },
                          );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(bool isDark) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? IColors.darkContainer : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusOptions.length,
        itemBuilder: (context, index) {
          final status = _statusOptions[index];
          final isSelected = status == _filterStatus;

          return GestureDetector(
            onTap: () {
              setState(() {
                _filterStatus = status;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getStatusColor(status.toLowerCase())
                    : (isDark
                        ? Colors.black12
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? _getStatusColor(status.toLowerCase())
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _getStatusColor(status.toLowerCase())
                              .withValues(alpha: 0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status.toLowerCase()),
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.white70
                            : _getStatusColor(status.toLowerCase())),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Iconsax.calendar_1;
      case 'live':
        return Iconsax.play_circle;
      case 'completed':
        return Iconsax.tick_circle;
      case 'cancelled':
        return Iconsax.slash;
      default:
        return Iconsax.filter;
    }
  }

  Widget _buildEventListItem(
      EventModel event, bool isDark, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? IColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getStatusBorderColor(event.status, isDark),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image Banner
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Event Image
                  CachedNetworkImage(
                    imageUrl:
                        "https://bnpdmwasofqiztyiwewo.supabase.co/storage/v1/object/public/event-bucket/${event.brochureImageUrl}",
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stackTrace) => Container(
                      color: IColors.accent.withValues(alpha: 0.2),
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            color: IColors.primary),
                      ),
                    ),
                    progressIndicatorBuilder:
                        (context, child, loadingProgress) {
                      return Container(
                        color: IColors.accent.withValues(alpha: 0.2),
                        child: const Center(
                          child: SpinKitRotatingCircle(
                            color: IColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Event title and date
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  event.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(event.status),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  event.status.capitalize(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.calendar,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getEventDateTimeRange(event),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Event details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Time Row
                Row(
                  children: [
                    const Icon(
                      Iconsax.timer_start,
                      size: 16,
                      color: IColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "From: ${DateFormat('MMM dd, yyyy • hh:mm a').format(event.start_timestamp)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Iconsax.timer_pause,
                      size: 16,
                      color: IColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "To: ${DateFormat('MMM dd, yyyy • hh:mm a').format(event.end_timestamp)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Venue
                Row(
                  children: [
                    const Icon(
                      Iconsax.location,
                      size: 16,
                      color: IColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.venue,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Department
                Row(
                  children: [
                    const Icon(
                      Iconsax.building,
                      size: 16,
                      color: IColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.department,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Likes
                Row(
                  children: [
                    const Icon(
                      Iconsax.heart,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${event.likes} Likes",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Upload Gallery Images Button
                    _buildActionButton(
                      icon: Iconsax.gallery,
                      label: "Gallery",
                      color: IColors.info,
                      onPressed: () => _showGalleryDialog(event),
                    ),
                    // Cancel Event Button
                    _buildActionButton(
                      icon: Iconsax.slash,
                      label: "Cancel",
                      color: IColors.error,
                      onPressed: () => _cancelEvent(event.event_id),
                      enabled: event.status.toLowerCase() != 'cancelled' &&
                          event.status.toLowerCase() != 'completed',
                    ),
                    // Delete Event Button
                    _buildActionButton(
                      icon: Iconsax.trash,
                      label: "Delete",
                      color: Colors.red,
                      onPressed: () => _deleteEvent(event.event_id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEventDateTimeRange(EventModel event) {
    final startDate = DateFormat('MMM dd, yyyy').format(event.start_timestamp);
    final endDate = DateFormat('MMM dd, yyyy').format(event.end_timestamp);

    // If same day event
    if (startDate == endDate) {
      return "$startDate • ${DateFormat('hh:mm a').format(event.start_timestamp)} - ${DateFormat('hh:mm a').format(event.end_timestamp)}";
    } else {
      return "$startDate - $endDate";
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon, size: 18, color: enabled ? color : Colors.grey),
          label: Text(
            label,
            style: TextStyle(
              color: enabled ? color : Colors.grey,
              fontSize: 14,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: color,
            backgroundColor: enabled
                ? color.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: enabled
                    ? color.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGalleryDialog(EventModel event) async {
    await showDialog(
      context: context,
      builder: (context) => _buildGalleryDialog(event),
    );
  }

  Widget _buildGalleryDialog(EventModel event) {
    const String _supabasePublicUrl =
        "https://bnpdmwasofqiztyiwewo.supabase.co/storage/v1/object/public/event-bucket/";
    final bool isDark = IDeviceUtils.isDarkMode(context);
    final Color backgroundColor = isDark ? IColors.dark : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subtleColor = isDark ? Colors.white70 : Colors.black54;
    final Color borderColor = isDark ? Colors.white12 : Colors.black12;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : Colors.black12,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: IDeviceUtils.getScreenHeight(context) * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enhanced Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.gallery,
                        color: IColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Event Gallery",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: subtleColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Gallery Images Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: event.galleryImageUrls.isEmpty
                    ? Container(
                        margin: const EdgeInsets.symmetric(vertical: 30),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.gallery,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No gallery images yet",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: subtleColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Add images to showcase this event",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                "${event.galleryImageUrls.length} of $_maxGalleryImages images",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: subtleColor,
                                ),
                              ),
                            ),
                            Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black12
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: borderColor, width: 1),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    for (int i = 0;
                                        i < event.galleryImageUrls.length;
                                        i++)
                                      Stack(
                                        children: [
                                          Container(
                                            height: 200,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDark
                                                      ? Colors.black26
                                                      : Colors.black12,
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Material(
                                                color: IColors.accent
                                                    .withValues(alpha: 0.1),
                                                child: InkWell(
                                                  onTap: () {
                                                    // Could add image preview functionality here
                                                  },
                                                  child: CachedNetworkImage(
                                                    errorWidget: (context,
                                                        error, stackTrace) {
                                                      // Error builder content remains the same
                                                      return Container(
                                                        color: IColors.accent
                                                            .withValues(
                                                                alpha: 0.2),
                                                        child: Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                color: IColors
                                                                    .primary,
                                                                size: 28,
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                "Failed to load",
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      subtleColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    imageUrl:
                                                        "$_supabasePublicUrl${event.galleryImageUrls[i]}"
                                                            .trim(),
                                                    fit: BoxFit.cover,
                                                    progressIndicatorBuilder:
                                                        (context, child,
                                                            loadingProgress) {
                                                      // Loading builder content remains the same
                                                      return Container(
                                                        color: IColors.accent
                                                            .withValues(
                                                                alpha: 0.1),
                                                        child: Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const SpinKitRotatingCircle(
                                                                color: IColors
                                                                    .primary,
                                                                size: 28,
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                "Loading...",
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      subtleColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _deleteGalleryImage(
                                                    event.event_id,
                                                    event.galleryImageUrls[i],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.red.shade600,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                )),
                          ],
                        ),
                      ),
              ),
            ),

            // Bottom Action Area
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: event.galleryImageUrls.length < _maxGalleryImages
                  ? ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _uploadGalleryImages(
                            event.event_id, event.galleryImageUrls.length);
                      },
                      icon: const Icon(Iconsax.add_circle),
                      label: Text(
                        "Add ${_maxGalleryImages - event.galleryImageUrls.length} more images",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: IColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.warning_2,
                            size: 16,
                            color: isDark
                                ? Colors.amber.shade300
                                : Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Maximum limit of $_maxGalleryImages images reached",
                            style: TextStyle(
                              color: subtleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.calendar_remove,
            size: 64,
            color: IColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            "No events found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus != 'All'
                ? "You don't have any $_filterStatus events"
                : "You haven't created any events yet",
            style: const TextStyle(
              fontSize: 14,
              color: IColors.darkerGrey,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Stream<List<EventModel>> _getUserEvents(String userId) {
    return FirebaseFirestore.instance
        .collection('Event Table')
        .where('user_id', isEqualTo: userId)
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

      // Sort events by date (newest first)
      events.sort((a, b) => b.start_timestamp.compareTo(a.start_timestamp));

      return events;
    });
  }

  Future<void> _cancelEvent(String eventId) async {
    final confirm = await _showConfirmationDialog(
      title: "Cancel Event",
      message: "Are you sure you want to cancel this event?",
      confirmLabel: "Yes",
      cancelLabel: "No",
      isDestructive: false,
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('Event Table')
            .doc(eventId)
            .update({'status': 'cancelled', 'eventCancelled': true});

        IDeviceUtils.showSnackBar("Success", "Event cancelled successfully");
      } catch (e) {
        IDeviceUtils.showSnackBar("Failure", "Failed to cancel event");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirm = await _showConfirmationDialog(
      title: "Delete Event",
      message: "Are you sure you want to delete this Event?",
      confirmLabel: "Delete",
      cancelLabel: "Cancel",
    );

    if (confirm != true) return;
    try {
      final supabase = Supabase.instance.client;
      final bucket = supabase.storage.from('event-bucket');

      // List top-level folders inside eventId/
      final subfolders = ['brochure', 'gallery'];

      List<String> allFilePaths = [];

      for (final folder in subfolders) {
        final files = await bucket.list(path: "$eventId/$folder");
        allFilePaths.addAll(
          files.map((file) => "$eventId/$folder/${file.name}"),
        );
      }

      // Also include .keep if present at root
      final rootFiles = await bucket.list(path: eventId);
      allFilePaths.addAll(
        rootFiles.map((file) => "$eventId/${file.name}"),
      );

      await _removeEventFromUserLikes(eventId);

      // Delete event document from Firestore
      await FirebaseFirestore.instance
          .collection('Event Table')
          .doc(eventId)
          .delete();

      IDeviceUtils.showSnackBar(
          "Success", "Event and files deleted successfully");
    } catch (e) {
      IDeviceUtils.showSnackBar("Failure", "Failed to delete event");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeEventFromUserLikes(String eventId) async {
    final usersRef = FirebaseFirestore.instance.collection('User Table');
    final usersSnapshot = await usersRef.get();

    for (final doc in usersSnapshot.docs) {
      final likedEvents = List<String>.from(doc.data()['liked_events'] ?? []);

      if (likedEvents.contains(eventId)) {
        likedEvents.remove(eventId);
        await doc.reference.update({'liked_events': likedEvents});
      }
    }
  }

  Future<void> _uploadGalleryImages(
      String eventId, int currentImageCount) async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isEmpty) return;

      final remainingSlots = _maxGalleryImages - currentImageCount;
      if (pickedFiles.length > remainingSlots) {
        IDeviceUtils.showSnackBar(
            "Failure", "You can only upload $remainingSlots more images.");
        return;
        // Show warning if user tries to upload more than allowed
      }

      // Limit the number of files to upload
      final filesToUpload = pickedFiles.take(remainingSlots).toList();

      setState(() {
        _isLoading = true;
      });

      // Get the event data to check if there's already a gallery folder
      final eventDoc = await FirebaseFirestore.instance
          .collection('Event Table')
          .doc(eventId)
          .get();

      var galleryFolderPath = eventDoc.data()?['galleryImageFolderUrl'];

      // If galleryFolderPath is a List, use it; otherwise, initialize as an empty list
      if (galleryFolderPath == null || galleryFolderPath is! List) {
        galleryFolderPath = [];
      }

      // Supabase client for file upload
      final supabase = Supabase.instance.client;

      // Upload each image and append the path to Firestore
      List<String> uploadedPaths = [];
      for (var i = 0; i < filesToUpload.length; i++) {
        final file = File(filesToUpload[i].path);
        final fileExt = filesToUpload[i].path.split('.').last;
        final fileName = 'gallery${currentImageCount + i + 1}.$fileExt';
        final filePath =
            '$eventId/gallery/$fileName'; // Folder path within the event

        await supabase.storage.from('event-bucket').upload(
              filePath,
              file,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: false),
            );

        // Append the uploaded image's path to the list
        uploadedPaths.add(filePath);
      }

      // If there were uploaded paths, update the Firestore document
      if (uploadedPaths.isNotEmpty) {
        // Append the new paths to the existing array of image paths
        galleryFolderPath.addAll(uploadedPaths);

        // Update the Firestore document with the new gallery image paths
        await FirebaseFirestore.instance
            .collection('Event Table')
            .doc(eventId)
            .update({'galleryImageFolderUrl': galleryFolderPath});
      }

      // Show success message
      IDeviceUtils.showSnackBar("Success",
          "Successfully uploaded ${filesToUpload.length} images to gallery");
    } catch (e) {
      IDeviceUtils.showSnackBar("Failure", "Failed to upload images");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGalleryImage(String eventId, String imagePath) async {
    final confirm = await _showConfirmationDialog(
      title: "Delete Image",
      message: "Are you sure you want to delete this image?",
      confirmLabel: "Delete",
      cancelLabel: "Cancel",
    );
    if (confirm != true) return;

    setState(() {
      Navigator.pop(context);
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      await supabase.storage.from('event-bucket').remove([imagePath]);

      // Remove image path from Firestore list
      final eventRef =
          FirebaseFirestore.instance.collection('Event Table').doc(eventId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(eventRef);
        if (!snapshot.exists) throw Exception("Event not found");

        List<dynamic> galleryList =
            snapshot.data()?['galleryImageFolderUrl'] ?? [];

        // Filter out the deleted path
        galleryList.remove(imagePath);

        transaction.update(eventRef, {'galleryImageFolderUrl': galleryList});
      });

      IDeviceUtils.showSnackBar("Success", "Image deleted successfully");

      setState(() {});
    } catch (e) {
      IDeviceUtils.showSnackBar("Failure", "Failed to delete image");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive = false,
  }) async {
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 250,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDestructive ? Icons.warning : Icons.info_outline,
                        color: isDestructive ? Colors.red : theme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontFamily: 'Roboto',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white70,
                      ),
                      child: Text(
                        cancelLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: IColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 70,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDestructive ? Colors.red : theme.primaryColor,
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "upcoming":
        return IColors.primary;
      case "live":
        return IColors.success;
      case "completed":
        return IColors.darkerGrey;
      case "cancelled":
        return IColors.error;
      default:
        return IColors.info;
    }
  }

  Color _getStatusBorderColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case "upcoming":
        return IColors.primary.withValues(alpha: 0.5);
      case "live":
        return IColors.success.withValues(alpha: 0.5);
      case "completed":
        return isDark
            ? Colors.grey.withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.3);
      case "cancelled":
        return IColors.error.withValues(alpha: 0.5);
      default:
        return isDark
            ? IColors.primary.withValues(alpha: 0.2)
            : IColors.borderSecondary;
    }
  }
}

// Extension method to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
