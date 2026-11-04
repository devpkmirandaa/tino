import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../application/shopping_controller.dart';
import '../data/nv21_crop.dart';
import '../domain/cart.dart';
import '../domain/money.dart';
import '../domain/tag_reader.dart';
import 'shopping_sheets.dart';

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
/// Moldura de leitura, em frações da imagem já em pé (retrato).
const _guide = Rect.fromLTRB(0.08, 0.32, 0.92, 0.62);

/// Intervalo mínimo entre análises; na prática, o limite é o tempo do OCR.
const _interval = Duration(milliseconds: 80);

/// Preço preferido em etiquetas com varejo e atacado.
enum PriceMode { retail, bulk }

/// Lembrado enquanto o app estiver aberto.
final priceModeProvider = NotifierProvider<PriceModeNotifier, PriceMode>(
  PriceModeNotifier.new,
);

class PriceModeNotifier extends Notifier<PriceMode> {
  @override
  PriceMode build() => PriceMode.retail;

  void set(PriceMode mode) => state = mode;
}

/// Câmera ao vivo + OCR local (ML Kit), só dentro da moldura. A permissão é
/// pedida ao abrir, no primeiro uso. Nenhuma imagem é gravada ou enviada.
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage>
    with WidgetsBindingObserver {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _stabilizer = ReadingConsensus();
  CameraController? _camera;
  String? _error;
  var _busy = false;
  var _lastFrame = DateTime(0);
  var _quantity = 1;
  String? _added;

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
      final watch = Stopwatch()..start();
      // Só a moldura vai para o OCR: menos pixels, mesma nitidez.
      final area = sensorRect(
        left: _guide.left,
        top: _guide.top,
        right: _guide.right,
        bottom: _guide.bottom,
        width: image.width,
        height: image.height,
        rotation: rotation.rawValue,
      );
      final crop = cropNv21(
        plane.bytes,
        width: image.width,
        height: image.height,
        stride: plane.bytesPerRow,
        x: area.x,
        y: area.y,
        w: area.w,
        h: area.h,
      );
      final text = await _recognizer.processImage(
        InputImage.fromBytes(
          bytes: crop?.bytes ?? plane.bytes,
          metadata: InputImageMetadata(
            size: Size(
              (crop?.width ?? image.width).toDouble(),
              (crop?.height ?? image.height).toDouble(),
            ),
            rotation: rotation,
            format: format!,
            bytesPerRow: crop?.width ?? plane.bytesPerRow,
          ),
        ),
      );
      _logTiming(watch.elapsedMilliseconds, cropped: crop != null);
      // Sem recorte, filtra pela moldura na imagem inteira.
      final turned =
          rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      final w = (turned ? image.height : image.width).toDouble();
      final h = (turned ? image.width : image.height).toDouble();
      final guide = crop != null
          ? Rect.largest
          : Rect.fromLTRB(
              _guide.left * w,
              _guide.top * h,
              _guide.right * w,
              _guide.bottom * h,
            );
      final lines = <OcrLine>[
        for (final block in text.blocks)
          for (final line in block.lines)
            if (guide.contains(line.boundingBox.center))
              (
                text: line.text,
                left: line.boundingBox.left,
                top: line.boundingBox.top,
                width: line.boundingBox.width,
                height: line.boundingBox.height,
              ),
      ];
      final reading = readTag(lines);

      if (_stabilizer.add(reading) && mounted) {
        // Diagnóstico local (logcat): o que o OCR leu dentro da moldura.
        debugPrint(
          "tino-ocr ${reading.price?.format()} bulk=${reading.bulkPrice?.format()} "
          "kg=${reading.perKg} | ${lines.map((l) => "${l.text}@${l.left.round()},${l.top.round()},h${l.height.round()}").join(" ; ")}",
        );
        setState(() => _quantity = _startQuantity(_stabilizer.stable!));
      }
    } on Exception catch (e) {
      debugPrint("tino-ocr erro: $e");
    } finally {
      _busy = false;
    }
  }

  var _timings = <int>[];

  /// Diagnóstico: média do tempo de OCR a cada 20 quadros (logcat).
  void _logTiming(int ms, {required bool cropped}) {
    _timings.add(ms);
    if (_timings.length < 20) return;
    final avg = _timings.reduce((a, b) => a + b) ~/ _timings.length;
    debugPrint("tino-ocr tempo médio ${avg}ms (recorte: $cropped)");
    _timings = [];
  }

  /// Por unidade e com nome lido: dá para adicionar sem sair da câmera.
  bool _direct(TagReading r) => !r.perKg && r.name != null;

  PriceMode get _mode => ref.read(priceModeProvider);

  int _startQuantity(TagReading r) =>
      _mode == PriceMode.bulk ? (r.bulkMin ?? 1) : 1;

  /// Atacado escolhido vale sempre; no varejo, o atacado só entra se a
  /// quantidade atingir o mínimo da etiqueta.
  Money _priceOf(TagReading r) => _mode == PriceMode.bulk && r.bulkPrice != null
      ? r.bulkPrice!
      : r.priceFor(_quantity)!;

  TagReading _chosen(TagReading r) =>
      TagReading(name: r.name, price: _priceOf(r), perKg: r.perKg);

  void _setMode(PriceMode mode) {
    ref.read(priceModeProvider.notifier).set(mode);
    final found = _stabilizer.stable;
    setState(() {
      if (found != null) _quantity = _startQuantity(found);
    });
  }

  void _add(TagReading r) {
    final controller = ref.read(shoppingProvider.notifier);
    final result = controller.add(
      UnitItem(
        id: controller.newId(),
        name: r.name!,
        price: _priceOf(r),
        quantity: _quantity,
      ),
    );
    if (result is PriceConflict) {
      // Mesmo produto com outro preço: o painel pergunta o que fazer.
      context.pop(ScanRead(_chosen(r)));
      return;
    }
    _stabilizer.accept();
    setState(() {
      _added =
          '${r.name} × $_quantity adicionado. '
          'Total ${result.cart.total.format()}. Aponte o próximo.';
      _quantity = 1;
    });
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
    final mode = ref.watch(priceModeProvider);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _ModeToggle(mode: mode, onChanged: _setMode),
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
                    _Suggestion(
                      found,
                      price: _priceOf(found),
                      mode: mode,
                      onMode: found.bulkPrice == null ? null : _setMode,
                      quantity: _quantity,
                      onQuantity: _direct(found)
                          ? (q) => setState(() => _quantity = q)
                          : null,
                    )
                  else if (_error == null)
                    Text(
                      _added ?? 'Procurando preço…',
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
                          onPressed: () => context.pop(
                            found == null
                                ? const ScanTypeInstead()
                                : ScanRead(_chosen(found)),
                          ),
                          child: Text(found == null ? 'Digitar' : 'Editar'),
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
                                onPressed: switch (found) {
                                  null => null,
                                  final f when _direct(f) => () => _add(f),
                                  final f => () => context.pop(
                                    ScanRead(_chosen(f)),
                                  ),
                                },
                                icon: const Icon(LucideIcons.plus, size: 20),
                                label: Text(switch (found) {
                                  TagReading(perKg: true) => 'Informar peso',
                                  TagReading(name: null) => 'Dar nome',
                                  _ => 'Adicionar',
                                }),
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

/// Filtro escolhido antes de escanear: qual preço usar em etiqueta dupla.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final PriceMode mode;
  final ValueChanged<PriceMode> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<PriceMode>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(value: PriceMode.retail, label: Text('Varejo')),
      ButtonSegment(value: PriceMode.bulk, label: Text('Atacado')),
    ],
    selected: {mode},
    onSelectionChanged: (s) => onChanged(s.single),
  );
}

