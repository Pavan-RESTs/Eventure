import 'dart:io';
import 'dart:typed_data';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:eventure/src/functions/cloud_helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CreateEventPopup extends StatefulWidget {
  final Function onEventCreated;

  const CreateEventPopup({
    Key? key,
    required this.onEventCreated,
  }) : super(key: key);

  @override
  State<CreateEventPopup> createState() => _CreateEventPopupState();
}

class _CreateEventPopupState extends State<CreateEventPopup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedDepartmentId;
  String? _selectedVenueId;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  File? _brochureImage;
  bool _isLoading = false;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _venues = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchVenues();
  }

  Future<void> _fetchDepartments() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Department Table').get();
    setState(() {
      _departments = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] ?? 'Unknown'})
          .toList();
    });
  }

  Future<void> _fetchVenues() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Venue Table').get();
    setState(() {
      _venues = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] ?? 'Unknown'})
          .toList();
    });
  }

  Future<void> _pickBrochureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _brochureImage = File(image.path);
      });
    }
  }

  Future<void> _selectStartDateTime(BuildContext context) async {
    final bool isDark = IDeviceUtils.isDarkMode(context);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: IColors.primary,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                    surface: IColors.dark,
                  )
                : const ColorScheme.light(
                    primary: IColors.primary,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: IColors.primary,
              ),
            ),
            dialogTheme: DialogThemeData(
                backgroundColor: isDark ? IColors.dark : Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDateTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: IColors.primary,
                      onPrimary: Colors.white,
                      onSurface: Colors.white,
                      surface: IColors.dark,
                    )
                  : const ColorScheme.light(
                      primary: IColors.primary,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: isDark ? IColors.dark : Colors.white,
                hourMinuteTextColor: isDark ? Colors.white : IColors.primary,
                hourMinuteColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                dayPeriodTextColor: isDark ? Colors.white : IColors.primary,
                dayPeriodColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                dialHandColor: IColors.primary,
                dialBackgroundColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                dialTextColor: isDark ? Colors.white : Colors.black87,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: IColors.primary,
                ),
              ),
              dialogTheme: DialogThemeData(
                  backgroundColor: isDark ? IColors.dark : Colors.white),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _startDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<bool> _checkForEventOverlaps() async {
    if (_startDateTime == null ||
        _endDateTime == null ||
        _selectedVenueId == null) {
      return false;
    }

    try {
      // Query events at the same venue that might overlap
      final QuerySnapshot eventsSnapshot = await FirebaseFirestore.instance
          .collection('Event Table')
          .where('venue_id', isEqualTo: _selectedVenueId)
          .get();

      // Check each event for time overlap
      for (var doc in eventsSnapshot.docs) {
        final eventData = doc.data() as Map<String, dynamic>;

        // Get the start and end times of existing events
        final existingStartTime =
            (eventData['start_timestamp'] as Timestamp).toDate();
        final existingEndTime =
            (eventData['end_timestamp'] as Timestamp).toDate();

        // Check for overlap
        // Overlap occurs when:
        // - New event starts during an existing event, OR
        // - New event ends during an existing event, OR
        // - New event completely encompasses an existing event
        if ((_startDateTime!.isAfter(existingStartTime) &&
                _startDateTime!.isBefore(existingEndTime)) ||
            (_endDateTime!.isAfter(existingStartTime) &&
                _endDateTime!.isBefore(existingEndTime)) ||
            (_startDateTime!.isBefore(existingStartTime) &&
                _endDateTime!.isAfter(existingEndTime))) {
          // Format the conflicting event times for display
          final dateFormatter = DateFormat('MMM dd, yyyy');
          final timeFormatter = DateFormat('hh:mm a');
          final existingEventName = eventData['name'];
          final conflictMessage =
              'Conflicts with "${existingEventName}" on ${dateFormatter.format(existingStartTime)} from ${dateFormatter.format(existingStartTime)} ${timeFormatter.format(existingStartTime)} to ${dateFormatter.format(existingEndTime)} ${timeFormatter.format(existingEndTime)}';

          IDeviceUtils.showSnackBar(
              'Time Conflict', conflictMessage, const Duration(seconds: 6));
          return true;
        }
      }

      return false; // No overlaps found
    } catch (e) {
      return false;
    }
  }

  Future<void> _selectEndDateTime(BuildContext context) async {
    final bool isDark = IDeviceUtils.isDarkMode(context);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDateTime ?? (_startDateTime ?? DateTime.now()),
      firstDate: _startDateTime ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: IColors.primary,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                    surface: IColors.dark,
                  )
                : const ColorScheme.light(
                    primary: IColors.primary,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: IColors.primary,
              ),
            ),
            dialogTheme: DialogThemeData(
                backgroundColor: isDark ? IColors.dark : Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _endDateTime ?? (_startDateTime ?? DateTime.now())),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: IColors.primary,
                      onPrimary: Colors.white,
                      onSurface: Colors.white,
                      surface: IColors.dark,
                    )
                  : const ColorScheme.light(
                      primary: IColors.primary,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: isDark ? IColors.dark : Colors.white,
                hourMinuteTextColor: isDark ? Colors.white : IColors.primary,
                hourMinuteColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                dayPeriodTextColor: isDark ? Colors.white : IColors.primary,
                dayPeriodColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                dialHandColor: IColors.primary,
                dialBackgroundColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                dialTextColor: isDark ? Colors.white : Colors.black87,
                entryModeIconColor: IColors.primary,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: IColors.primary,
                ),
              ),
              dialogTheme: DialogThemeData(
                  backgroundColor: isDark ? IColors.dark : Colors.white),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _endDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_brochureImage == null) {
        IDeviceUtils.showSnackBar('Error', 'Please select a brochure image',
            const Duration(seconds: 2));
        return;
      }

      if (_startDateTime == null) {
        IDeviceUtils.showSnackBar('Error',
            'Please select a start date and time', const Duration(seconds: 2));
        return;
      }

      if (_endDateTime == null) {
        IDeviceUtils.showSnackBar('Error', 'Please select an end date and time',
            const Duration(seconds: 2));
        return;
      }

      if (_selectedDepartmentId == null) {
        IDeviceUtils.showSnackBar(
            'Error', 'Please select a department', const Duration(seconds: 2));
        return;
      }

      if (_selectedVenueId == null) {
        IDeviceUtils.showSnackBar(
            'Error', 'Please select a venue', const Duration(seconds: 2));
        return;
      }
      setState(() {
        _isLoading = true;
      });
      // Check for event time overlaps
      bool hasOverlaps = await _checkForEventOverlaps();
      if (hasOverlaps) {
        setState(() {
          _isLoading = false;
        });

        return;
      }

      try {
        // Generate event ID
        final eventId = const Uuid().v4();
        final userId = await ICloudHelperFunctions.getUserId();

        final fileExtension =
            path.extension(_brochureImage!.path); // e.g., ".jpg"
        final brochurePath = "$eventId/brochure/brochure$fileExtension";

// Upload the image
        await Supabase.instance.client.storage.from('event-bucket').upload(
              brochurePath,
              _brochureImage!,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: false),
            );

        // Create a folder for gallery images by uploading a placeholder file
        final galleryPlaceholderPath = "$eventId/gallery/.keep";
        await Supabase.instance.client.storage
            .from('event-bucket')
            .uploadBinary(
              galleryPlaceholderPath,
              Uint8List.fromList([]),
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: false),
            );

