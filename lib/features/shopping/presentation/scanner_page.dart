import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/theme/tino_theme.dart';
import '../../settings/data/lab_mode.dart';
import '../application/shopping_controller.dart';
import '../data/nv21_crop.dart';
import '../domain/cart.dart';
import '../domain/lab_answer.dart';
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

/// Giro acima disso (rad/s) é celular em movimento: quadro descartado.
const _maxTurn = 0.8;

/// Sem quadro aprovado por este tempo, o mais nítido recusado vai pro OCR.
const _maxWait = Duration(milliseconds: 300);

typedef _Crop = ({Uint8List bytes, int width, int height});

/// Quadro com nitidez abaixo desta fração da melhor recente é descartado.
const _minSharpness = 0.4;

/// Contagem por etiqueta, do primeiro preço visto até travar (logcat).
class _Stats {
  var ocr = 0;
  var blurred = 0;
  var moving = 0;
  var fallback = 0;
  var voted = 0;
  var cropMs = 0;
  var sharpMs = 0;
  var ocrMs = 0;
  var parseMs = 0;
  final prices = <Money, int>{};
  var maxDiff = 0.0;

  String avg(int total) => ocr == 0 ? '-' : '${total ~/ ocr}';

  /// Preços concorrentes, do mais votado: "19,11×4, 18,11×1".
  String tally() {
    final list = prices.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list
        .map((e) => '${e.key.format().replaceFirst(r'R$ ', '')}×${e.value}')
        .join(', ');
  }
}

/// Travamento aguardando a etiqueta sair para ser comparado com o gabarito
/// (atacado e mínimo podem chegar depois do preço).
typedef _LabPending = ({
  LabAnswer? answer,
  String note,
  int ms,
  int frames,
  String rule,
  String tally,
});

/// Quadros seguidos sem preço que encerram a tentativa (etiqueta saiu).
const _goneAfter = 8;

