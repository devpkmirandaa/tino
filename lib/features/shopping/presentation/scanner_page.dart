import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/tino_haptics.dart';
import '../../../core/motion/tino_springs.dart';
import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../../settings/data/lab_mode.dart';
import '../application/scan_reader.dart';
import '../application/shopping_controller.dart';
import '../domain/cart.dart';
import '../domain/money.dart';
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

/// Último item que entrou pelo scanner, mostrado na folha.
typedef _Added = ({String name, Money price, int quantity});

/// Tema da folha, criado uma vez: a tela reconstrói a cada leitura.
final _sheetTheme = buildTinoTheme(Brightness.light);

/// M3b: a folha troca de conteúdo 80 ms depois do travamento.
const _swapDelay = Duration(milliseconds: 80);

/// Tela do scanner (design/specs/telas.md · 03), sempre escura. A leitura
/// (câmera, OCR, votação) fica em [ScanReader]; aqui só a interface, a
/// quantidade e a escolha de varejo ou atacado.
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage>
    with TickerProviderStateMixin {
  late final ScanReader _reader;
  var _quantity = 1;
  _Added? _added;
  var _adds = 0;

  /// Travamentos de preço novos; cada um dispara o M3a no visor.
  var _locks = 0;
  Money? _lockedPrice;

  // M2: controles do topo descem de −16 e aparecem, 140 ms depois de abrir.
  late final _topY = AnimationController.unbounded(vsync: this);
  late final _topFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Timer? _topTimer;
  var _entered = false;

  @override
  void initState() {
    super.initState();
    _reader = ScanReader(
      labMode: ref.read(labModeProvider.future),
      onChanged: _onReading,
    )..addListener(_rebuild);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entered) return;
    _entered = true;
    if (TinoMotion.reduced(context)) {
      _topFade.value = 1;
      return;
    }
    _topY.value = -16;
    _topTimer = Timer(const Duration(milliseconds: 140), () {
      _topFade.forward();
      _topY.animateWith(TinoMotion.spring(TinoSprings.cartao, -16, 0));
    });
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
    final price = stable?.price;
    if (price != null && price != _lockedPrice) {
      _locks++;
      TinoHaptics.light();
    }
    _lockedPrice = price;
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
    final price = _priceOf(r);
    final result = controller.add(
      UnitItem(
        id: controller.newId(),
        name: r.name!,
        price: price,
        quantity: _quantity,
      ),
    );
    if (result is PriceConflict) {
      // Mesmo produto com outro preço: o painel pergunta o que fazer.
      context.pop(ScanRead(_chosen(r)));
      return;
    }
    _reader.accept();
    TinoHaptics.success();
    setState(() {
      _added = (name: r.name!, price: price * _quantity, quantity: _quantity);
      _adds++;
      _lockedPrice = null;
      _quantity = 1;
    });
  }

  @override
  void dispose() {
    _topTimer?.cancel();
    _topY.dispose();
    _topFade.dispose();
    _reader
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final read = _reader.stable;
    final found = read == null ? null : _withMin(read);
    final cart = ref.watch(shoppingProvider).value?.cart;
    return Scaffold(
      backgroundColor: c.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: _CameraLayer(
              camera: _reader.camera,
              locks: _locks,
              locked: found != null,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedBuilder(
                animation: Listenable.merge([_topY, _topFade]),
                builder: (context, child) => Opacity(
                  opacity: TinoCurves.easeOut.transform(_topFade.value),
                  child: Transform.translate(
                    offset: Offset(0, _topY.value),
                    child: child,
                  ),
                ),
                child: _TopBar(
                  count: cart?.items.length ?? 0,
                  total: cart?.total ?? Money.zero,
                  torch: _reader.camera == null ? null : _reader.torch,
                  onTorch: _reader.toggleTorch,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Theme(
              // A folha é clara sobre o scanner escuro (03-scanner.html).
              data: _sheetTheme,
              child: _sheet(read, found),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheet(TagReading? read, TagReading? found) {
    final mode = ref.watch(priceModeProvider);
    final error = _reader.error;
    final bulk = found?.bulkPrice;
    final (Key key, Widget item) = switch (found) {
      _ when error != null => (
        const ValueKey('error'),
        _Message(title: error, detail: 'Quer digitar o preço?'),
      ),
      final f? => (
        ValueKey('found-${f.price?.cents}'),
        _ReadItem(
          name: f.name ?? 'Nome não lido.',
          detail: _detail(f, mode),
          price: f.perKg ? '${_priceOf(f).format()}/kg' : _priceOf(f).format(),
        ),
      ),
      null when _added != null => (
        ValueKey('added-$_adds'),
        _ReadItem(
          added: true,
          name: _added!.name,
          detail: _added!.quantity == 1 ? null : '× ${_added!.quantity}',
          price: _added!.price.format(),
        ),
      ),
      null => (
        const ValueKey('search'),
        _Message(
          title: switch ((_reader.camera, _reader.provisional)) {
            (null, _) => 'Abrindo a câmera…',
            (_, final p?) => '${p.format()} · confirmando…',
            _ => 'Procurando preço…',
          },
          detail: 'Enquadre o preço e o nome do produto.',
        ),
      ),
    };

    final actions = switch (found) {
      _ when error != null => Row(
        children: [
          Expanded(
            child: TinoButton.outlined(
              label: 'Digitar',
              icon: LucideIcons.keyboard,
              expand: true,
              onPressed: () => context.pop(const ScanTypeInstead()),
            ),
          ),
          const SizedBox(width: TinoSpace.s8),
          Expanded(
            child: TinoButton.primary(
              label: 'Tentar de novo',
              expand: true,
              onPressed: _reader.open,
            ),
          ),
        ],
      ),
      final f? => Row(
        children: [
          if (_direct(f)) ...[
            TinoQuantityStepper(
              value: _quantity,
              onChanged: (q) => setState(() => _quantity = q),
            ),
            const SizedBox(width: TinoSpace.s8),
          ],
          Expanded(
            child: TinoButton.primary(
              label: switch (f) {
                TagReading(perKg: true) => 'Informar peso',
                TagReading(name: null) => 'Dar nome',
                _ => 'Adicionar',
              },
              icon: LucideIcons.plus,
              expand: true,
              onPressed: _direct(f)
                  ? () => _add(f)
                  : () => context.pop(ScanRead(_chosen(f))),
            ),
          ),
          const SizedBox(width: TinoSpace.s8),
          _OutlinedIconButton(
            icon: LucideIcons.pencil,
            semanticLabel: 'Corrigir',
            onPressed: () => context.pop(ScanRead(_chosen(f))),
          ),
        ],
      ),
      null => Row(
        children: [
          Expanded(
            child: TinoSegmented<PriceMode>(
              segments: const [
                (value: PriceMode.retail, label: 'Varejo'),
                (value: PriceMode.bulk, label: 'Atacado'),
              ],
              selected: mode,
              onChanged: _setMode,
            ),
          ),
          const SizedBox(width: TinoSpace.s8),
          TinoButton.outlined(
            label: 'Digitar',
            icon: LucideIcons.keyboard,
            onPressed: () => context.pop(const ScanTypeInstead()),
          ),
        ],
      ),
    };

    return _SheetFrame(
      children: [
        // Etiqueta dupla: os dois preços lado a lado, um toque troca.
        if (found != null && bulk != null)
          TinoSegmented<PriceMode>(
            segments: [
              (
                value: PriceMode.retail,
                label: 'Varejo ${found.price!.format()}',
              ),
              (value: PriceMode.bulk, label: 'Atacado ${bulk.format()}'),
            ],
            selected: mode,
            onChanged: _setMode,
          ),
        _Swap(id: key, child: item),
        // Atacado lido sem o mínimo: campo vazio para digitar.
        if (found != null && read!.bulkPrice != null && read.bulkMin == null)
          _MinField(
            key: ValueKey(read.price),
            applied:
                mode == PriceMode.retail &&
                found.bulkMin != null &&
                _quantity >= found.bulkMin!,
            onChanged: (m) => setState(() {
              _manualMin = m;
              _minFor = read.price;
              if (_mode == PriceMode.bulk && m != null) _quantity = m;
            }),
          ),
        actions,
        if (found == null && _added != null && error == null)
          Text(
            'Já pode apontar para a próxima etiqueta.',
            textAlign: TextAlign.center,
            style: TinoType.caption.withColor(context.tino.textSecondary),
          ),
      ],
    );
  }

  /// Linha de apoio do item lido: por kg ou o aviso do atacado.
  String? _detail(TagReading r, PriceMode mode) {
    if (r.perKg) return 'Preço por kg';
    final min = r.bulkMin;
    return switch ((r.bulkPrice, min)) {
      (null, _) when mode == PriceMode.bulk =>
        'Atacado não encontrado nesta etiqueta.',
      (null, _) => null,
      (_, final m?) when mode == PriceMode.retail && _quantity >= m =>
        'Atacado aplicado a partir de $m un.',
      (_, final m?) => 'Atacado a partir de $m un.',
      _ => null,
    };
  }
}

/// Topo: fechar · pílula "N itens" + total (M4) · lanterna.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.count,
    required this.total,
    required this.torch,
    required this.onTorch,
  });
  final int count;
  final Money total;

  /// Nulo enquanto a câmera não abriu.
  final bool? torch;
  final VoidCallback onTorch;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TinoSpace.s16,
        TinoSpace.s8,
        TinoSpace.s16,
        0,
      ),
      child: Row(
        children: [
          _RoundButton(
            icon: LucideIcons.x,
            semanticLabel: 'Fechar scanner',
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: TinoSpace.s16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(TinoRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      count == 1 ? '1 item' : '$count itens',
                      style: TinoType.secundario.withColor(c.textSecondary),
                    ),
                    const SizedBox(width: TinoSpace.s8),
                    TinoMoneyCounter(
                      cents: total.cents,
                      format: (v) => Money(v).format(),
                      style: TinoType.corpo.withColor(c.textPrimary).money,
                      accent: c.action,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _RoundButton(
            icon: LucideIcons.zap,
            semanticLabel: torch == true ? 'Desligar lanterna' : 'Lanterna',
            active: torch == true,
            onPressed: torch == null ? null : onTorch,
          ),
        ],
      ),
    );
  }
}

/// Botão só ícone em círculo `surface`, 48 × 48. Ativo muda só a cor.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.active = false,
  });
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return TinoPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      selected: active,
      excludeSemantics: true,
      builder: (context, _) => Container(
        width: TinoSize.touchTarget,
        height: TinoSize.touchTarget,
        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
        child: Icon(
          icon,
          size: TinoSize.icon,
          color: onPressed == null
              ? c.textSecondary
              : active
              ? c.action
              : c.textPrimary,
        ),
      ),
    );
  }
}

