import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../settings/data/lab_mode.dart';
import '../application/scan_reader.dart';
import '../application/shopping_controller.dart';
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

/// Tela do scanner. A leitura (câmera, OCR, votação) fica em [ScanReader];
/// aqui só a interface, a quantidade e a escolha de varejo ou atacado.
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  late final ScanReader _reader;
  var _quantity = 1;
  String? _added;

  @override
  void initState() {
    super.initState();
    _reader = ScanReader(
      labMode: ref.read(labModeProvider.future),
      onChanged: _onReading,
    )..addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  /// Leitura confirmada mudou; o rebuild vem logo depois, pelo ouvinte.
  void _onReading(TagReading? stable) {
    // Mínimo digitado vale só para a etiqueta em que foi digitado.
    if (stable?.price != _minFor) {
      _manualMin = null;
      _minFor = stable?.price;
    }
    if (stable != null) _quantity = _startQuantity(_withMin(stable));
  }

  /// Por unidade e com nome lido: dá para adicionar sem sair da câmera.
  bool _direct(TagReading r) => !r.perKg && r.name != null;

  PriceMode get _mode => ref.read(priceModeProvider);

  /// Mínimo do atacado não lido e digitado no cartão; nunca preenchido
  /// sozinho.
  int? _manualMin;
  Money? _minFor;

  TagReading _withMin(TagReading r) => r.bulkMin != null || _manualMin == null
      ? r
      : TagReading(
          name: r.name,
          price: r.price,
          perKg: r.perKg,
          bulkPrice: r.bulkPrice,
          bulkMin: _manualMin,
        );

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
    final found = _reader.stable;
    setState(() {
      if (found != null) _quantity = _startQuantity(_withMin(found));
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
    _reader.accept();
    setState(() {
      _added =
          '${r.name} × $_quantity adicionado. '
          'Total ${result.cart.total.format()}. Aponte o próximo.';
      _quantity = 1;
    });
  }

  @override
  void dispose() {
    _reader
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const light = TinoColors.offWhite;
    final camera = _reader.camera;
    final error = _reader.error;
    final read = _reader.stable;
    final found = read == null ? null : _withMin(read);
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
                    tooltip: _reader.torch
                        ? 'Desligar lanterna'
                        : 'Ligar lanterna',
                    onPressed: _reader.toggleTorch,
                    icon: Icon(
                      _reader.torch
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
                  child: switch ((camera, error)) {
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
                      // Atacado lido sem o mínimo: campo vazio para digitar.
                      onMin: read!.bulkPrice != null && read.bulkMin == null
                          ? (m) => setState(() {
                              _manualMin = m;
                              _minFor = read.price;
                              if (_mode == PriceMode.bulk && m != null) {
                                _quantity = m;
                              }
                            })
                          : null,
                    )
                  else if (error == null)
                    Text(
                      switch (_reader.provisional) {
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
                        child: error != null
                            ? FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: TinoColors.lightJade,
                                  foregroundColor: TinoColors.ink,
                                ),
                                onPressed: _reader.open,
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

/// "Atacado a partir de [__] un." com o número vazio até o usuário digitar.
class _MinField extends StatelessWidget {
  const _MinField({super.key, required this.applied, required this.onChanged});
  final bool applied;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Padding(
      padding: const EdgeInsets.only(top: TinoSpace.s4),
      child: Row(
        children: [
          Flexible(
            child: Text(
              applied ? 'Atacado aplicado a partir de' : 'Atacado a partir de',
              style: style,
            ),
          ),
          const SizedBox(width: TinoSpace.s8),
          SizedBox(
            width: 64,
            child: TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 3,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(counterText: '', hintText: '–'),
              onChanged: (v) {
                final n = int.tryParse(v);
                onChanged(n == null || n < 1 ? null : n);
              },
            ),
          ),
          const SizedBox(width: TinoSpace.s8),
          Text('un.', style: style),
        ],
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
    this.onMin,
  });
  final TagReading reading;
  final Money price;
  final PriceMode mode;
  final int quantity;
  final ValueChanged<PriceMode>? onMode;
  final ValueChanged<int>? onQuantity;

  /// Mínimo do atacado não lido: mostra campo vazio e editável.
  final ValueChanged<int?>? onMin;

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
                if (onMin != null)
                  _MinField(
                    key: ValueKey(reading.price),
                    applied:
                        mode == PriceMode.retail &&
                        min != null &&
                        quantity >= min,
                    onChanged: onMin!,
                  )
                else if (bulkNote != null)
                  Text(bulkNote, style: text.labelLarge),
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
        scanGuide.left * box.maxWidth,
        scanGuide.top * box.maxHeight,
        scanGuide.right * box.maxWidth,
        scanGuide.bottom * box.maxHeight,
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