/// Diferença média entre miniaturas (0 a 255) que indica mudança brusca.
const _cutDiff = 18.0;

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
  var _torch = false;
  DateTime? _firstSeen;
  String? _added;
  StreamSubscription<GyroscopeEvent>? _gyro;
  var _turn = 0.0;
  var _bestSharpness = 0.0;
  var _lastApproved = DateTime.now();
  _Crop? _spare;
  var _spareSharpness = -1.0;
  var _stats = _Stats();
  var _missRun = 0;

  // Troca de etiqueta: miniatura do quadro anterior e dados desde o corte.
  Uint8List? _lastThumb;
  DateTime? _cutAt;
  _Stats? _cutStats;
  var _cutQr = <String>{};
  var _qrSinceStart = <String>{};

  // Modo laboratório: QR de gabarito lido em paralelo ao OCR.
  BarcodeScanner? _barcodes;
  LabReport? _lab;
  LabAnswer? _answer;
  _LabPending? _pending;
  TagReading? _labLast;
  Money? _shownProvisional;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Giro do aparelho, com decaimento: um tranco segura por ~100 ms.
    _gyro = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen(
          (e) => _turn = math.max(
            math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z),
            _turn * 0.7,
          ),
          onError: (_) => _turn = 0,
          cancelOnError: true,
        );
    ref.read(labModeProvider.future).then((on) {
      if (!on || !mounted) return;
      debugPrint('tino-lab modo laboratório ligado');
      _lab = LabReport();
      _barcodes = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    }, onError: (_) {});
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

  var _qrFrames = 0;
  var _qrFound = 0;
  final _unknownQr = <String>{};

  void _onQr(List<Barcode> codes) {
    _qrFrames++;
    for (final code in codes) {
      _qrFound++;
      final raw = code.rawValue ?? code.displayValue ?? '';
      final answer = LabAnswer.parse(raw);
      if (answer == null) {
        // Diagnóstico: QR lido que não está no formato do gabarito.
        if (_unknownQr.add(raw)) debugPrint('tino-lab QR desconhecido: "$raw"');
        continue;
      }
      if (answer.id != _answer?.id) {
        debugPrint('tino-lab QR id=${answer.id} c=${answer.scenario}');
      }
      _answer = answer;
      _qrSinceStart.add(answer.id);
      _cutQr.add(answer.id);
      _lab?.saw(answer);
    }
  }

  /// Compara o último travamento com o gabarito, quando a etiqueta sai.
  void _labFinish() {
    final p = _pending;
    final last = _labLast;
    _pending = null;
    _labLast = null;
    if (p == null || last == null) return;
    final a = p.answer;
    final tail =
        '| ${p.ms}ms quadros=${p.frames} regra=${p.rule} '
        'preços ${p.tally}';
    if (a == null) {
      debugPrint('tino-lab ${p.note}: lido ${last.price?.format()} $tail');
      return;
    }
    String field(bool ok, Object? read, Object? want) =>
        ok ? 'ok' : 'ERRO(lido $read, certo $want)';
    final c = a.check(last);
    final ok = _lab!.lock(a, last, p.ms);
    debugPrint(
      'tino-lab id=${a.id} c=${a.scenario} ${ok ? 'ACERTOU' : 'ERROU'} '
      'preço=${field(c.price, last.price?.format(), a.price.format())} '
      'atacado=${field(c.bulk, last.bulkPrice?.format(), a.bulkPrice?.format())} '
      'mínimo=${field(c.min, last.bulkMin, a.bulkMin)} '
      'kg=${field(c.kg, last.perKg, a.perKg)} $tail',
    );
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
      // Foco e exposição ficam no automático contínuo: definir um ponto
      // trava o foco naquela distância e desfoca ao mover o celular.
      if (!mounted) {
        await camera.dispose();
        return;
      }
      await camera.startImageStream(
        (image) => _onFrame(image, back.sensorOrientation),
      );
      setState(() {
        _camera = camera;
        _torch = false;
      });
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
      final stats = _stats;
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
      var crop = cropNv21(
        plane.bytes,
        width: image.width,
        height: image.height,
        stride: plane.bytesPerRow,
        x: area.x,
        y: area.y,
        w: area.w,
        h: area.h,
      );
      final cropMs = watch.elapsedMilliseconds;
      // Nitidez relativa à melhor recente: se adapta à luz e à etiqueta.
      final sharp = crop == null
          ? 0.0
          : sharpness(crop.bytes, crop.width, crop.height, step: 3);
      final sharpMs = watch.elapsedMilliseconds - cropMs;
      _bestSharpness = math.max(sharp, _bestSharpness * 0.95);
      final moving = _turn > _maxTurn;
      if (moving || crop != null && sharp < _bestSharpness * _minSharpness) {
        moving ? stats.moving++ : stats.blurred++;
        if (crop == null) return;
        if (sharp > _spareSharpness) {
          _spare = crop;
          _spareSharpness = sharp;
        }
        if (now.difference(_lastApproved) < _maxWait) return;
        // Nunca fica sem leitura: vai o mais nítido dos recusados.
        debugPrint(
          "tino-ocr saída ${_maxWait.inMilliseconds}ms: quadro recusado "
          "nitidez ${_spareSharpness.round()} melhor ${_bestSharpness.round()} "
          "giro ${_turn.toStringAsFixed(2)}",
        );
        stats.fallback++;
        crop = _spare;
      }
      _lastApproved = now;
      _spare = null;
      _spareSharpness = -1;
      // Quadro inteiro: o QR pode estar fora da moldura.
      final qr = _barcodes?.processImage(
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
      final ocrMs = watch.elapsedMilliseconds - cropMs - sharpMs;
      if (qr != null) _onQr(await qr);
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
                glyphs: [
                  for (final element in line.elements)
                    for (final symbol in element.symbols)
                      (
                        top: symbol.boundingBox.top,
                        bottom: symbol.boundingBox.bottom,
                      ),
                ],
              ),
      ];
      final reading = readTag(lines);
      final parseMs = watch.elapsedMilliseconds - cropMs - sharpMs - ocrMs;

      // Mudança brusca na imagem: miniatura muito diferente da anterior.
      var diff = 0.0;
      if (crop != null) {
        final thumb = thumbnail(crop.bytes, crop.width, crop.height);
        final last = _lastThumb;
        if (last != null) diff = thumbnailDiff(thumb, last);
        _lastThumb = thumb;
      }

      if (reading.price != null && _firstSeen == null) {
        // Nova tentativa: conta a partir do primeiro preço visto.
        _firstSeen = now;
        _stats = _Stats();
        _qrSinceStart = {if (_answer case final a?) a.id};
      }
      final before = _stabilizer.stable?.price;
      final changed = _stabilizer.add(reading, cut: diff >= _cutDiff);
      if (_stabilizer.cutSeen) {
        _cutAt = now;
        _cutStats = _Stats();
        _cutQr = {};
      }
      if (_stabilizer.switched) {
        // Troca de etiqueta confirmada: o relógio conta desde o corte.
        debugPrint(
          'tino-ocr troca de etiqueta: ${before?.format()} → '
          '${reading.price?.format()} (diferença ${diff.toStringAsFixed(0)})',
        );
        _firstSeen = _cutAt ?? now;
        _stats = _cutStats ?? _Stats();
        _qrSinceStart = _cutQr;
      }
      if (reading.price == null &&
          ++_missRun >= _goneAfter &&
          _stabilizer.stable == null) {
        // Etiqueta saiu sem travar: a próxima tentativa recomeça o relógio.
        _firstSeen = null;
      }
      for (final s in [_stats, ?_cutStats]) {
        if (reading.price case final p?) s.prices[p] = (s.prices[p] ?? 0) + 1;
        s
          ..ocr += 1
          ..voted += reading.price == null ? 0 : 1
          ..cropMs += cropMs
          ..sharpMs += sharpMs
          ..ocrMs += ocrMs
          ..parseMs += parseMs
          ..maxDiff = math.max(s.maxDiff, diff);
      }
      if (reading.price != null) _missRun = 0;
      if (reading.price == null &&
          lines.any((l) => RegExp(r'\d{2}').hasMatch(l.text))) {
        // Diagnóstico: números lidos que não viraram preço.
        debugPrint(
          "tino-ocr sem preço | ${lines.map((l) => "${l.text}@${l.left.round()},${l.top.round()},h${l.height.round()}${RegExp(r'\d{3}').hasMatch(l.text) ? " g${l.glyphs.map((g) => "${g.top.round()}-${g.bottom.round()}").join("/")}" : ""}").join(" ; ")}",
        );
      }
      final provisional = _stabilizer.provisional?.price;
      if (!changed && provisional != _shownProvisional && mounted) {
        setState(() => _shownProvisional = provisional);
      }
      if (changed && mounted) {
        _shownProvisional = null;
        final first = _firstSeen;
        // Só travamento novo; nome ou atacado chegando depois não conta.
        if (_stabilizer.stable != null &&
            _stabilizer.stable!.price != before &&
            first != null) {
          final s = _stats;
          final ms = DateTime.now().difference(first).inMilliseconds;
          if (_lab != null) {
            _labFinish();
            // Só compara se um único QR foi lido durante esta tentativa.
            final ids = _qrSinceStart;
            final a = _answer;
            _pending = (
              answer: ids.length == 1 && a != null && ids.single == a.id
                  ? a
                  : null,
              note: ids.length > 1
                  ? 'QR misturado (${ids.join(", ")})'
                  : 'sem QR',
              ms: ms,
              frames: s.ocr,
              rule: '${_stabilizer.rule?.name}',
              tally: s.tally(),
            );
          }
          debugPrint(
            "tino-ocr travou em ${ms}ms "
            "regra=${_stabilizer.rule?.name} | preços ${s.tally()} | quadros ocr=${s.ocr} "
            "votos=${s.voted} descartados borrado=${s.blurred} "
            "movimento=${s.moving} saída300=${s.fallback} | média ms recorte=${s.avg(s.cropMs)} "
            "nitidez=${s.avg(s.sharpMs)} ocr=${s.avg(s.ocrMs)} "
            "leitura=${s.avg(s.parseMs)} | nitidez ${sharp.round()} "
            "melhor ${_bestSharpness.round()} | maior diferença ${s.maxDiff.toStringAsFixed(0)}",
          );
          _firstSeen = null;
        }
        // Diagnóstico local (logcat): o que o OCR leu dentro da moldura.
        debugPrint(
          "tino-ocr ${reading.price?.format()} bulk=${reading.bulkPrice?.format()} "
          "kg=${reading.perKg} | ${lines.map((l) => "${l.text}@${l.left.round()},${l.top.round()},h${l.height.round()}").join(" ; ")}",
        );
        final stable = _stabilizer.stable;
        if (stable == null) {
          _labFinish();
        } else {
          _labLast = stable;
        }
        setState(() {
          if (stable != null) _quantity = _startQuantity(stable);
        });
      }
    } on Exception catch (e) {
      debugPrint("tino-ocr erro: $e");
    } finally {
      _busy = false;
    }
  }

  /// Por unidade e com nome lido: dá para adicionar sem sair da câmera.
  bool _direct(TagReading r) => !r.perKg && r.name != null;

  Future<void> _toggleTorch() async {
    final camera = _camera;
    if (camera == null) return;
    try {
      await camera.setFlashMode(_torch ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _torch = !_torch);
    } on CameraException {
      // Sem lanterna neste aparelho.
    }
  }

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
    _labFinish();
    _stabilizer.accept();
    _firstSeen = null;
    setState(() {
      _added =
          '${r.name} × $_quantity adicionado. '
          'Total ${result.cart.total.format()}. Aponte o próximo.';
      _quantity = 1;
    });
  }

  @override
  void dispose() {
    _labFinish();
    final lab = _lab;
    if (lab != null) {
      debugPrint(
        'tino-lab leitor de QR: $_qrFrames quadros, $_qrFound códigos achados',
      );
      for (final line in lab.isEmpty ? <String>[] : lab.summary()) {
        debugPrint('tino-lab resumo $line');
      }
    }
    _barcodes?.close();
    WidgetsBinding.instance.removeObserver(this);
    _gyro?.cancel();
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
                if (camera != null)
                  IconButton(
                    tooltip: _torch ? 'Desligar lanterna' : 'Ligar lanterna',
                    onPressed: _toggleTorch,
                    icon: Icon(
                      _torch
                          ? LucideIcons.flashlightOff
                          : LucideIcons.flashlight,
                      color: light,
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
                      switch (_shownProvisional) {
                        final p? => '${p.format()} · confirmando…',
                        null => _added ?? 'Procurando preço…',
                      },
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
