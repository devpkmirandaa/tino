// Vitrine dos componentes base. Só desenvolvimento, fora do app.
// flutter run -t lib/dev/vitrine_main.dart -d ZF524K6WC6
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/tino_theme.dart';
import '../core/widgets/tino_widgets.dart';

void main() => runApp(const TinoVitrineApp());

class TinoVitrineApp extends StatefulWidget {
  const TinoVitrineApp({super.key});

  @override
  State<TinoVitrineApp> createState() => _TinoVitrineAppState();
}

class _TinoVitrineAppState extends State<TinoVitrineApp> {
  ThemeMode _mode = ThemeMode.light;
  bool _reduced = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Tino · Vitrine',
    debugShowCheckedModeBanner: false,
    theme: buildTinoTheme(Brightness.light),
    darkTheme: buildTinoTheme(Brightness.dark),
    themeMode: _mode,
    // Acima do Navigator: folhas também enxergam o movimento reduzido.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: _reduced || MediaQuery.of(context).disableAnimations,
      ),
      child: child ?? const SizedBox.shrink(),
    ),
    home: VitrinePage(
      dark: _mode == ThemeMode.dark,
      reduced: _reduced,
      onToggleTheme: () => setState(
        () =>
            _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      ),
      onToggleReduced: () => setState(() => _reduced = !_reduced),
    ),
  );
}

class VitrinePage extends StatefulWidget {
  const VitrinePage({
    super.key,
    required this.dark,
    required this.reduced,
    required this.onToggleTheme,
    required this.onToggleReduced,
  });

  final bool dark;
  final bool reduced;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleReduced;

  @override
  State<VitrinePage> createState() => _VitrinePageState();
}

enum _Unit { unidade, peso }

class _VitrinePageState extends State<VitrinePage> {
  _Unit _unit = _Unit.unidade;
  int _quantity = 1;
  double _progress = 0.4;
  int _taps = 0;

