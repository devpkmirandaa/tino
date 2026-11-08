import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tino_theme.dart';
import '../../../core/widgets/tino_widgets.dart';

/// Resposta da folha 14 (antes de pedir a câmera).
enum CameraAskChoice { allow, type }

/// Resposta da folha 15 (câmera sem permissão).
enum CameraDeniedChoice { type, settings }

/// 14 · Câmera, antes de pedir (design/telas/14-camera-pedido.html). O
/// bloco do escudo sobre recortes da Saúva fica escondido até a coleta
/// existir (docs/ONDE_PARAMOS.md).
Future<CameraAskChoice?> showCameraAskSheet(BuildContext context) =>
    showTinoSheet<CameraAskChoice>(
      context,
      barrierLabel: 'Fechar usar a câmera',
      blocks: [
        const _Header('Usar a câmera'),
        const _Message(
          icon: LucideIcons.camera,
          title: 'O Tino lê o preço pela câmera',
          detail:
              'Aponte pra etiqueta e o item entra no carrinho. Nenhuma foto '
              'sai do celular.',
        ),
        Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TinoButton.primary(
                key: const ValueKey('camera-allow'),
                label: 'Permitir câmera',
                icon: LucideIcons.camera,
                expand: true,
                onPressed: () => Navigator.pop(context, CameraAskChoice.allow),
              ),
              const SizedBox(height: TinoSpace.s4),
              TinoButton.text(
                key: const ValueKey('camera-not-now'),
                label: 'Agora não, vou digitar',
                expand: true,
                onPressed: () => Navigator.pop(context, CameraAskChoice.type),
              ),
            ],
          ),
        ),
      ],
    );

/// 15 · Câmera sem permissão (design/telas/15-camera-negada.html).
Future<CameraDeniedChoice?> showCameraDeniedSheet(BuildContext context) =>
    showTinoSheet<CameraDeniedChoice>(
      context,
      barrierLabel: 'Fechar câmera desligada',
      blocks: [
        const _Header('Câmera desligada'),
        const _Message(
          icon: LucideIcons.cameraOff,
          title: 'Sem a câmera, dá pra digitar o preço.',
          detail:
              'Se mudar de ideia, libere a câmera pro Tino nos ajustes do '
              'celular.',
        ),
        Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TinoButton.primary(
                key: const ValueKey('camera-denied-type'),
                label: 'Digitar preço',
                icon: LucideIcons.keyboard,
                expand: true,
                onPressed: () =>
                    Navigator.pop(context, CameraDeniedChoice.type),
              ),
              const SizedBox(height: TinoSpace.s8),
              TinoButton.outlined(
                key: const ValueKey('camera-denied-settings'),
                label: 'Abrir ajustes do celular',
                icon: LucideIcons.settings,
                expand: true,
                onPressed: () =>
                    Navigator.pop(context, CameraDeniedChoice.settings),
              ),
            ],
          ),
        ),
      ],
    );

class _Header extends StatelessWidget {
  const _Header(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: TinoType.secao.withColor(context.tino.textPrimary),
          ),
        ),
      ),
      Transform.translate(
        offset: const Offset(TinoSpace.s12, 0),
        child: TinoIconButton(
          icon: LucideIcons.x,
          semanticLabel: 'Fechar',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    ],
  );
}

/// Ícone num quadrado 64 `surface-soft`, título 20/700 e apoio 16/400,
/// centralizados.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  static const _box = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.tino;
    return Column(
      children: [
        Container(
          width: _box,
          height: _box,
          decoration: BoxDecoration(
            color: c.surfaceSoft,
            borderRadius: BorderRadius.circular(TinoRadius.cardCompact),
          ),
          child: Icon(icon, size: TinoSize.icon, color: c.action),
        ),
        const SizedBox(height: TinoSpace.s16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TinoType.secao.withColor(c.textPrimary),
        ),
        const SizedBox(height: TinoSpace.s8),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TinoType.corpo.withColor(c.textSecondary),
        ),
      ],
    );
  }
}
