import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/tino_springs.dart';
import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_button.dart';
import '../../../core/widgets/tino_cascade_block.dart';
import '../../../core/widgets/tino_wordmark.dart';
import '../data/onboarding_preference.dart';
import 'welcome_illustration.dart';

/// Boas-vindas (design/telas/01), com entrada M10. Na primeira abertura,
/// "Começar" grava a preferência e vai pro Comprar. Em [review] (Ajustes →
/// Rever apresentação), "Começar" e o Voltar só voltam pra Ajustes.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.review = false});
  final bool review;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  /// M10: cada bloco sobe deste deslocamento (px).
  static const _entryOffset = 32.0;
  static const _wordmarkHeight = 32.0;
  static const _maxWidth = 560.0;

  static const _benefits = [
    'Grátis e sem anúncios',
    'Lê o preço no próprio celular',
    'Avisa quanto falta do orçamento',
  ];

  bool _saving = false;
  String? _error;

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
    final c = context.tino;
    final reduced = TinoMotion.reduced(context);
    // Sem wordmark no escuro: o SVG negativo usa <style>, que o flutter_svg
    // ignora (sairia preto). Volta quando o arquivo for corrigido.
    final showWordmark = c.brightness == Brightness.light;

    Widget block(int index, Widget child, {double fromScale = 1}) =>
        TinoCascadeBlock(
          index: index,
          reduced: reduced,
          offset: _entryOffset,
          fromScale: fromScale,
          child: child,
        );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showWordmark) ...[
          block(
            0,
            const Align(
              alignment: Alignment.centerLeft,
              child: TinoWordmark(
                width: _wordmarkHeight * TinoWordmark.aspectRatio,
              ),
            ),
          ),
          const SizedBox(height: TinoSpace.s32),
        ],
        block(
          1,
          WelcomeIllustration(sealIndex: 5, reduced: reduced),
          fromScale: 0.9,
        ),
        const SizedBox(height: TinoSpace.s32),
        block(
          2,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Comprar bem começa antes.',
                  style: TinoType.display.withColor(c.textPrimary),
                ),
              ),
              const SizedBox(height: TinoSpace.s8),
              Text(
                'Aponte a câmera para a etiqueta. O Tino lê o preço e soma '
                'tudo pra você.',
                style: TinoType.corpo.withColor(c.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: TinoSpace.s32),
        block(
          3,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _benefits.length; i++) ...[
                if (i > 0) const SizedBox(height: TinoSpace.s12),
                Row(
                  children: [
                    Icon(
                      LucideIcons.check,
                      size: TinoSize.iconCompact,
                      color: c.action,
                    ),
                    const SizedBox(width: TinoSpace.s12),
                    Expanded(
                      child: Text(
                        _benefits[i],
                        style: TinoType.secundario.withColor(c.textPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final actions = block(
      4,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TinoType.secundario.withColor(c.textPrimary),
              ),
            ),
            const SizedBox(height: TinoSpace.s12),
          ],
          TinoButton.primary(
            label: _saving && !widget.review ? 'Salvando…' : 'Começar',
            onPressed: _saving ? null : _finish,
            expand: true,
          ),
          const SizedBox(height: TinoSpace.s12),
          Text(
            'A câmera só é pedida quando você escanear pela primeira vez.',
            textAlign: TextAlign.center,
            style: TinoType.caption.withColor(c.textSecondary),
          ),
        ],
      ),
    );

    Widget limit(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: child,
      ),
    );

    return PopScope(
      // Primeira abertura: Voltar sai do app sem marcar como vista.
      // Revisão: volta pra Ajustes, sem gravar nada.
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    TinoSpace.s16,
                    TinoSpace.s32,
                    TinoSpace.s16,
                    TinoSpace.s24,
                  ),
                  child: limit(content),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TinoSpace.s16,
                  0,
                  TinoSpace.s16,
                  TinoSpace.s32,
                ),
                child: limit(actions),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