  void _tap() => setState(() => _taps++);

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: TinoSpace.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TinoType.secao.withColor(c.textPrimary)),
          const SizedBox(height: TinoSpace.s12),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: TinoSpace.s12),
            children[i],
          ],
        ],
      ),
    );

    return TinoSheetScope(
      child: Scaffold(
        backgroundColor: c.canvas,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(TinoSpace.s16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vitrine',
                      style: TinoType.tela.withColor(c.textPrimary),
                    ),
                  ),
                  TinoIconButton(
                    icon: widget.dark ? LucideIcons.sun : LucideIcons.moon,
                    semanticLabel: widget.dark
                        ? 'Usar tema claro'
                        : 'Usar tema escuro',
                    onPressed: widget.onToggleTheme,
                  ),
                ],
              ),
              Text(
                'Toques: $_taps',
                style: TinoType.secundario.withColor(c.textSecondary),
              ),
              const SizedBox(height: TinoSpace.s8),
              TinoChip(
                label: widget.reduced
                    ? 'Movimento reduzido: ligado'
                    : 'Movimento reduzido: desligado',
                icon: LucideIcons.gauge,
                onPressed: widget.onToggleReduced,
              ),
              const SizedBox(height: TinoSpace.s24),
              section('Botões', [
                TinoButton.primary(
                  label: 'Escanear preço',
                  icon: LucideIcons.scanLine,
                  size: TinoButtonSize.scan,
                  expand: true,
                  onPressed: _tap,
                ),
                TinoButton.primary(
                  label: 'Concluir compra',
                  expand: true,
                  onPressed: _tap,
                ),
                const TinoButton.primary(
                  label: 'Desativado',
                  expand: true,
                  onPressed: null,
                ),
                Wrap(
                  spacing: TinoSpace.s8,
                  runSpacing: TinoSpace.s8,
                  children: [
                    TinoButton.outlined(label: 'Contornado', onPressed: _tap),
                    TinoButton.outlined(
                      label: 'Em action',
                      accent: true,
                      onPressed: _tap,
                    ),
                    TinoButton.text(label: 'Digitar preço', onPressed: _tap),
                  ],
                ),
                Row(
                  children: [
                    TinoIconButton(
                      icon: LucideIcons.settings,
                      semanticLabel: 'Ajustes',
                      onPressed: _tap,
                    ),
                    TinoIconButton(
                      icon: LucideIcons.flashlight,
                      semanticLabel: 'Lanterna',
                      accent: true,
                      onPressed: _tap,
                    ),
                    const TinoIconButton(
                      icon: LucideIcons.trash2,
                      semanticLabel: 'Remover',
                      onPressed: null,
                    ),
                  ],
                ),
              ]),
              section('Chips', [
                Wrap(
                  spacing: TinoSpace.s8,
                  children: [
                    TinoChip(
                      label: 'Orçamento',
                      icon: LucideIcons.wallet,
                      onPressed: _tap,
                    ),
                    TinoChip(
                      label: 'Usar uma lista',
                      icon: LucideIcons.listChecks,
                      onPressed: _tap,
                    ),
                  ],
                ),
              ]),
              section('Input', [
                const TinoInput(
                  label: 'Nome do produto',
                  hint: 'Ex.: Arroz 5 kg',
                ),
                const TinoInput(
                  label: 'Preço',
                  hint: '0,00',
                  suffix: 'R\$',
                  money: true,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ]),
              section('Cartões', [
                TinoCard(
                  onPressed: _tap,
                  semanticLabel: 'Lista do mês',
                  child: Text(
                    'Cartão tocável (raio 20)',
                    style: TinoType.corpo.withColor(c.textPrimary),
                  ),
                ),
                TinoCard(
                  compact: true,
                  child: Text(
                    'Cartão compacto (raio 16)',
                    style: TinoType.corpo.withColor(c.textPrimary),
                  ),
                ),
              ]),
              section('Linhas de item', [
                TinoCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(TinoRadius.card),
                    child: Column(
                      children: [
                        TinoItemRow(
                          title: 'Molho de tomate',
                          subtitle: '2 × R\$ 3,00',
                          price: 'R\$ 6,00',
                          onPressed: _tap,
                        ),
                        Divider(color: c.border, height: 1),
                        TinoItemRow(
                          title: 'Banana prata',
                          subtitle: '0,845 kg · R\$ 6,99/kg',
                          price: 'R\$ 5,91',
                          onPressed: _tap,
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              section('Controle segmentado', [
                TinoSegmented<_Unit>(
                  segments: const [
                    (value: _Unit.unidade, label: 'Unidade'),
                    (value: _Unit.peso, label: 'Peso'),
                  ],
                  selected: _unit,
                  onChanged: (u) => setState(() => _unit = u),
                ),
              ]),
              section('Contador de quantidade', [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TinoQuantityStepper(
                    value: _quantity,
                    onChanged: (q) => setState(() => _quantity = q),
                  ),
                ),
              ]),
              section('Barra de progresso', [
                TinoProgressBar(
                  value: _progress,
                  over: _progress >= 1,
                  overLabel: 'Passou R\$ 12,40',
                  semanticLabel: 'Orçamento usado',
                ),
                TinoProgressBar(value: _progress, compact: true),
                Wrap(
                  spacing: TinoSpace.s8,
                  children: [
                    TinoButton.outlined(
                      label: '− 20%',
                      onPressed: () => setState(
                        () => _progress = (_progress - 0.2).clamp(0.0, 1.0),
                      ),
                    ),
                    TinoButton.outlined(
                      label: '+ 20%',
                      onPressed: () => setState(
                        () => _progress = (_progress + 0.2).clamp(0.0, 1.0),
                      ),
                    ),
                    TinoButton.outlined(
                      label: 'Passar do orçamento',
                      accent: true,
                      onPressed: () => setState(() => _progress = 1),
                    ),
                  ],
                ),
              ]),
              section('Folha', [
                TinoButton.primary(
                  label: 'Abrir folha',
                  expand: true,
                  onPressed: () => _openSheet(context),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    final c = context.tino;
    showTinoSheet<void>(
      context,
      blocks: [
        Text('Digitar preço', style: TinoType.secao.withColor(c.textPrimary)),
        Text(
          'Arraste pra baixo pra fechar. Pra cima, a folha resiste.',
          style: TinoType.secundario.withColor(c.textSecondary),
        ),
        const TinoInput(
          label: 'Preço',
          hint: '0,00',
          suffix: 'R\$',
          money: true,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        Builder(
          builder: (context) => TinoButton.primary(
            label: 'Adicionar',
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
