import 'dart:math';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n.dart';
import '../lock.dart';
import '../profile.dart';
import '../repo.dart';
import '../theme.dart';

/// Halaman manajemen profil: Foto profil, nama panggilan (nickname), serta info akun.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, this.enableHero = true});

  final bool enableHero;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _nicknameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: ref.read(profileProvider).nickname ?? '',
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickPhoto(ImageSource source) async {
    await Lock.instance.suppressLockDuring(() async {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 90,
        );
        if (picked == null) return;
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        await _startCrop(bytes);
      } catch (_) {
        // Fallback untuk platform desktop / file selector
        try {
          const typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'png', 'jpeg', 'webp']);
          final file = await openFile(acceptedTypeGroups: [typeGroup]);
          if (file == null) return;
          final bytes = await file.readAsBytes();
          if (!mounted) return;
          await _startCrop(bytes);
        } catch (e) {
          if (mounted) _toast(tr('Could not pick a photo: {0}', [e]));
        }
      }
    });
  }

  Future<void> _startCrop(Uint8List bytes) async {
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => ProfilePhotoCropPage(imageBytes: bytes),
      ),
    );
    if (cropped == null) return;
    await ref.read(profileProvider.notifier).setPhoto(cropped);
    if (mounted) {
      HapticFeedback.mediumImpact();
      _toast(tr('Profile photo updated.'));
    }
  }

  void _viewPhoto() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfilePhotoViewPage(),
      ),
    );
  }

  Future<void> _confirmRemovePhoto() async {
    final confirmed = await confirm(context, tr('Remove profile photo?'));
    if (!confirmed || !mounted) return;
    await ref.read(profileProvider.notifier).setPhoto(null);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _toast(tr('Profile photo removed.'));
  }

  void _showPhotoBottomSheet(BuildContext context) {
    final hasPhoto = ref.read(profileProvider).photo != null;
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('Profile Photo'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (hasPhoto)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        tooltip: tr('Remove photo'),
                        onPressed: () {
                          Navigator.of(sheetCtx).pop();
                          _confirmRemovePhoto();
                        },
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PhotoActionItem(
                      icon: Icons.photo_camera_rounded,
                      label: tr('Camera'),
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        _pickPhoto(ImageSource.camera);
                      },
                    ),
                    _PhotoActionItem(
                      icon: Icons.photo_library_rounded,
                      label: tr('Gallery'),
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        _pickPhoto(ImageSource.gallery);
                      },
                    ),
                    if (hasPhoto)
                      _PhotoActionItem(
                        icon: Icons.visibility_rounded,
                        label: tr('View Photo'),
                        onTap: () {
                          Navigator.of(sheetCtx).pop();
                          _viewPhoto();
                        },
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).setNickname(_nicknameController.text);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _toast(tr('Profile saved.'));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _toast(tr('Failed to save profile: {0}', [e]));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).value;
    final username = user?.displayName;
    final hasPhoto = ref.watch(profileProvider.select((s) => s.photo != null));
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Profile'), style: display(22)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  size: 112,
                  heroTag: widget.enableHero ? 'profile_photo_hero' : null,
                  onTap: () {
                    if (hasPhoto) {
                      _viewPhoto();
                    } else {
                      _showPhotoBottomSheet(context);
                    }
                  },
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: C.peony,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _showPhotoBottomSheet(context),
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _showPhotoBottomSheet(context),
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(tr('Change photo')),
              ),
              if (hasPhoto) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _viewPhoto,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(tr('View Photo')),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: cardBox(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nicknameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 30,
                  decoration: InputDecoration(
                    labelText: tr('Nickname'),
                    hintText: tr('e.g. Lunaria'),
                    helperText: tr('Shown in greetings on the Home screen and profile card.'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                gap(16),
                if (username != null && username.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.alternate_email_rounded, color: C.peony),
                    title: Text('@$username', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(tr('Account username')),
                  ),
                if (user?.email != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.mail_outline_rounded, color: C.peony),
                    title: Text(user!.email!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(tr('Registered email')),
                  ),
                gap(8),
                Text(
                  tr('Username and email are used for login authentication and cannot be changed.'),
                  style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          gap(24),
          pillButton(
            _saving ? '...' : tr('Save Profile'),
            _saving ? () {} : _save,
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }
}

/// Item aksi foto bergaya bundar.
class _PhotoActionItem extends StatelessWidget {
  const _PhotoActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(icon, color: C.peony, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Halaman sesi Crop / Potong Foto Profil interaktif.
/// Memungkinkan pengguna menggeser, memperbesar (zoom), dan memutar foto dalam lingkaran viewfinder.
class ProfilePhotoCropPage extends StatefulWidget {
  const ProfilePhotoCropPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<ProfilePhotoCropPage> createState() => _ProfilePhotoCropPageState();
}

class _ProfilePhotoCropPageState extends State<ProfilePhotoCropPage> {
  final TransformationController _transformController = TransformationController();
  ui.Image? _rawImage;
  bool _isLoading = true;
  bool _isSaving = false;
  int _quarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _rawImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _rotate() {
    HapticFeedback.lightImpact();
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _transformController.value = Matrix4.identity();
    });
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _quarterTurns = 0;
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _cropAndSave(double cropSize) async {
    if (_rawImage == null || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      const targetSize = 512.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, targetSize, targetSize));

      final scaleFactor = targetSize / cropSize;
      canvas.scale(scaleFactor, scaleFactor);
      canvas.transform(_transformController.value.storage);

      final rawW = _rawImage!.width.toDouble();
      final rawH = _rawImage!.height.toDouble();
      final isRotated = _quarterTurns % 2 == 1;
      final effW = isRotated ? rawH : rawW;
      final effH = isRotated ? rawW : rawH;

      final fitScale = min(cropSize / effW, cropSize / effH);
      final drawW = effW * fitScale;
      final drawH = effH * fitScale;
      final dx = (cropSize - drawW) / 2;
      final dy = (cropSize - drawH) / 2;

      canvas.save();
      canvas.translate(dx + drawW / 2, dy + drawH / 2);
      canvas.rotate(_quarterTurns * pi / 2);
      canvas.translate(-rawW * fitScale / 2, -rawH * fitScale / 2);
      canvas.drawImageRect(
        _rawImage!,
        Rect.fromLTWH(0, 0, rawW, rawH),
        Rect.fromLTWH(0, 0, rawW * fitScale, rawH * fitScale),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();

      final picture = recorder.endRecording();
      final croppedImg = await picture.toImage(targetSize.toInt(), targetSize.toInt());
      final byteData = await croppedImg.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        Navigator.of(context).pop(byteData.buffer.asUint8List());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Could not pick a photo: {0}', [e]))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          tr('Crop Photo'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: tr('Reset'),
            onPressed: _reset,
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined, color: Colors.white),
            tooltip: tr('Rotate'),
            onPressed: _rotate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (context, constraints) {
                final maxDim = min(constraints.maxWidth - 32, constraints.maxHeight - 120);
                final cropSize = maxDim.clamp(240.0, 360.0);

                final rawW = _rawImage!.width.toDouble();
                final rawH = _rawImage!.height.toDouble();
                final isRotated = _quarterTurns % 2 == 1;
                final effW = isRotated ? rawH : rawW;
                final effH = isRotated ? rawW : rawH;

                final fitScale = min(cropSize / effW, cropSize / effH);
                final drawW = effW * fitScale;
                final drawH = effH * fitScale;

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: cropSize,
                          height: cropSize,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRect(
                                child: InteractiveViewer(
                                  transformationController: _transformController,
                                  minScale: 0.8,
                                  maxScale: 4.0,
                                  boundaryMargin: EdgeInsets.all(cropSize * 0.8),
                                  child: SizedBox(
                                    width: cropSize,
                                    height: cropSize,
                                    child: Center(
                                      child: RotatedBox(
                                        quarterTurns: _quarterTurns,
                                        child: SizedBox(
                                          width: isRotated ? drawH : drawW,
                                          height: isRotated ? drawW : drawH,
                                          child: Image.memory(
                                            widget.imageBytes,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: CustomPaint(
                                  size: Size(cropSize, cropSize),
                                  painter: const _WhatsAppCropOverlayPainter(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        child: Row(
                          children: [
                            Flexible(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  tr('Cancel'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.rotate_90_degrees_cw_outlined, color: Colors.white),
                              tooltip: tr('Rotate'),
                              onPressed: _rotate,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: C.peony,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onPressed: _isSaving ? null : () => _cropAndSave(cropSize),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check, size: 18),
                                label: Text(
                                  tr('Done'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Overlay masker pemotong lingkaran bergaya WhatsApp.
class _WhatsAppCropOverlayPainter extends CustomPainter {
  const _WhatsAppCropOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Lapisan gelap di luar lingkaran
    final overlayPath = Path()
      ..addRect(rect)
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );

    // 2. Garis lingkaran putih
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 3. Garis pandu grid rule-of-thirds di dalam lingkaran
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final step = size.width / 3;
    canvas.drawLine(Offset(step, 0), Offset(step, size.height), gridPaint);
    canvas.drawLine(Offset(step * 2, 0), Offset(step * 2, size.height), gridPaint);
    canvas.drawLine(Offset(0, step), Offset(size.width, step), gridPaint);
    canvas.drawLine(Offset(0, step * 2), Offset(size.width, step * 2), gridPaint);
    canvas.restore();

    // 4. Bracket sudut bingkai foto (gaya WhatsApp)
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    const cornerLen = 18.0;

    // Kiri-atas
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLen)
        ..lineTo(0, 0)
        ..lineTo(cornerLen, 0),
      cornerPaint,
    );
    // Kanan-atas
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerLen),
      cornerPaint,
    );
    // Kiri-bawah
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLen)
        ..lineTo(0, size.height)
        ..lineTo(cornerLen, size.height),
      cornerPaint,
    );
    // Kanan-bawah
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Halaman penampil foto profil layar penuh dengan zoom & pan interaktif.
class ProfilePhotoViewPage extends ConsumerWidget {
  const ProfilePhotoViewPage({super.key});

  Future<void> _pickAndCrop(BuildContext context, WidgetRef ref, ImageSource source) async {
    await Lock.instance.suppressLockDuring(() async {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 90,
        );
        if (picked == null) return;
        final bytes = await picked.readAsBytes();
        if (!context.mounted) return;

        final cropped = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(
            builder: (_) => ProfilePhotoCropPage(imageBytes: bytes),
          ),
        );
        if (cropped == null) return;
        await ref.read(profileProvider.notifier).setPhoto(cropped);
        if (context.mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('Profile photo updated.'))),
          );
        }
      } catch (_) {
        try {
          const typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'png', 'jpeg', 'webp']);
          final file = await openFile(acceptedTypeGroups: [typeGroup]);
          if (file == null) return;
          final bytes = await file.readAsBytes();
          if (!context.mounted) return;

          final cropped = await Navigator.of(context).push<Uint8List>(
            MaterialPageRoute(
              builder: (_) => ProfilePhotoCropPage(imageBytes: bytes),
            ),
          );
          if (cropped == null) return;
          await ref.read(profileProvider.notifier).setPhoto(cropped);
          if (context.mounted) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('Profile photo updated.'))),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('Could not pick a photo: {0}', [e]))),
            );
          }
        }
      }
    });
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirm(context, tr('Remove profile photo?'));
    if (!confirmed || !context.mounted) return;
    await ref.read(profileProvider.notifier).setPhoto(null);
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Profile photo removed.'))),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final sheetTheme = Theme.of(sheetCtx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: sheetTheme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('Change photo'),
                        style: sheetTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PhotoActionItem(
                      icon: Icons.photo_camera_rounded,
                      label: tr('Camera'),
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        _pickAndCrop(context, ref, ImageSource.camera);
                      },
                    ),
                    _PhotoActionItem(
                      icon: Icons.photo_library_rounded,
                      label: tr('Gallery'),
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        _pickAndCrop(context, ref, ImageSource.gallery);
                      },
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final photo = profile.photo;
    final name = ref.watch(displayNameProvider) ?? tr('Profile Photo');

    // Jika foto dihapus saat di viewer, otomatis kembali.
    if (photo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: tr('Change photo'),
            onPressed: () => _showPicker(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            tooltip: tr('Remove photo'),
            onPressed: () => _confirmRemove(context, ref),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          child: Hero(
            tag: 'profile_photo_hero',
            child: Image.memory(
              photo,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
