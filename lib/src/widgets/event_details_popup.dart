import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:eventure/src/data_repository/event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
              color:
                  isDark ? Colors.black26 : Colors.grey.withValues(alpha: 0.3),
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
                            color: IColors.primary.withValues(alpha: 0.2),
                            child: const Icon(
                              Iconsax.gallery,
                              size: 60,
                              color: IColors.primary,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: IColors.primary.withValues(alpha: 0.2),
                                child: const Center(
                                  child: Icon(
                                    Iconsax.gallery_slash,
                                    size: 40,
                                    color: IColors.primary,
                                  ),
                                ),
                              );
                            },
                            progressIndicatorBuilder:
                                (context, child, loadingProgress) {
                              return Container(
                                height: 180,
                                color: IColors.primary.withValues(alpha: 0.1),
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
                              : Colors.white.withValues(alpha: 0.8),
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
                        Iconsax.timer_start,
                        _formatDateTime(event.start_timestamp),
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        Iconsax.timer_pause,
                        _formatDateTime(event.end_timestamp),
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
}

Widget _buildGalleryPreview(List<dynamic> galleryUrls, bool isDark) {
  return SizedBox(
    height: 120,
    child: galleryUrls.isNotEmpty
        ? ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: galleryUrls.length > 5 ? 5 : galleryUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    // Show image in a dialog with carousel capability
                    _showImageCarouselDialog(
                        context, galleryUrls, index, isDark);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl:
                          "https://bnpdmwasofqiztyiwewo.supabase.co/storage/v1/object/public/event-bucket/${galleryUrls[index].toString()}",
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorWidget: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: IColors.primary.withValues(alpha: 0.2),
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
                ),
              );
            },
          )
        : Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: isDark
                  ? IColors.primary.withValues(alpha: 0.1)
                  : IColors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "No gallery images available",
                style: TextStyle(
                  color: IColors.primary,
                ),
              ),
            ),
          ),
  );
}

// Function to show image carousel dialog
void _showImageCarouselDialog(BuildContext context, List<dynamic> galleryUrls,
    int initialIndex, bool isDark) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ImageCarouselDialog(
        galleryUrls: galleryUrls,
        initialIndex: initialIndex,
        isDark: isDark,
      );
    },
  );
}

class ImageCarouselDialog extends StatefulWidget {
  final List<dynamic> galleryUrls;
  final int initialIndex;
  final bool isDark;

  const ImageCarouselDialog({
    Key? key,
    required this.galleryUrls,
    required this.initialIndex,
    required this.isDark,
  }) : super(key: key);

  @override
  State<ImageCarouselDialog> createState() => _ImageCarouselDialogState();
}

class _ImageCarouselDialogState extends State<ImageCarouselDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final backgroundColor = widget.isDark
        ? Colors.black.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.95);
    final textColor = widget.isDark ? IColors.white : IColors.textPrimary;
    final secondaryColor = widget.isDark ? Colors.white70 : Colors.black54;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top bar with counter and close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Image counter
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: IColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_currentIndex + 1}/${widget.galleryUrls.length}",
                    style: const TextStyle(
                      color: IColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Close button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Iconsax.close_circle,
                      color: secondaryColor,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main container for carousel
          Container(
            constraints: BoxConstraints(
              maxWidth: size.width,
              maxHeight: size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                // PageView for swiping images
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.galleryUrls.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        child: CachedNetworkImage(
                          imageUrl:
                              "https://bnpdmwasofqiztyiwewo.supabase.co/storage/v1/object/public/event-bucket/${widget.galleryUrls[index].toString()}",
                          fit: BoxFit.contain,
                          progressIndicatorBuilder:
                              (context, child, loadingProgress) {
                            return SizedBox(
                              width: size.width * 0.8,
                              height: size.width * 0.8,
                              child: const Center(
                                child: SpinKitWaveSpinner(
                                  size: 60,
                                  waveColor: Colors.lightBlueAccent,
                                  color: IColors.primary,
                                ),
                              ),
                            );
                          },
                          errorWidget: (context, error, stackTrace) {
                            return Container(
                              width: size.width * 0.8,
                              height: size.width * 0.8,
                              color: IColors.primary.withValues(alpha: 0.1),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Iconsax.gallery_slash,
                                    color: IColors.primary,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Failed to load image",
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(
                                          () {}); // Trigger rebuild to retry
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: IColors.primary,
                                      foregroundColor: IColors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text("Retry"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
