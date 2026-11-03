import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../domain/tag_reader.dart';

/// Resultado do scanner: leitura confirmada ou pedido para digitar.
sealed class ScanResult {
  const ScanResult();
}

final class ScanRead extends ScanResult {
  const ScanRead(this.reading);
  final TagReading reading;
}

final class ScanTypeInstead extends ScanResult {
  const ScanTypeInstead();
}

/// Moldura de leitura, em frações da imagem já em pé (retrato).
const _guide = Rect.fromLTRB(0.08, 0.32, 0.92, 0.62);
const _interval = Duration(milliseconds: 250);

/// Câmera ao vivo + OCR local (ML Kit), só dentro da moldura. A permissão é
/// pedida ao abrir, no primeiro uso. Nenhuma imagem é gravada ou enviada.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _stabilizer = ReadingStabilizer();
  CameraController? _camera;
  String? _error;
  var _busy = false;
  var _lastFrame = DateTime(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final camera = _camera;
      _camera = null;
      camera?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      _open();
    }
  }

  Future<void> _open() async {
    setState(() => _error = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('none', null);
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final camera = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await camera.initialize();
      if (!mounted) {
        await camera.dispose();
        return;
      }
      await camera.startImageStream(
        (image) => _onFrame(image, back.sensorOrientation),
      );
      setState(() => _camera = camera);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.code.contains('AccessDenied')
            ? 'Sem acesso à câmera. Permita o uso da câmera para o Tino nas '
                  'configurações do Android.'
            : 'Não deu pra abrir a câmera.',
      );
    }
  }

  Future<void> _onFrame(CameraImage image, int sensorOrientation) async {
    final now = DateTime.now();
    if (_busy || now.difference(_lastFrame) < _interval) return;
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null ||
        format != InputImageFormat.nv21 ||
        image.planes.length != 1) {
      return;
    }
    _busy = true;
    _lastFrame = now;
    try {
      final plane = image.planes.single;
      final text = await _recognizer.processImage(
        InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format!,
            bytesPerRow: plane.bytesPerRow,
          ),
        ),
      );
      final turned =
          rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      final w = (turned ? image.height : image.width).toDouble();
      final h = (turned ? image.width : image.height).toDouble();
      final guide = Rect.fromLTRB(
        _guide.left * w,
        _guide.top * h,
        _guide.right * w,
        _guide.bottom * h,
      );
      final reading = readTag([
        for (final block in text.blocks)
          for (final line in block.lines)
            if (guide.contains(line.boundingBox.center))
              (
                text: line.text,
                top: line.boundingBox.top,
                height: line.boundingBox.height,
              ),
      ]);
      if (_stabilizer.add(reading) && mounted) setState(() {});
    } on Exception {
      // Quadro perdido: o próximo é analisado normalmente.
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const light = TinoColors.offWhite;
    final camera = _camera;
    final found = _stabilizer.stable;
    return Scaffold(
      backgroundColor: TinoColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.x, color: light),
                ),
                Expanded(
                  child: Text(
                    'Enquadre o preço e o nome do produto.',
                    style: text.bodyLarge?.copyWith(color: light),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: switch ((camera, _error)) {
                    (_, final error?) => Text(
                      error,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(color: light),
                    ),
                    (final c?, _) when c.value.isInitialized => ClipRRect(
                      borderRadius: BorderRadius.circular(TinoRadius.card),
                      child: CameraPreview(c, child: const _GuideOverlay()),
                    ),
                    _ => const CircularProgressIndicator(color: light),
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TinoSpace.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (found != null)
                    _Suggestion(found)
                  else if (_error == null)
                    Text(
                      'Procurando preço…',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: light),
                    ),
                  const SizedBox(height: TinoSpace.s12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: light,
                            side: const BorderSide(color: light),
                          ),
                          onPressed: () => context.pop(const ScanTypeInstead()),
                          child: const Text('Digitar'),
                        ),
                      ),
                      const SizedBox(width: TinoSpace.s12),
                      Expanded(
                        child: _error != null
                            ? FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: TinoColors.lightJade,
                                  foregroundColor: TinoColors.ink,
                                ),
                                onPressed: _open,
                                child: const Text('Tentar de novo'),
                              )
                            : FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: TinoColors.lightJade,
                                  foregroundColor: TinoColors.ink,
                                ),
                                onPressed: found == null
                                    ? null
                                    : () => context.pop(ScanRead(found)),
                                icon: const Icon(LucideIcons.check, size: 20),
                                label: const Text('Usar'),
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
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion(this.reading);
  final TagReading reading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final price = reading.price!.format();
    return Container(
      padding: const EdgeInsets.all(TinoSpace.s16),
      decoration: BoxDecoration(
        color: TinoTokens.surface,
        borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reading.perKg ? '$price/kg' : price, style: text.displaySmall),
          Text(
            reading.name ?? 'Nome não lido; dá pra digitar depois.',
            style: text.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Escurece fora da moldura e desenha o contorno onde o texto é lido.
class _GuideOverlay extends StatelessWidget {
  const _GuideOverlay();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final rect = Rect.fromLTRB(
        _guide.left * box.maxWidth,
        _guide.top * box.maxHeight,
        _guide.right * box.maxWidth,
        _guide.bottom * box.maxHeight,
      );
      return Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                TinoColors.ink.withValues(alpha: 0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Colors.transparent),
                  ),
                  Positioned.fromRect(
                    rect: rect,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(
                          TinoRadius.cardCompact,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fromRect(
            rect: rect,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: TinoColors.lightJade, width: 2),
                borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
              ),
            ),
          ),
        ],
      );
    },
  );
}