/// Botão contornado só ícone, 48 × 48 (lápis "Corrigir").
class _OutlinedIconButton extends StatelessWidget {
  const _OutlinedIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return TinoPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, _) => Container(
        width: TinoSize.touchTarget,
        height: TinoSize.touchTarget,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TinoRadius.control),
          border: Border.all(
            color: c.borderStrong,
            width: TinoSize.borderWidth,
          ),
        ),
        child: Icon(icon, size: TinoSize.iconCompact, color: c.textPrimary),
      ),
    );
  }
}

/// Folha inferior fixa: raio superior 24, fundo `surface`, blocos a 16.
/// A altura acompanha o conteúdo com a mola `cartao`.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.children});
  final List<Widget> children;

  static const _sizeDuration = Duration(milliseconds: 600);
  static final _sizeCurve = TinoSpringCurve(TinoSprings.cartao, _sizeDuration);

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TinoRadius.panel),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TinoSpace.s16,
            TinoSpace.s24,
            TinoSpace.s16,
            TinoSpace.s24,
          ),
          child: AnimatedSize(
            duration: _sizeDuration,
            curve: _sizeCurve,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) const SizedBox(height: TinoSpace.s16),
                  child,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// M3b · troca de conteúdo da folha. O anterior sai subindo (y 0 → −24) e
