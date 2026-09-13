import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Full-screen photo cropper rendered entirely with Flutter widgets (no
/// native platform screen), so it inherits this app's own SafeArea/inset
/// handling instead of fighting a third-party native activity's edge-to-edge
/// quirks. Pops with the cropped image bytes, or `null` if cancelled.
class CropPhotoScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const CropPhotoScreen({super.key, required this.imageBytes});

  @override
  State<CropPhotoScreen> createState() => _CropPhotoScreenState();
}

class _CropPhotoScreenState extends State<CropPhotoScreen> {
  final _controller = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Adjust photo',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: _isCropping
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.accent,
                            ),
                          )
                        : Icon(Icons.check, color: colors.accent),
                    onPressed: _isCropping ? null : _controller.crop,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Crop(
                controller: _controller,
                image: widget.imageBytes,
                aspectRatio: 1,
                withCircleUi: true,
                interactive: true,
                baseColor: Colors.black,
                maskColor: Colors.black.withValues(alpha: 0.65),
                progressIndicator: CircularProgressIndicator(
                  color: colors.accent,
                ),
                onStatusChanged: (status) {
                  if (!mounted) return;
                  setState(() => _isCropping = status == CropStatus.cropping);
                },
                onCropped: (result) {
                  switch (result) {
                    case CropSuccess(:final croppedImage):
                      Navigator.pop(context, croppedImage);
                    case CropFailure():
                      Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
