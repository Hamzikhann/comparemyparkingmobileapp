import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:parkingapp/web/web_driver_pages.dart' show WebJobDetail;
import 'package:parkingapp/web/web_frame.dart';
import 'package:parkingapp/chat/web_media.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/models/CheckPointRequestModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/NonEditatbleTextFeild.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Job detail for employees: customer, car, flights, and Start/End job.
class Bookingdetaildriver extends StatefulWidget {
  const Bookingdetaildriver({Key? key}) : super(key: key);

  @override
  State<Bookingdetaildriver> createState() => BookingdetaildriverState();
}

class BookingdetaildriverState extends State<Bookingdetaildriver> {
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;

  Parking? get _job => Globals.bookingDriverResponse;
  Registration? get _reg =>
      (_job?.registrations.isNotEmpty ?? false) ? _job!.registrations.first : null;
  Vehicle? get _car =>
      (_job?.vehicles.isNotEmpty ?? false) ? _job!.vehicles.first : null;

  String _v(String? s) => (s == null || s.trim().isEmpty) ? '-' : s;

  @override
  Widget build(BuildContext context) {
    final job = _job;
    // Web, sidebar layout: desktop page (same actions as below)
    if (kIsWeb && job != null && WebFrame.inDesktopShell(context)) {
      return WebJobDetail(
        job: job,
        submitting: _submitting,
        onBack: () => Navigator.of(context).pop(),
        onAction: () => _onActionPressed(job, job.isStarted),
        onWhatsApp: _launchWhatsApp,
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: "Job Detail",
              showBackButton: true,
              onBackPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: job == null
                  ? const Center(child: Text("Job not found"))
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statusBanner(job),
                          SizedBox(height: 20.h),
                          _heading("Booking Information"),
                          _field("Customer Name",
                              "${_reg?.firstName ?? ''} ${_reg?.lastName ?? ''}"),
                          _field("Contact Number", _v(_reg?.phoneNo)),
                          _twoFields("Start", "${job.startDate}  ${job.startTime}",
                              "End", "${job.endDate}  ${job.endTime}"),
                          SizedBox(height: 8.h),
                          _heading("Car Details"),
                          _field("Car Registration No",
                              _v(_car?.vehicleRegistration)),
                          _twoFields("Car Maker", _v(_car?.vehicleManufacturer),
                              "Car Model", _v(_car?.vehicleModel)),
                          _field("Colour", _v(_car?.vehicleColour)),
                          SizedBox(height: 8.h),
                          _heading("Flight Details"),
                          _twoFields(
                              "Outbound Terminal",
                              _v(_reg?.outboundTerminal),
                              "Inbound Terminal",
                              _v(_reg?.inboundTerminal)),
                          _twoFields(
                              "Outbound Flight",
                              _v(_reg?.outboundFlightNo),
                              "Inbound Flight",
                              _v(_reg?.inboundFlightNo)),
                          if ((_reg?.phoneNo ?? '').isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            GestureDetector(
                              onTap: _launchWhatsApp,
                              child: Row(
                                children: [
                                  Icon(Icons.chat,
                                      color: colors.secondarynew, size: 24.sp),
                                  SizedBox(width: 10.w),
                                  Text(
                                    "Chat with customer on WhatsApp",
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        color: colors.primaryNew,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: 24.h),
                          _actions(job),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI pieces ----------------

  Widget _heading(String text) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Text(text,
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Archivo',
                color: const Color(0xFF1A1A2E))),
      );

  Widget _label(String text) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(text,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
      );

  Widget _field(String label, String value) => Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(label),
            NonEditableTextField(hintText: "", value: value),
          ],
        ),
      );

  Widget _twoFields(String l1, String v1, String l2, String v2) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _field(l1, v1)),
          SizedBox(width: 10.w),
          Expanded(child: _field(l2, v2)),
        ],
      );

  Widget _statusBanner(Parking job) {
    final String text;
    final Color color;
    final IconData icon;
    if (job.isCompleted) {
      text = "Job completed";
      color = colors.secondarynew;
      icon = Icons.check_circle;
    } else if (job.isStarted) {
      text = "Car collected: end the job when it is returned";
      color = Colors.orange.shade800;
      icon = Icons.directions_car;
    } else {
      text = "Not started: start the job when you collect the car";
      color = colors.primaryNew;
      icon = Icons.schedule;
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ],
      ),
    );
  }

  Widget _actions(Parking job) {
    if (job.isCompleted) return const SizedBox.shrink();
    final isEnd = job.isStarted;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : () => _onActionPressed(job, isEnd),
        icon: Icon(isEnd ? Icons.flag : Icons.play_arrow,
            color: Colors.white, size: 20.sp),
        label: Text(isEnd ? "End Job" : "Start Job",
            style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnd ? colors.secondarynew : colors.primaryNew,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      ),
    );
  }

  // ---------------- Start / End ----------------

  /// Start is allowed from the start date, End from the end date.
  void _onActionPressed(Parking job, bool isEnd) {
    final dateStr = isEnd ? job.endDate : job.startDate;
    final date = DateTime.tryParse(dateStr);
    if (date != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (today.isBefore(DateTime(date.year, date.month, date.day))) {
        _snack(isEnd
            ? "This job can be ended from $dateStr"
            : "This job can be started from $dateStr");
        return;
      }
    }
    _showCheckpointPopup(isEnd ? "dropoff" : "pickup");
  }

  Future<void> _showCheckpointPopup(String type) async {
    final isEnd = type == "dropoff";
    final locationCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final images = <File>[];
    String? error;

    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> pick(ImageSource source) async {
            final picked =
                await _picker.pickImage(source: source, imageQuality: 85);
            if (picked != null) {
              setDialogState(() => images.add(File(picked.path)));
            }
          }

          return AlertDialog(
            title: Text(isEnd ? "End Job" : "Start Job"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: locationCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Location'),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: sectionCtrl,
                    decoration: const InputDecoration(labelText: 'Section'),
                  ),
                  SizedBox(height: 16.h),
                  Text("Photos (at least 1, max 5)",
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      // Desktop browsers have no camera picker (same file dialog)
                      if (!(kIsWeb && WebFrame.inDesktopShell(context)))
                        IconButton.filledTonal(
                          onPressed: images.length >= 5
                              ? null
                              : () => pick(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                        ),
                      IconButton.filledTonal(
                        onPressed: images.length >= 5
                            ? null
                            : () => pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                      ),
                    ],
                  ),
                  // Wrap, not ListView: dialogs size content by intrinsic
                  // width, which a scrolling list can't provide (blank dialog).
                  if (images.isNotEmpty)
                    Wrap(
                        children: [
                          for (int i = 0; i < images.length; i++)
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: localImage(images[i].path,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: GestureDetector(
                                      onTap: () => setDialogState(
                                          () => images.removeAt(i)),
                                      child: const CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.black54,
                                        child: Icon(Icons.close,
                                            size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                    ),
                  if (error != null) ...[
                    SizedBox(height: 8.h),
                    Text(error!,
                        style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isEnd ? colors.secondarynew : colors.primaryNew),
                onPressed: () {
                  if (locationCtrl.text.trim().isEmpty ||
                      sectionCtrl.text.trim().isEmpty) {
                    setDialogState(
                        () => error = "Please enter location and section.");
                    return;
                  }
                  if (images.isEmpty) {
                    setDialogState(
                        () => error = "Please add at least one photo.");
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: Text(isEnd ? "End Job" : "Start Job",
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    if (submitted == true) {
      await _submitCheckpoint(
          type, locationCtrl.text.trim(), sectionCtrl.text.trim(), images);
    }
    locationCtrl.dispose();
    sectionCtrl.dispose();
  }

  Future<void> _submitCheckpoint(
      String type, String location, String section, List<File> images) async {
    final reg = _reg;
    if (reg == null) {
      _snack("This booking has no registration details.");
      return;
    }
    setState(() => _submitting = true);
    try {
      // On success the repository shows a dialog and returns to the home tab.
      await GeneralRepository().submitCheckpoint(
        context,
        CheckpointRequestModel(
          bookingId: reg.bookingId,
          location: location,
          section: section,
          type: type,
        ),
        images,
      );
    } catch (e) {
      _snack(_cleanError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _cleanError(Object e) {
    final s = e.toString();
    return s
        .replaceFirst(RegExp(r'^(Exception: )?(API Error: )?'), '')
        .trim();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// WhatsApp needs digits with country code and no "+" or leading 0.
  /// UK numbers like 07700 900123 become 447700900123.
  String _toInternational(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+')) return d.substring(1).replaceAll('+', '');
    d = d.replaceAll('+', '');
    if (d.startsWith('00')) return d.substring(2);
    if (d.startsWith('0')) return '44${d.substring(1)}';
    return d;
  }

  Future<void> _launchWhatsApp() async {
    final phoneNumber = _toInternational(_reg?.phoneNo ?? '');
    if (phoneNumber.isEmpty) {
      _snack("No phone number for this customer");
      return;
    }
    final message =
        Uri.encodeComponent("Hello, I need help with your booking.");
    final url = Uri.parse(
        "https://api.whatsapp.com/send?phone=$phoneNumber&text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _snack("Could not open WhatsApp");
    }
  }
}
