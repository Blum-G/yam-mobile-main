import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';

/// Écran de scan de la carte QR patient.
///
/// Renvoie le contenu brut lu dans la carte via `Navigator.pop(context, valeur)`.
class CardScannerScreen extends StatefulWidget {
  const CardScannerScreen({super.key});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _returning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_returning) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;
      _returning = true;
      await _controller.stop();
      if (!mounted) return;
      Navigator.pop(context, value);
      return;
    }
  }

  void _showScanError(MobileScannerException error) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        "L'accès à la caméra a été refusé. Autorisez-le dans les paramètres du téléphone puis réessayez.",
      MobileScannerErrorCode.unsupported =>
        "Cet appareil ne dispose pas de caméra utilisable.",
      _ => 'Impossible de démarrer la caméra (${error.errorDetails?.message ?? error.errorCode.name}).',
    };

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: YamColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: kCardRadius),
        title: const Text(
          'Caméra indisponible',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: YamColors.text),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: YamColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scanner la carte',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Lampe',
            onPressed: _controller.toggleTorch,
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Changer de caméra',
            onPressed: _controller.switchCamera,
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              // Le widget n'est jamais monté si une erreur survient avant le
              // premier frame : on affiche un écran vide plutôt que de crasher.
              return ColoredBox(
                color: Colors.black,
                child: Center(
                  child: TextButton(
                    onPressed: () => _showScanError(error),
                    child: const Text(
                      'Caméra indisponible — voir le détail',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: Center(child: _ScanFrameOverlay()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Text(
              'Alignez le QR code de la carte dans le cadre',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cadre de visée vert, purement décoratif.
class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(color: YamColors.primary, width: 3),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
