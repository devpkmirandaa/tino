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

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pages = PageController();
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
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (_saving) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _exitReview() {
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
                          if (_step < 2)
                            TextButton(
                              onPressed: _saving ? null : _finish,
                              child: const Text('Pular'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      allowImplicitScrolling: true,
                      physics: _saving
                          ? const NeverScrollableScrollPhysics()
                          : null,
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
                              key: PageStorageKey('intro-content-$index'),
                              padding: EdgeInsets.symmetric(
                                horizontal: margin,
                                vertical: 24,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: math.max(0, page.maxHeight - 48),
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
                                            const TinoWordmark(width: 96),
                                            const SizedBox(height: 40),
                                          ],
                                          Semantics(
                                            header: true,
                                            child: Text(
                                              _steps[index].title,
                                              style: text.headlineMedium
                                                  ?.copyWith(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.25,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _steps[index].support,
                                            style: text.bodyLarge?.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
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
                              if (!_hasAdvanced && _step == 0)
                                Text(
                                  'Deslize para continuar',
                                  style: Theme.of(context).textTheme.bodySmall,
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
                                              child: Container(
                                                width: index == _step ? 24 : 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: index == _step
                                                      ? TinoColors.jade
                                                      : TinoColors.lightJade,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
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
                              if (_step == 2) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _saving ? null : _finish,
                                    child: Text(
                                      _saving ? 'Salvando…' : 'Começar',
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }
}