/// some em 180 ms; o novo entra pelos blocos [_Rise] dele. A troca acontece
/// quando [id] muda.
class _Swap extends StatelessWidget {
  const _Swap({required this.id, required this.child});
  final Key id;
  final Widget child;

  static const _out = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final reduced = TinoMotion.reduced(context);
    return AnimatedSwitcher(
      duration: _out,
      reverseDuration: reduced ? TinoMotion.reducedFade : _out,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [
          for (final p in previous)
            Positioned(left: 0, right: 0, top: 0, child: p),
          ?current,
        ],
      ),
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          // Quem entra aparece pelos próprios blocos; aqui só a saída.
          if (animation.status != AnimationStatus.reverse) return child!;
          final t = TinoCurves.easeOut.transform(1 - animation.value);
          return IgnorePointer(
            child: Opacity(
              opacity: 1 - t,
              child: Transform.translate(
                offset: Offset(0, reduced ? 0 : -24 * t),
                child: child,
              ),
            ),
          );
        },
      ),
      child: KeyedSubtree(key: id, child: child),
    );
  }
}

/// Entrada de um bloco no M3b: y 32 → 0 com a mola `confirmacao` e
/// opacidade 0 → 1 em 200 ms, depois de [_swapDelay] + [delay]. Movimento
/// reduzido: só opacidade, 150 ms.
class _Rise extends StatefulWidget {
  const _Rise({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<_Rise> createState() => _RiseState();
}

class _RiseState extends State<_Rise> with TickerProviderStateMixin {
  late final _y = AnimationController.unbounded(vsync: this, value: 32);
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Timer? _timer;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = TinoMotion.reduced(context);
    if (reduced) {
      _y.value = 0;
      _fade.duration = TinoMotion.reducedFade;
    }
    _timer = Timer(_swapDelay + widget.delay, () {
      _fade.forward();
      if (!reduced) {
        _y.animateWith(TinoMotion.spring(TinoSprings.confirmacao, 32, 0));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _y.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_y, _fade]),
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: TinoCurves.easeOut.transform(_fade.value),
      child: Transform.translate(offset: Offset(0, _y.value), child: child),
    ),
  );
}

/// Ícone de check do "Adicionado ao carrinho": escala 0,3 → 1 com a mola
/// `confirmacao`.
class _CheckPop extends StatefulWidget {
  const _CheckPop({required this.color});
  final Color color;