class _Suggestion extends StatelessWidget {
  const _Suggestion(
    this.reading, {
    required this.price,
    required this.mode,
    required this.quantity,
    this.onMode,
    this.onQuantity,
  });
  final TagReading reading;
  final Money price;
  final PriceMode mode;
  final int quantity;
  final ValueChanged<PriceMode>? onMode;
  final ValueChanged<int>? onQuantity;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bulk = reading.bulkPrice;
    final min = reading.bulkMin;
    final bulkNote = switch ((bulk, min)) {
      (null, _) when mode == PriceMode.bulk =>
        'Atacado não encontrado nesta etiqueta.',
      (null, _) => null,
      (_, final m?) when mode == PriceMode.retail && quantity >= m =>
        'Atacado aplicado a partir de $m un.',
      (_, final m?) => 'Atacado a partir de $m un.',
      _ => null,
    };
    final card = Container(
      padding: const EdgeInsets.all(TinoSpace.s16),
      decoration: BoxDecoration(
        color: TinoTokens.surface,
        borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reading.perKg ? '${price.format()}/kg' : price.format(),
                  style: text.displaySmall,
                ),
                Text(
                  reading.name ?? 'Nome não lido.',
                  style: text.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (bulkNote != null) Text(bulkNote, style: text.labelLarge),
              ],
            ),
          ),
          if (onQuantity != null)
            QuantityStepper(value: quantity, onChanged: onQuantity!),
        ],
      ),
    );
    if (bulk == null || onMode == null) return card;
    // Etiqueta dupla: os dois preços lado a lado, um toque troca.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<PriceMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: PriceMode.retail,
              label: Text('Varejo ${reading.price!.format()}'),
            ),
            ButtonSegment(
              value: PriceMode.bulk,
              label: Text('Atacado ${bulk.format()}'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (s) => onMode!(s.single),
        ),
        const SizedBox(height: TinoSpace.s8),
        card,
      ],
    );
  }
}

/// Escurece fora da moldura e desenha o contorno onde o texto é lido.
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
      final radius = BorderRadius.circular(TinoRadius.cardCompact);
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
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: radius,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fromRect(
            rect: rect,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: TinoColors.lightJade, width: 2),
                borderRadius: radius,
              ),
            ),
          ),
        ],
      );
    },
  );
}
