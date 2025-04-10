import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax/iconsax.dart';

class EventCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String location;
  final String status;
  final bool isLiked;
  final int likeCount;
  final String eventId;
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
    final screenHeight = IDeviceUtils.getScreenHeight(context);
    final contentPadding = screenWidth * 0.03;

    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.255,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? IColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? IColors.primary.withOpacity(0.2)
              : IColors.borderSecondary,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and details row (unchanged)
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
                          ? IColors.primary.withOpacity(0.3)
                          : IColors.accent.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: IColors.accent.withOpacity(0.2),
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              color: IColors.primary),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: IColors.accent.withOpacity(0.2),
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
                // Text content (unchanged)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and status (unchanged)
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
                                  .withOpacity(isDarkMode ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    _getStatusColor(widget.status, isDarkMode)
                                        .withOpacity(0.5),
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
                      const SizedBox(height: 10),
                      // Description (unchanged)
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? IColors.textWhite.withOpacity(0.8)
                              : IColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Location (unchanged)
                      Row(
                        children: [
                          Icon(
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
                                    ? IColors.textWhite.withOpacity(0.7)
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
            // Action buttons - UPDATED FOR LIKE COUNT
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
                            ? IColors.textWhite.withOpacity(0.7)
                            : IColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Share button (unchanged)
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
                // Details button (unchanged)
                ElevatedButton(
                  onPressed: widget.onViewDetails,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      IColors.primary.withOpacity(0.1),
                    ),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(IColors.primary),
                    elevation: MaterialStateProperty.all<double>(0),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: IColors.primary.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    overlayColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
                          return IColors.primary.withOpacity(0.2);
                        }
                        return IColors.primary.withOpacity(0.1);
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
