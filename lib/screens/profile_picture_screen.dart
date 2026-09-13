import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_display.dart';
import '../widgets/icon_badge.dart';
import 'crop_photo_screen.dart';

/// Filenames of bundled default avatars, relative to
/// `assets/images/avatars/`. Empty until default avatar images are added —
/// see assets/images/avatars/README.md.
const List<String> kDefaultAvatarAssets = [];

class ProfilePictureScreen extends StatefulWidget {
  final String initials;
  const ProfilePictureScreen({super.key, required this.initials});

  @override
  State<ProfilePictureScreen> createState() => _ProfilePictureScreenState();
}

class _ProfilePictureScreenState extends State<ProfilePictureScreen> {
  String? _current;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _current = DbService.getProfilePicture();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isWorking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null) return;
      if (!mounted) return;

      final bytes = await File(picked.path).readAsBytes();
      if (!mounted) return;
      final cropped = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (_) => CropPhotoScreen(imageBytes: bytes)),
      );
      if (cropped == null) return; // user backed out of the crop screen

      final docsDir = await getApplicationDocumentsDirectory();
      final savedPath = '${docsDir.path}/profile_picture.jpg';
      await File(savedPath).writeAsBytes(cropped);
      await DbService.setProfilePicture('file:$savedPath');
      unawaited(SyncService.pushProfile());
      if (!mounted) return;
      setState(() => _current = 'file:$savedPath');
    } catch (_) {
      if (!mounted) return;
      final colors = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? "Couldn't access the camera"
                : "Couldn't access your photos",
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              color: colors.onError,
            ),
          ),
          backgroundColor: colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _chooseDefaultAvatar(String assetPath) async {
    await DbService.setProfilePicture('asset:$assetPath');
    unawaited(SyncService.pushProfile());
    if (!mounted) return;
    setState(() => _current = 'asset:$assetPath');
  }

  Future<void> _confirmRemovePhoto() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove profile picture?',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
        content: Text(
          "You'll go back to your initials until you set a new one.",
          style: GoogleFonts.nunito(color: colors.accent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: GoogleFonts.nunito(
                color: colors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await DbService.setProfilePicture(null);
    unawaited(SyncService.pushProfile());
    if (!mounted) return;
    setState(() => _current = null);
  }

  Widget _actionTile(
    AppColors colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isWorking ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: colors.cardShadow,
        ),
        child: Row(
          children: [
            IconBadge(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.deep,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: colors.accent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.deep, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile picture',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    AvatarImage(
                      pictureValue: _current,
                      initials: widget.initials,
                      size: 160,
                    ),
                    if (_isWorking)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _actionTile(
                colors,
                icon: Icons.camera_alt_outlined,
                label: 'Take a photo',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              _actionTile(
                colors,
                icon: Icons.photo_library_outlined,
                label: 'Choose from your photos',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'App default avatars',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (kDefaultAvatarAssets.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(kCardRadius),
                    boxShadow: colors.cardShadow,
                  ),
                  child: Text(
                    'No default avatars yet — check back soon!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textDim,
                    ),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: kDefaultAvatarAssets.map((name) {
                    final assetPath = 'assets/images/avatars/$name';
                    final isSelected = _current == 'asset:$assetPath';
                    return GestureDetector(
                      onTap: () => _chooseDefaultAvatar(assetPath),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colors.accent : colors.border,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: Image.asset(assetPath, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (_current != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isWorking ? null : _confirmRemovePhoto,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.danger,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Remove photo',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
