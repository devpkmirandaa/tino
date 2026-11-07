import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';
import '../data/lab_mode.dart';
import '../data/settings_preferences.dart';

/// Ajustes (design/telas/10-ajustes.html): fora das abas, abre pela
/// engrenagem do Comprar e volta para ele. Só aparece o que já funciona;
/// Sons, recortes de etiqueta e Apoiar entram quando existirem.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.tino;
    final autoAdd = ref.watch(autoAddProvider).value ?? true;
    final vibrate = ref.watch(vibrateOnReadProvider).value ?? true;
    final appearance = ref.watch(appearanceProvider).value ?? Appearance.system;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            TinoSpace.s16,
            TinoSpace.s8,
            TinoSpace.s16,
            TinoSpace.s24,
          ),
          children: [
            Row(
              children: [
                Transform.translate(
                  offset: const Offset(-TinoSpace.s12, 0),
                  child: TinoIconButton(
                    key: const ValueKey('settings-back'),
                    icon: LucideIcons.chevronLeft,
                    semanticLabel: 'Voltar',
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    'Ajustes',
                    style: TinoType.tela.withColor(c.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TinoSpace.s16),
            _Section(
              title: 'Na compra',
              children: [
                _SwitchRow(
                  key: const ValueKey('settings-auto-add'),
                  title: 'Adicionar ao travar o preço',
                  detail: 'Sem precisar tocar em nada',
                  value: autoAdd,
                  onChanged: ref.read(autoAddProvider.notifier).set,
                ),
                _SwitchRow(
                  key: const ValueKey('settings-vibrate'),
                  title: 'Vibrar ao ler',
                  value: vibrate,
                  onChanged: ref.read(vibrateOnReadProvider.notifier).set,
                ),
              ],
            ),
            const SizedBox(height: TinoSpace.s24),
            _SectionTitle('Aparência'),
            const SizedBox(height: TinoSpace.s8),
            TinoSegmented<Appearance>(
              key: const ValueKey('settings-appearance'),
              segments: const [
                (value: Appearance.system, label: 'Automático'),
                (value: Appearance.light, label: 'Claro'),
                (value: Appearance.dark, label: 'Escuro'),
              ],
              selected: appearance,
              onChanged: ref.read(appearanceProvider.notifier).set,
            ),
            const SizedBox(height: TinoSpace.s24),
            _Section(
              title: 'Sobre',
              children: [
                _LinkRow(
                  title: 'Código aberto e licenças',
                  onPressed: () => _showLicenses(context),
                ),
                _LinkRow(
                  title: 'Rever apresentação',
                  onPressed: () => context.push('/apresentacao?rever=true'),
                ),
              ],
            ),
            const SizedBox(height: TinoSpace.s32),
            const _DeveloperTaps(child: _Version()),
          ],
        ),
      ),
    );
  }

  static Future<void> _showLicenses(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showLicensePage(
      context: context,
      applicationName: 'Tino',
      applicationVersion: info.version,
      applicationLegalese:
          'Gratuito, de código aberto e sem anúncios. Ícones: Lucide (ISC).',
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: TinoType.caption
          .withColor(context.tino.textSecondary)
          .copyWith(
            fontWeight: FontWeight.w600,
            fontVariations: tinoWeightAxis(FontWeight.w600),
          ),
    ),
  );
}

/// Rótulo 12/600 + cartão compacto com as linhas separadas por borda.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title),
        const SizedBox(height: TinoSpace.s8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
            border: Border.all(color: c.border, width: TinoSize.borderWidth),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: TinoSize.borderWidth,
                      thickness: TinoSize.borderWidth,
                      color: c.border,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Linha com chave: a linha inteira liga e desliga.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    super.key,
    required this.title,
    this.detail,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TinoSpace.s16,
              vertical: TinoSpace.s8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TinoType.corpo
                            .withColor(c.textPrimary)
                            .copyWith(
                              fontWeight: FontWeight.w500,
                              fontVariations: tinoWeightAxis(FontWeight.w500),
                            ),
                      ),
                      if (detail != null)
                        Text(
                          detail!,
                          style: TinoType.caption.withColor(c.textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: TinoSpace.s12),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: c.action,
                  activeThumbColor: c.onAction,
                  inactiveTrackColor: c.surfaceSoft,
                  inactiveThumbColor: c.textSecondary,
                  trackOutlineColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? c.action
                        : c.borderStrong,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha que abre outra tela, com chevron 20 `text-secondary`.
class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.title, required this.onPressed});
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TinoSize.inputHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TinoSpace.s16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TinoType.corpo
                        .withColor(c.textPrimary)
                        .copyWith(
                          fontWeight: FontWeight.w500,
                          fontVariations: tinoWeightAxis(FontWeight.w500),
                        ),
                  ),
                ),
                const SizedBox(width: TinoSpace.s12),
                Icon(
                  LucideIcons.chevronRight,
                  size: TinoSize.iconCompact,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Tino beta · versão", lida do pacote instalado.
class _Version extends StatelessWidget {
  const _Version();

  static final _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _info,
    builder: (context, snapshot) => Text(
      snapshot.hasData ? 'Tino beta · ${snapshot.data!.version}' : 'Tino beta',
      textAlign: TextAlign.center,
      style: TinoType.caption.withColor(context.tino.textSecondary),
    ),
  );
}

/// Opção de desenvolvedor escondida: 7 toques seguidos no rodapé ligam ou
/// desligam o modo laboratório do scanner.
class _DeveloperTaps extends ConsumerStatefulWidget {
  const _DeveloperTaps({required this.child});
  final Widget child;

  @override
  ConsumerState<_DeveloperTaps> createState() => _DeveloperTapsState();
}

class _DeveloperTapsState extends ConsumerState<_DeveloperTaps> {
  var _taps = 0;
  var _last = DateTime(0);

  Future<void> _tap() async {
    final now = DateTime.now();
    _taps = now.difference(_last) < const Duration(seconds: 1) ? _taps + 1 : 1;
    _last = now;
    if (_taps < 7) return;
    _taps = 0;
    final on = await ref.read(labModeProvider.notifier).toggle();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          on ? 'Modo laboratório ligado.' : 'Modo laboratório desligado.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _tap,
    child: widget.child,
  );
}
