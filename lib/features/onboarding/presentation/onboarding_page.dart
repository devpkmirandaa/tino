import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_wordmark.dart';
import '../data/onboarding_preference.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.review = false});
  final bool review;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();
  late final _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final _entryCurve = CurvedAnimation(
    parent: _entry,
    curve: Curves.easeOutCubic,
  );
  bool _entryStarted = false;
  int _step = 0;
  bool _hasAdvanced = false;
  bool _saving = false;
  String? _error;

  static const _steps = [
    (
      title: 'Comprar bem começa antes.',
      support: 'Acompanhe quanto vai gastar antes de chegar ao caixa.',
    ),
    (
      title: 'Aponte. Confira. Adicione.',
      support: 'Leia a etiqueta com a câmera e confirme o produto para somar à compra.',
    ),
    (
      title: 'Seu limite, sempre à vista.',
      support: 'Defina um orçamento e acompanhe o que ainda pode gastar.',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entry.value = 1;
      _entryStarted = true;
    } else if (!_entryStarted) {
      _entryStarted = true;
      _entry.forward();
    }
  }

  @override
  void dispose() {
    _entryCurve.dispose();
    _entry.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (_saving) return;
    _entry.value = 1;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _exitReview() {
    if (_saving) return;
    setState(() => _saving = true);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/ajustes');
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    if (widget.review) {
      _exitReview();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(onboardingPreferenceProvider).markSeen();
      if (mounted) context.go('/');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Não foi possível salvar sua escolha. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving && (_step == 0 || widget.review),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving && _step > 0) _goTo(_step - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              overscroll: false,
              physics: const ClampingScrollPhysics(),
            ),
            child: LayoutBuilder(
              builder: (context, viewport) {
                final margin = viewport.maxWidth < 320 ? 16.0 : 24.0;
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: margin),
                      child: SizedBox(
                        height: 56,
                        child: Row(
                          children: [
                            if (widget.review)
                              IconButton(
                                onPressed: _saving ? null : _exitReview,
                                tooltip: 'Fechar apresentação',
                                icon: const Icon(LucideIcons.x),
                              ),
                            const Spacer(),
                            _AnimatedVisibility(
                              visible: _step < 2,
                              collapse: false,
                              child: TextButton(
                                onPressed: _saving ? null : _finish,
                                child: const Text('Pular'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Listener(
                        onPointerDown: (_) {
                          // O dedo assume o movimento: não somar entrada ao arraste.
                          if (!_entry.isCompleted) _entry.value = 1;
                        },
                        child: FadeTransition(
                          key: const ValueKey('intro-entry'),
                          opacity: _entryCurve,
                          child: AnimatedBuilder(
                            animation: _entryCurve,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, 10 * (1 - _entryCurve.value)),
                              child: child,
                            ),
                            child: PageView.builder(
                              controller: _pages,
                              allowImplicitScrolling: true,
                              physics: _saving
                                  ? const NeverScrollableScrollPhysics()
                                  : const _TutorialSnapPhysics(),
                              itemCount: _steps.length,
                              onPageChanged: (page) => setState(() {
                                _step = page;
                                if (page > 0) _hasAdvanced = true;
                              }),
                              itemBuilder: (context, index) => ExcludeSemantics(
                                excluding: index != _step,
                                child: LayoutBuilder(
                                  builder: (context, page) {
                                    final text = Theme.of(context).textTheme;
                                    return SingleChildScrollView(
                                      key: PageStorageKey(
                                        'intro-content-$index',
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: margin,
                                        vertical: 24,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: math.max(
                                            0,
                                            page.maxHeight - 48,
                                          ),
                                        ),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 560,
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (index == 0) ...[
                                                    const TinoWordmark(
                                                      width: 96,
                                                    ),
                                                    const SizedBox(height: 40),
                                                  ],
                                                  Semantics(
                                                    header: true,
                                                    child: Text(
                                                      _steps[index].title,
                                                      style: text.headlineMedium
                                                          ?.copyWith(
                                                            fontSize: 28,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            height: 1.25,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    _steps[index].support,
                                                    style: text.bodyLarge
                                                        ?.copyWith(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          height: 1.5,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: math.min(180, viewport.maxHeight * .35),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: margin,
                            vertical: 16,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AnimatedVisibility(
                                  visible: !_hasAdvanced && _step == 0,
                                  child: Text(
                                    'Deslize para continuar',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (
                                      var index = 0;
                                      index < _steps.length;
                                      index++
                                    )
                                      MergeSemantics(
                                        child: Semantics(
                                          label:
                                              'Página ${index + 1} de ${_steps.length}',
                                          selected: index == _step,
                                          child: SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: TextButton(
                                              key: ValueKey(
                                                'intro-indicator-$index',
                                              ),
                                              onPressed: _saving
                                                  ? null
                                                  : () => _goTo(index),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: ExcludeSemantics(
                                                child: AnimatedBuilder(
                                                  animation: _pages,
                                                  builder: (context, child) {
                                                    final page =
                                                        _pages.hasClients
                                                        ? (_pages.page ??
                                                              _step.toDouble())
                                                        : _step.toDouble();
                                                    final weight =
                                                        (1 -
                                                                (page - index)
                                                                    .abs())
                                                            .clamp(0.0, 1.0);
                                                    return Container(
                                                      key: ValueKey(
                                                        'intro-dot-$index',
                                                      ),
                                                      width: 8 + 16 * weight,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: Color.lerp(
                                                          TinoColors.lightJade,
                                                          TinoColors.jade,
                                                          weight,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(_error!),
                                  ),
                                ],
                                _AnimatedVisibility(
                                  visible: _step == 2,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: _saving ? null : _finish,
                                        child: Text(
                                          _saving ? 'Salvando…' : 'Começar',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Clamping nas bordas e encaixe amortecido, sem efeito elástico.
class _TutorialSnapPhysics extends ClampingScrollPhysics {
  const _TutorialSnapPhysics({super.parent});

  @override
  _TutorialSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _TutorialSnapPhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 360, ratio: 1.1);
}

/// Anima só controles pequenos; sem atrasar o toque ou expor ações ocultas.
class _AnimatedVisibility extends StatelessWidget {
  const _AnimatedVisibility({
    required this.visible,
    required this.child,
    this.collapse = true,
  });
  final bool visible;
  final Widget child;
  final bool collapse;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: visible ? 1 : 0, end: visible ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    child: IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(excluding: !visible, child: child),
    ),
    builder: (context, value, child) {
      final faded = Opacity(opacity: value, child: child);
      return collapse
          ? ClipRect(
              child: Align(heightFactor: value, child: faded),
            )
          : faded;
    },
  );
}
