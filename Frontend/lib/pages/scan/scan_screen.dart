import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../components/app_bar.dart';
import '../../utils/constants.dart';

/// Screen 19: Receipt & Image Capture / Upload
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isProcessing = false;

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isProcessing = true);
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes ?? await file.xFile.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      final ext = file.extension?.toLowerCase() ?? 'png';
      final base64Str = 'data:image/$ext;base64,${base64Encode(bytes)}';

      if (!mounted) return;
      Navigator.pop(context, {
        'source': 'gallery',
        'name': file.name,
        'data': base64Str,
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  void _capturePhoto() {
    // Simulated camera capture: generate a receipt image record
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final photoName = 'receipt_$timestamp.jpg';
    Navigator.pop(context, {
      'source': 'camera',
      'name': photoName,
      'data': 'captured_receipt_$timestamp',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(
        title: 'Attach Receipt / Invoice',
        showBack: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Viewfinder simulation
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              height: 340,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.document_scanner_outlined, size: 48, color: AppColors.primary.withAlpha(200)),
                      const SizedBox(height: 12),
                      const Text(
                        'Align Receipt in Frame',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Take a photo or upload an image below',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                  // Corner target indicators
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.primary, width: 4), left: BorderSide(color: AppColors.primary, width: 4)))),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.primary, width: 4), right: BorderSide(color: AppColors.primary, width: 4)))),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primary, width: 4), left: BorderSide(color: AppColors.primary, width: 4)))),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(width: 24, height: 24, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primary, width: 4), right: BorderSide(color: AppColors.primary, width: 4)))),
                  ),
                ],
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Bottom Controls: Shutter button & Upload from Gallery
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Flash / placeholder control
                    IconButton(
                      icon: const Icon(Icons.flash_auto_rounded, color: Colors.white70, size: 28),
                      onPressed: () {},
                    ),

                    // Center Shutter Capture Button
                    GestureDetector(
                      onTap: _capturePhoto,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.black87, size: 28),
                          ),
                        ),
                      ),
                    ),

                    // Upload from gallery icon
                    IconButton(
                      tooltip: 'Upload Picture',
                      icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 30),
                      onPressed: _pickFromGallery,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap Shutter to Capture • Tap Gallery to Upload',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
