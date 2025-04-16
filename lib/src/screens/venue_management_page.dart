import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:eventure/src/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
  String selectedCategory = 'All';
  final List<String> categories = [
    'All',
    'Indoor',
    'Outdoor',
    'Conference',
    'Wedding'
  ];

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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(isDark),
            const SizedBox(height: 16),
            _buildCategoryChips(),
            const SizedBox(height: 16),
            Text(
              "Featured Venues",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
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

                  // Filter by category if not "All"
                  List<VenueModel> filteredVenues = selectedCategory == 'All'
                      ? venues
                      : venues.where((venue) =>
                          // This is a placeholder. In a real app, you'd have a category field in your venue model
                          true).toList();

                  return _buildVenueGrid(filteredVenues, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return TextField(
      controller: searchTextController,
      onChanged: (value) {
        setState(() {});
      },
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: "Search venues...",
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
            setState(() {});
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
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: IColors.grey,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(category),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : IColors.primary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.transparent,
              shape: const StadiumBorder(
                side: BorderSide(color: IColors.primary),
              ),
              selectedColor: IColors.primary,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildVenueGrid(List<VenueModel> venues, bool isDark) {
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

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: filteredVenues.length,
      itemBuilder: (context, index) {
        final venue = filteredVenues[index];

        // Get the first image as thumbnail
        String thumbnailUrl = "";
        if (venue.images.isNotEmpty) {
          thumbnailUrl =
              "https://bnpdmwasofqiztyiwewo.supabase.co/storage/v1/object/public/venue-bucket/${venue.venueId}/${venue.images[0]}";
        }

        return GestureDetector(
          onTap: () {
            _showVenueDetailsDialog(context, venue, isDark);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? IColors.darkContainer : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          height: index % 3 == 0
                              ? 180
                              : 140, // Varied heights for visual interest
                          width: double.infinity,
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
                            ),
                          ),
                        )
                      : Container(
                          height: index % 3 == 0 ? 180 : 140,
                          color: IColors.lightGrey,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: IColors.primary,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        venue.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? IColors.grey : IColors.darkGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
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
                              color: IColors.primary,
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
        );
      },
    );
  }

  void _showVenueDetailsDialog(
      BuildContext context, VenueModel venue, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                    Text(
                      venue.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: IColors.primary),
                      onPressed: () => Navigator.pop(context),
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
                              borderRadius: BorderRadius.circular(8),
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
                  color: IColors.lightGrey,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: IColors.primary,
                      size: 50,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: IColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      venue.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? IColors.grey : IColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
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
          const Icon(
            Iconsax.building,
            size: 64,
            color: IColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            "No venues found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchTextController.text.isNotEmpty
                ? "Try different search terms"
                : "Please check back later",
            style: const TextStyle(
              fontSize: 14,
              color: IColors.darkerGrey,
            ),
          ),
        ],
      ),
    );
  }
}
