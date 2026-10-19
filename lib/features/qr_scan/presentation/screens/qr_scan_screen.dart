// =========================================================
// QR + BARCODE SCAN MODULE
// Scan -> API Lookup -> Asset / Location Details
// =========================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import 'package:assets_app/core/utils/app_colors.dart';
import 'package:assets_app/core/utils/api_service.dart';

// =========================================================
// SCAN MODE
// =========================================================

enum ScanMode { qr, barcode }

// =========================================================
// QR FORMATS
// =========================================================
 
const Set<BarcodeFormat> _qrFormats = {BarcodeFormat.qrCode};

// =========================================================
// BARCODE FORMATS
// =========================================================

const Set<BarcodeFormat> _barcodeFormats = {
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.itf,
};

// =========================================================
// QR SCAN SCREEN
// =========================================================

class QRScanScreen extends ConsumerWidget {
  final ScanMode initialMode;

  const QRScanScreen({super.key, this.initialMode = ScanMode.qr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,

        title: const Text(
          'Scan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // =================================================
            // ICON
            // =================================================
            Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),

            const SizedBox(height: 16),

            // =================================================
            // TITLE
            // =================================================
            const Text(
              'Scan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // =================================================
            // SUB TITLE
            // =================================================
            const Text(
              'Scan a QR code or a barcode instantly',
              style: TextStyle(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 28),

            // =================================================
            // START SCANNING
            // =================================================
            ElevatedButton.icon(
              onPressed: () {
                _openScanner(context, ref, initialMode);
              },

              icon: const Icon(Icons.qr_code_scanner, size: 20),

              label: const Text('Start Scanning'),

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,

                foregroundColor: Colors.white,

                elevation: 0,

                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),

                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // QUICK LAUNCH BUTTONS
            // =================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // QR
                _QuickLaunchChip(
                  icon: Icons.qr_code_2,
                  label: 'QR Code',

                  onTap: () {
                    _openScanner(context, ref, ScanMode.qr);
                  },
                ),

                const SizedBox(width: 12),

                // BARCODE
                _QuickLaunchChip(
                  icon: Icons.view_week_outlined,
                  label: 'Barcode',

                  onTap: () {
                    _openScanner(context, ref, ScanMode.barcode);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // OPEN CAMERA SCANNER
  // =========================================================

  Future<void> _openScanner(
    BuildContext context,
    WidgetRef ref,
    ScanMode mode,
  ) async {
    // -------------------------------------------------------
    // OPEN CAMERA
    // -------------------------------------------------------

    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => QRCameraScreen(initialMode: mode)),
    );

    // -------------------------------------------------------
    // NO RESULT
    // -------------------------------------------------------

    if (result == null || result.trim().isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final String scannedCode = result.trim();

    // -------------------------------------------------------
    // SHOW LOADING
    // -------------------------------------------------------

    showDialog<void>(
      context: context,

      barrierDismissible: false,

      builder: (_) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // =====================================================
      // API SERVICE
      // =====================================================

      final api = ref.read(apiServiceProvider);

      // =====================================================
      // SCAN LOOKUP API
      // =====================================================

      final response = await api.scanLookup(scannedCode);

      // =====================================================
      // CLOSE LOADING
      // =====================================================

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!context.mounted) {
        return;
      }

      // =====================================================
      // SUCCESS
      // =====================================================

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['status'] == 'success') {
        // ---------------------------------------------------
        // TYPE
        // asset / location
        // ---------------------------------------------------

        final String type = response.data['type']?.toString() ?? '';

        // ---------------------------------------------------
        // DATA
        // ---------------------------------------------------

        final dynamic rawData = response.data['data'];

        // ---------------------------------------------------
        // VALIDATE DATA
        // ---------------------------------------------------

        if (rawData is! Map) {
          _showError(context, 'Invalid data received from server');

          return;
        }

        // ---------------------------------------------------
        // CONVERT DATA
        // ---------------------------------------------------

        final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);

        // ===================================================
        // OPEN DETAILS SCREEN
        // ===================================================

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ScanDetailsScreen(code: scannedCode, type: type, data: data),
          ),
        );
      }
      // =====================================================
      // NOT FOUND
      // =====================================================
      else {
        String message = 'No Asset or Location found';

        if (response.data is Map) {
          message = response.data['message']?.toString() ?? message;
        }

        _showError(context, message);
      }
    }
    // =======================================================
    // API / NETWORK ERROR
    // =======================================================
    catch (e) {
      // -----------------------------------------------------
      // CLOSE LOADING
      // -----------------------------------------------------

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!context.mounted) {
        return;
      }

      // -----------------------------------------------------
      // ERROR MESSAGE
      // -----------------------------------------------------

      _showError(context, 'Unable to connect to server');
    }
  }

  // =========================================================
  // ERROR DIALOG
  // =========================================================

  void _showError(BuildContext context, String message) {
    showDialog<void>(
      context: context,

      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141D24),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          title: const Text(
            'Scan Result',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),

          content: Text(message, style: const TextStyle(color: Colors.white70)),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },

              child: const Text(
                'OK',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =========================================================
// SCAN DETAILS SCREEN
// =========================================================

class ScanDetailsScreen extends StatelessWidget {
  final String code;
  final String type;
  final Map<String, dynamic> data;

  const ScanDetailsScreen({
    super.key,
    required this.code,
    required this.type,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAsset = type.toLowerCase() == 'asset';

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,

        elevation: 0,

        title: Text(
          isAsset ? 'Asset Details' : 'Location Details',

          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // =================================================
              // HEADER
              // =================================================
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: AppColors.cardBackground,

                  borderRadius: BorderRadius.circular(16),

                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),

                child: Row(
                  children: [
                    // -------------------------------------------
                    // ICON
                    // -------------------------------------------
                    Container(
                      width: 54,
                      height: 54,

                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),

                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        isAsset
                            ? Icons.inventory_2_outlined
                            : Icons.location_on_outlined,

                        color: AppColors.primary,

                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // -------------------------------------------
                    // TITLE
                    // -------------------------------------------
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            isAsset ? 'Asset Found' : 'Location Found',

                            style: const TextStyle(
                              color: Colors.white,

                              fontSize: 18,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            code,

                            style: const TextStyle(
                              color: Colors.white60,

                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // SECTION TITLE
              // =================================================
              Text(
                isAsset ? 'Asset Information' : 'Location Information',

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // =================================================
              // DATABASE DATA
              // =================================================
              if (data.isEmpty)
                const _EmptyDataWidget()
              else
                ...data.entries.map((entry) {
                  return _DetailRow(
                    label: _formatLabel(entry.key),

                    value: _formatValue(entry.value),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FORMAT DATABASE FIELD NAME
  // =========================================================

  String _formatLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return word;
          }

          return '${word[0].toUpperCase()}'
              '${word.substring(1)}';
        })
        .join(' ');
  }

  // =========================================================
  // FORMAT VALUE
  // =========================================================

  String _formatValue(dynamic value) {
    if (value == null) {
      return '-';
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    return text;
  }
}

// =========================================================
// EMPTY DATA
// =========================================================

class _EmptyDataWidget extends StatelessWidget {
  const _EmptyDataWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(12),
      ),

      child: const Text(
        'No details available',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}

// =========================================================
// DETAIL ROW
// =========================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style: const TextStyle(
              color: AppColors.textSecondary,

              fontSize: 12,

              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 15,

              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// QUICK LAUNCH CHIP
// =========================================================

class _QuickLaunchChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLaunchChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),

      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

        decoration: BoxDecoration(
          color: AppColors.cardBackground,

          borderRadius: BorderRadius.circular(24),

          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(icon, size: 16, color: AppColors.primary),

            const SizedBox(width: 8),

            Text(
              label,

              style: const TextStyle(
                color: Colors.white,

                fontSize: 13,

                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// CAMERA SCREEN
// =========================================================

class QRCameraScreen extends StatefulWidget {
  final ScanMode initialMode;

  const QRCameraScreen({super.key, this.initialMode = ScanMode.qr});

  @override
  State<QRCameraScreen> createState() => _QRCameraScreenState();
}

class _QRCameraScreenState extends State<QRCameraScreen> {
  // ========================================================
  // CAMERA CONTROLLER
  // ========================================================

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  // ========================================================
  // IMAGE PICKER
  // ========================================================

  final ImagePicker _imagePicker = ImagePicker();

  // ========================================================
  // STATE
  // ========================================================

  late ScanMode _mode;

  bool _handled = false;

  bool _torchOn = false;

  String? _mismatchHint;

  // ========================================================
  // INIT
  // ========================================================

  @override
  void initState() {
    super.initState();

    _mode = widget.initialMode;
  }

  // ========================================================
  // DISPOSE
  // ========================================================

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ========================================================
  // ACTIVE FORMATS
  // ========================================================

  Set<BarcodeFormat> get _activeFormats =>
      _mode == ScanMode.qr ? _qrFormats : _barcodeFormats;

  // ========================================================
  // FRAME SIZE
  // ========================================================

  Size get _frameSize =>
      _mode == ScanMode.qr ? const Size(260, 260) : const Size(300, 160);

  // ========================================================
  // MICRO COPY
  // ========================================================

  String get _microCopy =>
      _mode == ScanMode.qr ? 'Scan QR code' : 'Align barcode within frame';

  // ========================================================
  // SWITCH MODE
  // ========================================================

  void _switchMode(ScanMode mode) {
    if (_mode == mode) {
      return;
    }

    setState(() {
      _mode = mode;
      _mismatchHint = null;
    });
  }

  // ========================================================
  // HANDLE BARCODE
  // ========================================================

  void _handleBarcode(Barcode barcode) {
    if (_handled) {
      return;
    }

    final String? value = barcode.rawValue;

    if (value == null) {
      return;
    }

    // ------------------------------------------------------
    // FORMAT CHECK
    // ------------------------------------------------------

    if (!_activeFormats.contains(barcode.format)) {
      final String suggestedMode = _mode == ScanMode.qr ? 'Barcode' : 'QR Code';

      setState(() {
        _mismatchHint =
            'That looks like a '
            '$suggestedMode — '
            'switch modes to scan it';
      });

      return;
    }

    // ------------------------------------------------------
    // CODE HANDLED
    // ------------------------------------------------------

    _handled = true;

    Navigator.of(context).pop(value);
  }

  // ========================================================
  // DETECT
  // ========================================================

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) {
      return;
    }

    _handleBarcode(capture.barcodes.first);
  }

  // ========================================================
  // TORCH
  // ========================================================

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();

    if (!mounted) {
      return;
    }

    setState(() => _torchOn = !_torchOn);
  }

  // ========================================================
  // SCAN FROM PHOTO
  // ========================================================

  Future<void> _scanFromPhoto() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null || !mounted) {
      return;
    }

    // ------------------------------------------------------
    // ANALYZE IMAGE
    // ------------------------------------------------------

    final BarcodeCapture? capture = await _controller.analyzeImage(picked.path);

    if (capture == null || capture.barcodes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No code found in that photo')),
        );
      }

      return;
    }

    // ------------------------------------------------------
    // REUSE HANDLER
    // ------------------------------------------------------

    _handleBarcode(capture.barcodes.first);
  }

  // ========================================================
  // INFO
  // ========================================================

  void _showInfo() {
    showDialog(
      context: context,

      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141D24),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

        title: const Text(
          'Scanning tips',
          style: TextStyle(color: Colors.white),
        ),

        content: Text(
          _mode == ScanMode.qr
              ? 'Hold your phone steady '
                    'and align the QR code '
                    'fully inside the frame. '
                    'Make sure the code is '
                    'well lit and not blurry.'
              : 'Hold your phone steady '
                    'and align the barcode '
                    'fully inside the frame, '
                    'with the stripes running '
                    'left to right. Make sure '
                    'the code is well lit and '
                    'not blurry.',

          style: const TextStyle(color: Colors.white70),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),

            child: const Text(
              'Got it',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // BUILD CAMERA
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        fit: StackFit.expand,

        children: [
          // =================================================
          // CAMERA
          // =================================================
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // =================================================
          // SCRIM
          // =================================================
          _ScannerScrim(frameSize: _frameSize),

          // =================================================
          // MODE TOGGLE
          // =================================================
          Positioned(
            top: 0,
            left: 0,
            right: 0,

            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),

                child: Center(
                  child: _ModeToggle(mode: _mode, onChanged: _switchMode),
                ),
              ),
            ),
          ),

          // =================================================
          // CENTER FRAME
          // =================================================
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // -------------------------------------------
                // FRAME
                // -------------------------------------------
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),

                  curve: Curves.easeInOutCubic,

                  width: _frameSize.width,

                  height: _frameSize.height,

                  child: CustomPaint(
                    size: _frameSize,

                    painter: _CornerBracketPainter(
                      color: Colors.white,

                      strokeWidth: 4,

                      cornerLength: 32,

                      borderRadius: 24,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // -------------------------------------------
                // MICRO COPY
                // -------------------------------------------
                Text(
                  _microCopy,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 22,

                    fontWeight: FontWeight.w500,

                    fontFamily: 'SF Pro',
                  ),
                ),

                // -------------------------------------------
                // MISMATCH HINT
                // -------------------------------------------
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),

                  child: _mismatchHint == null
                      ? const SizedBox(height: 0)
                      : Padding(
                          key: ValueKey(_mismatchHint),

                          padding: const EdgeInsets.only(top: 10),

                          child: Text(
                            _mismatchHint!,

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: Colors.amber.shade300,

                              fontSize: 13,

                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // -------------------------------------------
                // CONTROLS
                // -------------------------------------------
                Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    // CLOSE
                    _CircleIconButton(
                      icon: Icons.close,

                      onTap: () => Navigator.of(context).pop(),
                    ),

                    const SizedBox(width: 16),

                    // FLASH
                    _CircleIconButton(
                      icon: _torchOn ? Icons.flash_on : Icons.flash_off,

                      onTap: _toggleTorch,
                    ),

                    const SizedBox(width: 16),

                    // INFO
                    _CircleIconButton(
                      icon: Icons.info_outline,

                      onTap: _showInfo,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // =================================================
          // SCAN FROM PHOTO
          // =================================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,

            child: Center(
              child: GestureDetector(
                onTap: _scanFromPhoto,

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),

                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: const Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Icon(Icons.image_outlined, color: Colors.white, size: 20),

                      SizedBox(width: 10),

                      Text(
                        'Scan from photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// MODE TOGGLE
// =========================================================

class _ModeToggle extends StatelessWidget {
  final ScanMode mode;
  final ValueChanged<ScanMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  static const double _optionWidth = 118;

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _optionWidth * 2 + 8,

      height: _height,

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),

        borderRadius: BorderRadius.circular(_height / 2),

        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),

      child: Stack(
        children: [
          // ===============================================
          // SELECTED INDICATOR
          // ===============================================
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),

            curve: Curves.easeInOutCubic,

            alignment: mode == ScanMode.qr
                ? Alignment.centerLeft
                : Alignment.centerRight,

            child: Container(
              width: _optionWidth - 4,

              height: _height - 8,

              decoration: BoxDecoration(
                color: AppColors.primary,

                borderRadius: BorderRadius.circular((_height - 8) / 2),
              ),
            ),
          ),

          // ===============================================
          // OPTIONS
          // ===============================================
          Row(
            children: [
              _ToggleOption(
                label: 'QR Code',

                width: _optionWidth,

                selected: mode == ScanMode.qr,

                onTap: () => onChanged(ScanMode.qr),
              ),

              _ToggleOption(
                label: 'Barcode',

                width: _optionWidth,

                selected: mode == ScanMode.barcode,

                onTap: () => onChanged(ScanMode.barcode),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================
// TOGGLE OPTION
// =========================================================

class _ToggleOption extends StatelessWidget {
  final String label;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: double.infinity,

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: onTap,

        child: Center(
          child: Text(
            label,

            style: TextStyle(
              color: selected ? Colors.white : Colors.white60,

              fontSize: 13,

              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// CIRCLE ICON BUTTON
// =========================================================

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),

      onTap: onTap,

      child: Container(
        width: 44,
        height: 44,

        alignment: Alignment.center,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          color: Colors.black.withValues(alpha: 0.35),
        ),

        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// =========================================================
// SCANNER SCRIM
// =========================================================

class _ScannerScrim extends StatelessWidget {
  final Size frameSize;

  const _ScannerScrim({required this.frameSize});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,

        painter: _ScrimPainter(frameSize: frameSize),
      ),
    );
  }
}

// =========================================================
// SCRIM PAINTER
// =========================================================

class _ScrimPainter extends CustomPainter {
  final Size frameSize;

  _ScrimPainter({required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint scrimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45);

    final double left = (size.width - frameSize.width) / 2;

    final double top = (size.height - frameSize.height) / 2 - 60;

    // -------------------------------------------------------
    // OUTER
    // -------------------------------------------------------

    final Path outer = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // -------------------------------------------------------
    // HOLE
    // -------------------------------------------------------

    final Path hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, frameSize.width, frameSize.height),

          const Radius.circular(24),
        ),
      );

    // -------------------------------------------------------
    // DIFFERENCE
    // -------------------------------------------------------

    final Path scrim = Path.combine(PathOperation.difference, outer, hole);

    canvas.drawPath(scrim, scrimPaint);
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter oldDelegate) {
    return oldDelegate.frameSize != frameSize;
  }
}

// =========================================================
// CORNER BRACKET PAINTER
// =========================================================

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double borderRadius;

  _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double w = size.width;

    final double h = size.height;

    final double r = borderRadius;

    final double c = cornerLength;

    // =======================================================
    // TOP LEFT
    // =======================================================

    canvas.drawPath(
      Path()
        ..moveTo(0, c)
        ..lineTo(0, r)
        ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
        ..lineTo(c, 0),

      paint,
    );

    // =======================================================
    // TOP RIGHT
    // =======================================================

    canvas.drawPath(
      Path()
        ..moveTo(w - c, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
        ..lineTo(w, c),

      paint,
    );

    // =======================================================
    // BOTTOM RIGHT
    // =======================================================

    canvas.drawPath(
      Path()
        ..moveTo(w, h - c)
        ..lineTo(w, h - r)
        ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
        ..lineTo(w - c, h),

      paint,
    );

    // =======================================================
    // BOTTOM LEFT
    // =======================================================

    canvas.drawPath(
      Path()
        ..moveTo(c, h)
        ..lineTo(r, h)
        ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
        ..lineTo(0, h - c),

      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) {
    return false;
  }
}
