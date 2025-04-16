import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:eventure/src/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax/iconsax.dart';

class VenueModel {
  final String venueId;
  final String name;
  final String description;
  final List<String> images;

  VenueModel({
    required this.venueId,
    required this.name,
    required this.description,
    required this.images,
  });

  factory VenueModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VenueModel(
      venueId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
    );
  }
}

class VenueExplorationScreen extends StatefulWidget {
  const VenueExplorationScreen({super.key});

  @override
  State<VenueExplorationScreen> createState() => _VenueExplorationScreenState();
}

class _VenueExplorationScreenState extends State<VenueExplorationScreen> {
  TextEditingController searchTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bool isDark = IDeviceUtils.isDarkMode(context);
    final double screenWidth = IDeviceUtils.getScreenWidth(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: "Explore Venues",
        isDark: isDark,
        onRefreshPressed: () {
          setState(() {});
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(isDark),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Text(
              "Featured Venues",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Venue Table')
                  .snapshots(),
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

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyWidget();
                }

                final venues = snapshot.data!.docs
                    .map((doc) => VenueModel.fromFirestore(doc))
                    .toList();

                return _buildVenueList(venues, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? IColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchTextController,
        onChanged: (value) {
          setState(() {});
        },
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: "Find your perfect venue...",
          hintStyle: TextStyle(
            color: isDark ? IColors.grey : IColors.darkGrey,
            fontSize: 16,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(14),
            child: const Icon(
              Iconsax.search_normal_1,
              color: IColors.primary,
              size: 24,
            ),
          ),
          suffixIcon: searchTextController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchTextController.clear();
                    setState(() {});
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: IColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: IColors.primary,
                      size: 20,
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: isDark ? IColors.darkContainer : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: IColors.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildVenueList(List<VenueModel> venues, bool isDark) {
    // Filter venues based on search text
    final filteredVenues = searchTextController.text.isEmpty
        ? venues
        : venues
            .where((venue) =>
                venue.name
                    .toLowerCase()
                    .contains(searchTextController.text.toLowerCase()) ||
                venue.description
                    .toLowerCase()
                    .contains(searchTextController.text.toLowerCase()))
            .toList();

    if (filteredVenues.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredVenues.length,
      itemBuilder: (context, index) {
        final venue = filteredVenues[index];

        return GestureDetector(
          onTap: () {
            _showVenueDetailsDialog(context, venue, isDark);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? IColors.darkContainer : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildVenueImage(venue),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              venue.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: IColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.gallery,
                                  size: 14,
                                  color: IColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${venue.images.length} photos",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: IColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        venue.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? IColors.grey : IColors.darkGrey,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _showVenueDetailsDialog(context, venue, isDark);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 46),
                          elevation: 0,
                        ),
                        child: const Text(
                          "View Details",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVenueImage(VenueModel venue) {
    // Get the first image as thumbnail
    String thumbnailUrl = "";
    if (venue.images.isNotEmpty) {
      thumbnailUrl =
          "https://bnpdmwasofqiztyiwewo.supabase.co/storage/v1/object/public/venue-bucket/${venue.venueId}/${venue.images[0]}";
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        thumbnailUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: IColors.lightGrey,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: IColors.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: IColors.lightGrey,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: IColors.primary,
                    size: 50,
                  ),
                ),
              )
            : Container(
                color: IColors.lightGrey,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: IColors.primary,
                    size: 50,
                  ),
                ),
              ),
        // Gradient overlay for better text readability if needed
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.2),
              ],
              stops: const [0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  void _showVenueDetailsDialog(
      BuildContext context, VenueModel venue, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isDark ? IColors.dark : Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        venue.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: IColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: IColors.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (venue.images.isNotEmpty)
                SizedBox(
                  height: 300,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 300,
                      viewportFraction: 1.0,
                      enlargeCenterPage: false,
                      autoPlay: true,
                      enableInfiniteScroll: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                    ),
                    items: venue.images.map((imagePath) {
                      String imageUrl =
                          "https://bnpdmwasofqiztyiwewo.supabase.co/storage/v1/object/public/venue-bucket/${venue.venueId}/$imagePath";
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: IColors.lightGrey,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: IColors.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: IColors.lightGrey,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: IColors.primary,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                )
              else
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: IColors.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: IColors.primary,
                      size: 60,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: IColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "About This Venue",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: IColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      venue.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? IColors.grey : IColors.darkGrey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Here you could navigate to a booking screen
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => BookVenueScreen(venue: venue)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: IColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(double.infinity, 56),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Book This Venue",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: IColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.building,
              size: 64,
              color: IColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No venues found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            searchTextController.text.isNotEmpty
                ? "Try different search terms"
                : "Please check back later",
            style: const TextStyle(
              fontSize: 16,
              color: IColors.darkerGrey,
            ),
          ),
        ],
      ),
    );
  }
}
