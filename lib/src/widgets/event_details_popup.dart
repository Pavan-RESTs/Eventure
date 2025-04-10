import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:eventure/src/data_repository/event_model.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

void showEventDetailsPopup(
    BuildContext context, dynamic event, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) => EventDetailsPopup(event: event, imageUrl: imageUrl),
  );
}

class EventDetailsPopup extends StatelessWidget {
  final EventModel event;
  final String imageUrl;

  const EventDetailsPopup({
    Key? key,
    required this.event,
    required this.imageUrl,
  }) : super(key: key);

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'live':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = IDeviceUtils.isDarkMode(context);
    final double screenHeight = IDeviceUtils.getScreenHeight(context);
    final double screenWidth = IDeviceUtils.getScreenWidth(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.05,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.8,
        ),
        decoration: BoxDecoration(
          color: isDark ? IColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header image
                Stack(
                  children: [
                    // Event image
                    imageUrl.isEmpty
                        ? Container(
                            height: 180,
                            width: double.infinity,
                            color: IColors.primary.withOpacity(0.2),
                            child: const Icon(
                              Iconsax.gallery,
                              size: 60,
                              color: IColors.primary,
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: IColors.primary.withOpacity(0.2),
                                child: const Center(
                                  child: Icon(
                                    Iconsax.gallery_slash,
                                    size: 40,
                                    color: IColors.primary,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 180,
                                color: IColors.primary.withOpacity(0.1),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: IColors.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                    // Close button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black54
                              : Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    // Status badge
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(event.status),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          event.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Event details
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event title
                      Text(
                        event.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Organizer info
                      if (event.department.isNotEmpty)
                        _buildDetailRow(
                          context,
                          Iconsax.building,
                          event.department,
                          isDark,
                        ),
                      if (event.department.isNotEmpty)
                        const SizedBox(height: 12),

                      // Event details list
                      _buildDetailRow(
                        context,
                        Iconsax.calendar,
                        "Starts: ${_formatDateTime(event.start_timestamp)}",
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        Iconsax.timer_1,
                        "Ends: ${_formatDateTime(event.end_timestamp)}",
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        Iconsax.location,
                        event.venue,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        Iconsax.heart,
                        "${event.likes} likes",
                        isDark,
                      ),
                      const SizedBox(height: 24),

                      // Description header
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description text
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),

                      // Gallery images section
                      if (event.galleryImageUrls.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          "Gallery",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildGalleryPreview(event.galleryImageUrls, isDark),
                      ],

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Add "like" functionality here
                              },
                              icon: const Icon(Iconsax.heart),
                              label: const Text("Like"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDark ? IColors.dark : Colors.white,
                                foregroundColor: IColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side:
                                      const BorderSide(color: IColors.primary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  event.status.toLowerCase() == "upcoming"
                                      ? () {
                                          // Add registration logic here
                                        }
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: IColors.primary,
                                foregroundColor: IColors.grey,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor:
                                    IColors.primary.withOpacity(0.4),
                              ),
                              child: Text(
                                event.status.toLowerCase() == "upcoming"
                                    ? "Register"
                                    : event.status.toLowerCase() == "live"
                                        ? "Join Now"
                                        : "Completed",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String text,
    bool isDark, {
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: IColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isLink
                  ? IColors.primary
                  : isDark
                      ? Colors.white70
                      : Colors.black54,
              decoration:
                  isLink ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryPreview(List<dynamic> galleryUrls, bool isDark) {
    // This is a simple horizontal gallery preview
    // You can expand this to show thumbnails and make them clickable to show full screen images
    return SizedBox(
      height: 120,
      child: galleryUrls is List<String> && galleryUrls.isNotEmpty
          ? ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: galleryUrls.length > 5 ? 5 : galleryUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      galleryUrls[index],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: IColors.primary.withOpacity(0.2),
                          child: const Center(
                            child: Icon(
                              Iconsax.gallery_slash,
                              color: IColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            )
          : Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: isDark
                    ? IColors.dark.withOpacity(0.5)
                    : IColors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "No gallery images available",
                  style: TextStyle(
                    color: IColors.darkerGrey,
                  ),
                ),
              ),
            ),
    );
  }
}