  @override
  State<_CheckPop> createState() => _CheckPopState();
}

class _CheckPopState extends State<_CheckPop>
    with SingleTickerProviderStateMixin {
  late final _scale = AnimationController.unbounded(vsync: this, value: 0.3);
  Timer? _timer;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (TinoMotion.reduced(context)) {
      _scale.value = 1;
      return;
    }
    _timer = Timer(_swapDelay, () {
      _scale.animateWith(TinoMotion.spring(TinoSprings.confirmacao, 0.3, 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Icon(LucideIcons.circleCheck, size: 16, color: widget.color),
  );
}

/// Item lido ou adicionado: nome 20/700, apoio, preço 700 tabular à direita.
class _ReadItem extends StatelessWidget {
  const _ReadItem({
    required this.name,
    required this.detail,
    required this.price,
    this.added = false,
  });
  final String name;
  final String? detail;
  final String price;
  final bool added;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (added)
          Padding(
            padding: const EdgeInsets.only(bottom: TinoSpace.s4),
            child: Row(
              children: [
                _CheckPop(color: c.action),
                const SizedBox(width: TinoSpace.s4),
                Flexible(
                  child: Text(
                    'Adicionado ao carrinho',
                    style: TinoType.caption.withColor(c.action),
                  ),
                ),
              ],
            ),
          ),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TinoType.secao.withColor(c.textPrimary),
        ),
        if (detail != null)
          Text(detail!, style: TinoType.caption.withColor(c.textSecondary)),
      ],
    );
    return Semantics(
      liveRegion: added,
      label: added ? '$name, $price, adicionado' : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Rise(child: info)),
          const SizedBox(width: TinoSpace.s12),
          _Rise(
            delay: TinoMotion.stagger,
            child: Text(
              price,
              style: TinoType.display.withColor(c.textPrimary).money,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado sem item: título e uma frase de apoio.
class _Message extends StatelessWidget {
  const _Message({required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return _Rise(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TinoType.secao.withColor(c.textPrimary)),
          const SizedBox(height: TinoSpace.s4),
          Text(detail, style: TinoType.secundario.withColor(c.textSecondary)),
        ],
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
    final style = TinoType.label.withColor(context.tino.textPrimary);
    return Row(
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
    );
  }
}

/// Câmera em largura total, alinhada ao topo, e o visor desenhado em cima,
/// nas mesmas coordenadas da imagem: o visor é exatamente a [scanGuide] que
/// vai para o OCR.
class _CameraLayer extends StatelessWidget {
  const _CameraLayer({
    required this.camera,
    required this.locks,
    required this.locked,
  });
  final CameraController? camera;
  final int locks;
  final bool locked;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final c = camera;
      final ready = c != null && c.value.isInitialized;
      // Proporção da imagem em pé; antes de abrir, a do ResolutionPreset.high.
      final aspect = ready ? 1 / c.value.aspectRatio : 9 / 16;
      final width = box.maxWidth;
      final height = width / aspect;
      final visor = Rect.fromLTRB(
        scanGuide.left * width,
        scanGuide.top * height,
        scanGuide.right * width,
        scanGuide.bottom * height,
      );
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (ready)
            Positioned(
              left: 0,
              top: 0,
              width: width,
              height: height,
              child: CameraPreview(c),
            ),
          Positioned.fill(
            child: _Viewfinder(rect: visor, locks: locks, locked: locked),
          ),
        ],
      );
    },
  );
}

