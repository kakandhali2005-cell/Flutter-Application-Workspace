import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SqueezrApp());
}

class SqueezrApp extends StatelessWidget {
  const SqueezrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squeezr',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SqueezrHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SqueezrHome extends StatefulWidget {
  const SqueezrHome({super.key});

  @override
  State<SqueezrHome> createState() => _SqueezrHomeState();
}

class _SqueezrHomeState extends State<SqueezrHome> {
  Uint8List? _originalBytes;
  Uint8List? _compressedBytes;
  bool _isCompressing = false;
  String? _error;
  double? _originalSizeKB;
  double? _compressedSizeKB;

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _originalBytes = bytes;
          _compressedBytes = null;
          _error = null;
          _isCompressing = true;
          _originalSizeKB = bytes.length / 1024;
          _compressedSizeKB = null;
        });

        await compressImage(bytes);
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking image: $e';
        _isCompressing = false;
      });
    }
  }

  Future<void> compressImage(Uint8List imageBytes) async {
    try {
      final Uint8List? compressedBytes =
      await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null || compressedBytes.isEmpty) {
        throw Exception('Compression failed: returned empty result');
      }

      setState(() {
        _compressedBytes = compressedBytes;
        _compressedSizeKB = compressedBytes.length / 1024;
        _isCompressing = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error compressing image: $e';
        _isCompressing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,

        // Logo + App name
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.compress_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Squeezr',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ],
        ),

        // Action buttons
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pick image button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isCompressing ? null : pickImage,
              icon: Icon(
                _isCompressing
                    ? Icons.hourglass_top_rounded
                    : Icons.add_photo_alternate_rounded,
              ),
              label: Text(
                _isCompressing ? 'Compressing...' : 'Pick & Compress Image',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Original image
            if (_originalBytes != null) ...[
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.photo_outlined,
                label: 'Original',
                sizeKB: _originalSizeKB,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_originalBytes!),
              ),
            ],

            // Compressed image
            if (_compressedBytes != null) ...[
              const SizedBox(height: 20),
              _SectionLabel(
                icon: Icons.compress_rounded,
                label: 'Compressed',
                sizeKB: _compressedSizeKB,
                isCompressed: true,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_compressedBytes!),
              ),

              // Stats card
              if (_originalSizeKB != null && _compressedSizeKB != null) ...[
                const SizedBox(height: 16),
                _StatsCard(
                  originalKB: _originalSizeKB!,
                  compressedKB: _compressedSizeKB!,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? sizeKB;
  final bool isCompressed;

  const _SectionLabel({
    required this.icon,
    required this.label,
    this.sizeKB,
    this.isCompressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: isCompressed
                ? const Color(0xFF0F766E)
                : const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isCompressed
                ? const Color(0xFF0F766E)
                : const Color(0xFF374151),
          ),
        ),
        if (sizeKB != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isCompressed
                  ? const Color(0xFFCCFBF1)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${sizeKB!.toStringAsFixed(1)} KB',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isCompressed
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final double originalKB;
  final double compressedKB;

  const _StatsCard({
    required this.originalKB,
    required this.compressedKB,
  });

  @override
  Widget build(BuildContext context) {
    final reduction =
    ((originalKB - compressedKB) / originalKB * 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFBF1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
              label: 'Original', value: '${originalKB.toStringAsFixed(1)} KB'),
          Container(width: 1, height: 36, color: const Color(0xFF99F6E4)),
          _StatItem(
              label: 'Compressed',
              value: '${compressedKB.toStringAsFixed(1)} KB',
              highlight: true),
          Container(width: 1, height: 36, color: const Color(0xFF99F6E4)),
          _StatItem(
              label: 'Saved',
              value: '${reduction.toStringAsFixed(1)}%',
              highlight: true),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: highlight
                ? const Color(0xFF0F766E)
                : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}