// Save Firestore document (include the full brochure path)
        await FirebaseFirestore.instance
            .collection('Event Table')
            .doc(eventId)
            .set({
          'created_at': Timestamp.now(),
          'name': _nameController.text,
          'description': _descriptionController.text,
          'user_id': userId,
          'department_id': _selectedDepartmentId,
          'venue_id': _selectedVenueId,
          'likes': 0,
          'start_timestamp': Timestamp.fromDate(_startDateTime!),
          'end_timestamp': Timestamp.fromDate(_endDateTime!),
          'brochureImageUrl': brochurePath,
          'galleryImageFolderUrl': []
        });

        // Create folder for gallery images (even if empty for now)

        IDeviceUtils.showSnackBar('Success', 'Event created successfully',
            const Duration(seconds: 2));
        widget.onEventCreated();
        Navigator.of(context).pop();
      } catch (e) {
        IDeviceUtils.showSnackBar(
            'Error', 'Failed to create event: $e', const Duration(seconds: 2));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = IDeviceUtils.isDarkMode(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: isDark ? IColors.dark : IColors.light,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.03,
      ),
      child: Stack(children: [
        Opacity(
          opacity: _isLoading ? 0.5 : 1,
          child: Container(
            width: screenWidth * 0.9,
            height: screenHeight * 0.85,
            decoration: BoxDecoration(
              color: isDark ? IColors.dark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Iconsax.calendar_add,
                                  size: 40,
                                  color: IColors.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create New Event',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fill in the details to create a new event',
                                  style: TextStyle(
                                    color: isDark
                                        ? IColors.grey
                                        : IColors.darkGrey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),

                          // Name field
                          _buildLabel('Event Name'),
                          _buildTextField(
                            controller: _nameController,
                            hintText: 'Enter event name',
                            icon: Iconsax.note_text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter event name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Description field
                          _buildLabel('Description'),
                          _buildTextField(
                            controller: _descriptionController,
                            hintText: 'Enter event description',
                            icon: Iconsax.document_text,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter event description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Department dropdown
                          _buildLabel('Department'),
                          _buildDropdown(
                            items: _departments,
                            value: _selectedDepartmentId,
                            hintText: 'Select department',
                            icon: Iconsax.building,
                            onChanged: (value) {
                              setState(() {
                                _selectedDepartmentId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Venue dropdown
                          _buildLabel('Venue'),
                          _buildDropdown(
                            items: _venues,
                            value: _selectedVenueId,
                            hintText: 'Select venue',
                            icon: Iconsax.location,
                            onChanged: (value) {
                              setState(() {
                                _selectedVenueId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Date and time pickers
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Start Date & Time'),
                                    _buildDateTimePicker(
                                      dateTime: _startDateTime,
                                      onTap: () =>
                                          _selectStartDateTime(context),
                                      hintText: 'Select start',
                                      icon: Iconsax.calendar,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('End Date & Time'),
                                    _buildDateTimePicker(
                                      dateTime: _endDateTime,
                                      onTap: () => _selectEndDateTime(context),
                                      hintText: 'Select end',
                                      icon: Iconsax.calendar,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Brochure image picker
                          _buildLabel('Brochure Image'),
                          InkWell(
                            onTap: _pickBrochureImage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black12
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: IColors.grey.withValues(alpha: 0.5),
                                ),
                              ),
                              child: _brochureImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _brochureImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Iconsax.image,
                                          size: 48,
                                          color: isDark
                                              ? IColors.grey
                                              : IColors.darkGrey,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to select brochure image',
                                          style: TextStyle(
                                            color: isDark
                                                ? IColors.grey
                                                : IColors.darkGrey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Create button
                          SizedBox(
                              width: double.infinity,
                              height: screenHeight * 0.07,
                              child: ElevatedButton(
                                onPressed: _createEvent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: IColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                  shadowColor:
                                      IColors.primary.withValues(alpha: 0.4),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Iconsax.calendar_add,
                                          size: 18,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Create Event',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading) const SpinKitDualRing(color: IColors.primary),
      ]),
    );
  }

  Widget _buildLabel(String label) {
    final isDark = IDeviceUtils.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = IDeviceUtils.isDarkMode(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        prefixIcon: Icon(
          icon,
          color: IColors.primary,
          size: 20,
        ),
        filled: true,
        fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: IColors.primary,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required List<Map<String, dynamic>> items,
    required String? value,
    required String hintText,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    final isDark = IDeviceUtils.isDarkMode(context);

    // Extract just the names for the dropdown
    final List<String> names =
        items.map((item) => item['name'] as String).toList();

    return Row(
      children: [
        Icon(
          icon,
          color: IColors.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: CustomDropdown<String>.search(
              decoration: CustomDropdownDecoration(
                expandedFillColor: isDark ? IColors.dark : Colors.white,
                listItemDecoration: const ListItemDecoration(
                  selectedColor: IColors.grey,
                  splashColor: IColors.darkGrey,
                  selectedIconShape: CircleBorder(
                    side: BorderSide(color: IColors.primary),
                  ),
                ),
                noResultFoundStyle: TextStyle(
                    color: isDark ? Colors.white70 : IColors.textPrimary),
                headerStyle:
                    TextStyle(color: isDark ? Colors.white : Colors.black),
                closedSuffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  size: 24,
                  color: IColors.primary,
                ),
                expandedSuffixIcon: const Icon(
                  Icons.arrow_drop_up,
                  size: 24,
                  color: IColors.primary,
                ),
                closedFillColor: isDark ? Colors.black12 : Colors.grey.shade50,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 14,
                ),
                listItemStyle: TextStyle(
                    color: isDark ? Colors.white : IColors.textPrimary),
                searchFieldDecoration: SearchFieldDecoration(
                  textStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54),
                  hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.black54),
                  fillColor:
                      isDark ? Colors.grey.shade800 : const Color(0xfff4f5f8),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              hintText: hintText,
              items: names,
              excludeSelected: true,
              onChanged: (selectedName) {
                if (selectedName != null) {
                  // Find the corresponding ID from the original items list
                  final selectedItem = items.firstWhere(
                    (item) => item['name'] == selectedName,
                    orElse: () => {'id': null, 'name': selectedName},
                  );
                  onChanged(selectedItem['id']);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required DateTime? dateTime,
    required VoidCallback onTap,
    required String hintText,
    required IconData icon,
  }) {
    final isDark = IDeviceUtils.isDarkMode(context);
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm a');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.black12 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: IColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            dateTime != null
                ? Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dateFormatter.format(dateTime),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          timeFormatter.format(dateTime),
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    hintText,
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// Helper method to show the create event popup
void showCreateEventPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CreateEventPopup(
        onEventCreated: () {
          // Refresh events or perform other actions after event creation
        },
      );
    },
  );
}