/// Recuo dos cantos ao travar, na horizontal; na vertical, × 0,55.
const _lockInset = 26.0;

/// Impulso de escala do visor ao travar (1 → ~1,06 → 1).
const _lockImpulse = 1.6;

/// Visor: quatro cantos `action` do escuro (jade-claro), traço 4, raio 16.
/// Sem animação contínua. Entra com escala 1,15 → 1 (M2) e, a cada novo
/// travamento, faz o M3a.
class _Viewfinder extends StatefulWidget {
  const _Viewfinder({
    required this.rect,
    required this.locks,
    required this.locked,
  });
  final Rect rect;
  final int locks;
  final bool locked;

  @override
  State<_Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<_Viewfinder>
    with TickerProviderStateMixin {
  late final _scale = AnimationController.unbounded(vsync: this, value: 1);
  late final _inset = AnimationController.unbounded(vsync: this);
  late final _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final _seal = AnimationController.unbounded(vsync: this, value: 1);
  late final _sealFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  final _timers = <Timer>[];
  var _entered = false;
  var _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = TinoMotion.reduced(context);
    if (_entered) return;
    _entered = true;
    if (widget.locked) _sealFade.value = 1;
    if (_reduced) return;
    _scale.animateWith(TinoMotion.spring(TinoSprings.cartao, 1.15, 1));
  }

  @override
  void didUpdateWidget(_Viewfinder old) {
    super.didUpdateWidget(old);
    if (widget.locks != old.locks) _lock();
    if (widget.locked && !old.locked) {
      _sealFade.forward();
    } else if (!widget.locked && old.locked) {
      _sealFade.reverse();
    }
  }

