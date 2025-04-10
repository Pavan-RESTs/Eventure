import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax/iconsax.dart';

class EventCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String location;
  final String status;
  final VoidCallback onLike;
  final VoidCallback onViewDetails;
  final bool isLiked;

  const EventCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.onLike,
    required this.onViewDetails,
    this.isLiked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = IDeviceUtils.getScreenWidth(context);
    final screenHeight = IDeviceUtils.getScreenHeight(context);

    // Responsive padding calculations
    final contentPadding = screenWidth * 0.03;

    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.255,
      margin: EdgeInsets.symmetric(vertical: 8),
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
            // Image and event info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event image
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
                      imageUrl,
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
                            child:
                                SpinKitRotatingCircle(color: IColors.primary),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            child: Text(
                              title,
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
                            width: screenWidth * 0.3,
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status, isDarkMode)
                                  .withOpacity(isDarkMode ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _getStatusColor(status, isDarkMode)
                                    .withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(status, isDarkMode),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Description
                      Text(
                        description,
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

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: isDarkMode
                                ? IColors.primary.withOpacity(0.9)
                                : IColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
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

                      const SizedBox(height: 4),

                      // Status badge
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Iconsax.heart5 : Iconsax.heart,
                        color: isLiked
                            ? Colors.red
                            : (isDarkMode
                                ? IColors.textWhite
                                : IColors.textPrimary),
                        size: 24,
                      ),
                      onPressed: onLike,
                    ),
                    Text(
                      "Like",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
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
                    Text(
                      "Share",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                // Details button
                // Button styled like the "Upcoming" status chip
                ElevatedButton(
                  onPressed: onViewDetails,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
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
