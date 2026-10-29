import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/area_page.dart';
import '../data/onboarding_preference.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.review = false});

  final bool review;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  bool _saving = false;
  String? _error;

  static const _steps = [
    (
      title: 'Conheça o Tino',
      description: 'Comprar bem começa antes.',
      icon: LucideIcons.shoppingBasket,
      message: 'Mais clareza nas suas escolhas',
      detail:
          'Um aplicativo brasileiro gratuito, de código aberto e sem anúncios. '
          'Feito para ajudar você a comprar com calma.',
    ),
    (
      title: 'Acompanhe a compra',
      description: 'Conheça o total antes de chegar ao caixa.',
      icon: LucideIcons.scanLine,
      message: 'Cada produto conta',
      detail:
          'A leitura de etiquetas e o carrinho vão ajudar a acompanhar o total. '
          'Esses recursos ainda estão em preparação.',
    ),
    (
      title: 'Controle o orçamento',
      description: 'Planeje quanto você quer gastar.',
      icon: LucideIcons.wallet,
      message: 'Mais tranquilidade até o caixa',
      detail:
          'Você poderá definir um orçamento e receber alertas durante a compra. '
          'Esses recursos ainda estão em preparação.',
    ),
  ];

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
    final step = _steps[_step];
    return PopScope(
      canPop: !_saving && (_step == 0 || widget.review),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving && _step > 0) {
          setState(() => _step--);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (widget.review)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _exitReview,
                          icon: const Icon(LucideIcons.arrowLeft, size: 24),
                          label: const Text('Voltar aos Ajustes'),
                        ),
                      )
                    else
                      const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : _finish,
                      child: const Text('Pular'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: AreaPage(
                    key: ValueKey(_step),
                    branding: SvgPicture.asset(
                      'assets/branding/tino-wordmark.svg',
                      width: 88,
                      height: 34,
                      fit: BoxFit.contain,
                      semanticsLabel: 'Tino',
                    ),
                    title: step.title,
                    description: step.description,
                    icon: step.icon,
                    message: step.message,
                    detail: step.detail,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text('${_step + 1} de ${_steps.length}'),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Semantics(liveRegion: true, child: Text(_error!)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  if (_step == _steps.length - 1) {
                                    _finish();
                                  } else {
                                    setState(() => _step++);
                                  }
                                },
                          child: Text(
                            _saving
                                ? 'Salvando…'
                                : _step == _steps.length - 1
                                ? 'Começar'
                                : 'Próximo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