  /// M3a: cantos fecham na etiqueta, visor pula, cantos piscam em branco e o
  /// selo entra. Depois de 600 ms os cantos voltam ao tamanho do visor.
  void _lock() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _flash.value = 1;
    _timers.add(
      Timer(const Duration(milliseconds: 250), () => _flash.reverse()),
    );
    if (_reduced) return;
    _scale.animateWith(
      TinoMotion.spring(
        TinoSprings.confirmacao,
        _scale.value,
        1,
        _scale.velocity + _lockImpulse,
      ),
    );
    _inset.animateWith(
      TinoMotion.spring(
        TinoSprings.confirmacao,
        _inset.value,
        _lockInset,
        _inset.velocity,
      ),
    );
    _seal.animateWith(TinoMotion.spring(TinoSprings.confirmacao, 0.7, 1));
    _timers.add(
      Timer(const Duration(milliseconds: 600), () {
        _inset.animateWith(
          TinoMotion.spring(
            TinoSprings.cartao,
            _inset.value,
            0,
            _inset.velocity,
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _scale.dispose();
    _inset.dispose();
    _flash.dispose();
    _seal.dispose();
    _sealFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    final rect = widget.rect;
    return Stack(
      children: [
        Positioned.fromRect(
          rect: rect,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_scale, _inset, _flash]),
              builder: (context, _) => Transform.scale(
                scale: _scale.value,
                child: CustomPaint(
                  size: rect.size,
                  painter: _CornersPainter(
                    inset: _inset.value,
                    color: Color.lerp(
                      c.action,
                      c.textPrimary,
                      TinoCurves.easeOut.transform(_flash.value),
                    )!,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: rect.bottom + TinoSpace.s24,
          child: Center(
            child: FadeTransition(
              opacity: _sealFade,
              child: ScaleTransition(
                scale: _seal,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TinoSpace.s12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(TinoRadius.pill),
                  ),
                  child: Text(
                    'Preço travado',
                    style: TinoType.secundario.withColor(c.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cantos do visor: braço de 32 (16 reto + raio 16), traço 4, ponta redonda.
class _CornersPainter extends CustomPainter {
  const _CornersPainter({required this.inset, required this.color});
  final double inset;
  final Color color;

  static const _stroke = 4.0;
  static const _radius = 16.0;
  static const _arm = 32.0;

  @override
  void paint(Canvas canvas, Size size) {
    final dx = inset;
    final dy = inset * 0.55;
    final r = Rect.fromLTRB(
      dx + _stroke / 2,
      dy + _stroke / 2,
      size.width - dx - _stroke / 2,
      size.height - dy - _stroke / 2,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    const arc = Radius.circular(_radius);
    final path = Path()
      // Superior esquerdo.
      ..moveTo(r.left, r.top + _arm)
      ..lineTo(r.left, r.top + _radius)
      ..arcToPoint(Offset(r.left + _radius, r.top), radius: arc)
      ..lineTo(r.left + _arm, r.top)
      // Superior direito.
      ..moveTo(r.right - _arm, r.top)
      ..lineTo(r.right - _radius, r.top)
      ..arcToPoint(Offset(r.right, r.top + _radius), radius: arc)
      ..lineTo(r.right, r.top + _arm)
      // Inferior direito.
      ..moveTo(r.right, r.bottom - _arm)
      ..lineTo(r.right, r.bottom - _radius)
      ..arcToPoint(Offset(r.right - _radius, r.bottom), radius: arc)
      ..lineTo(r.right - _arm, r.bottom)
      // Inferior esquerdo.
      ..moveTo(r.left + _arm, r.bottom)
      ..lineTo(r.left + _radius, r.bottom)
      ..arcToPoint(Offset(r.left, r.bottom - _radius), radius: arc)
      ..lineTo(r.left, r.bottom - _arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornersPainter old) =>
      old.inset != inset || old.color != color;
}
