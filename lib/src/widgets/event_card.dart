import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class EventCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String location;
  final String status;
  final bool isLiked;
  final int likeCount;
  final String eventId;
  final DateTime startDateTime; // Added start date time
  final DateTime endDateTime; // Added end date time
  final VoidCallback onViewDetails;
  final Function(bool) onLikeToggled;

  const EventCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.onViewDetails,
    required this.isLiked,
    required this.likeCount,
    required this.eventId,
    required this.startDateTime, // Required parameter
    required this.endDateTime, // Required parameter
    required this.onLikeToggled,
  }) : super(key: key);

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late bool _isLiked;
  late int _likeCount;
  bool _isProcessingLike = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeCount = widget.likeCount;
  }

  @override
  void didUpdateWidget(EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked ||
        oldWidget.likeCount != widget.likeCount) {
      setState(() {
        _isLiked = widget.isLiked;
        _likeCount = widget.likeCount;
      });
    }
  }

  // Format the date and time according to the requirements
  String _formatDateTime() {
    final startDate = DateFormat('MMM d, yyyy').format(widget.startDateTime);
    final endDate = DateFormat('MMM d, yyyy').format(widget.endDateTime);
    final startTime = DateFormat('h:mm a').format(widget.startDateTime);
    final endTime = DateFormat('h:mm a').format(widget.endDateTime);

    // Check if the event is on the same day
    if (startDate == endDate) {
      return '$startDate · $startTime - $endTime';
    } else {
      return '$startDate $startTime - $endDate $endTime';
    }
  }

  Future<void> _toggleLike() async {
    if (_isProcessingLike) return;

    setState(() {
      _isProcessingLike = true;
      // Optimistic UI update
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    try {
      await widget.onLikeToggled(_isLiked);
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like status: $e')),
      );
    } finally {
      setState(() {
        _isProcessingLike = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = IDeviceUtils.getScreenWidth(context);
    final contentPadding = screenWidth * 0.03;

    return Container(
      width: screenWidth * 0.9,
      // Height is removed to allow content to determine container size
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? IColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? IColors.primary.withValues(alpha: 0.2)
              : IColors.borderSecondary,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:
              MainAxisSize.min, // Let column take minimum space needed
          children: [
            // Image and details row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image (unchanged)
                Container(
                  width: screenWidth * 0.28,
                  height: screenWidth * 0.28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? IColors.primary.withValues(alpha: 0.3)
                          : IColors.accent.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
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
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.3,
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? IColors.textWhite
                                    : IColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.status, isDarkMode)
                                  .withValues(alpha: isDarkMode ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    _getStatusColor(widget.status, isDarkMode)
                                        .withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color:
                                    _getStatusColor(widget.status, isDarkMode),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // Description
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? IColors.textWhite.withValues(alpha: 0.8)
                              : IColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: IColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? IColors.textWhite.withValues(alpha: 0.7)
                                    : IColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // ADDED: Date and Time display
                      Row(
                        children: [
                          const Icon(
                            Iconsax.calendar,
                            size: 16,
                            color: IColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDateTime(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? IColors.textWhite.withValues(alpha: 0.7)
                                    : IColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like button with count
                Row(
                  children: [
                    IconButton(
                      icon: _isProcessingLike
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: SpinKitPulse(
                                color: Colors.red,
                              ),
                            )
                          : Icon(
                              _isLiked ? Iconsax.heart5 : Iconsax.heart,
                              color: _isLiked
                                  ? Colors.red
                                  : (isDarkMode
                                      ? IColors.textWhite
                                      : IColors.textPrimary),
                              size: 24,
                            ),
                      onPressed: _toggleLike,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_likeCount Likes',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode
                            ? IColors.textWhite.withValues(alpha: 0.7)
                            : IColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Share button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Iconsax.share,
                        color: isDarkMode
                            ? IColors.textWhite
                            : IColors.textPrimary,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                    const Text("Share", style: TextStyle(fontSize: 16)),
                  ],
                ),
                // Details button
                ElevatedButton(
                  onPressed: widget.onViewDetails,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      IColors.primary.withValues(alpha: 0.1),
                    ),
                    foregroundColor:
                        WidgetStateProperty.all<Color>(IColors.primary),
                    elevation: WidgetStateProperty.all<double>(0),
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: IColors.primary.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    overlayColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.pressed)) {
                          return IColors.primary.withValues(alpha: 0.2);
                        }
                        return IColors.primary.withValues(alpha: 0.1);
                      },
                    ),
                  ),
                  child: const Text(
                    "Details",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status.toLowerCase()) {
      case "upcoming":
        return IColors.primary;
      case "live":
        return IColors.success;
      case "completed":
        return isDarkMode ? IColors.darkGrey : IColors.textSecondary;
      case "cancelled":
        return IColors.error;
      default:
        return IColors.info;
    }
  }
}
