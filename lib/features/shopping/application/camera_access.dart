import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../onboarding/data/onboarding_preference.dart';

/// O que o toque em "Escanear" faz (design/specs/telas-complementares.md ·
/// 14 e 15).
enum CameraStep {
  /// Permissão dada: abre o scanner.
  scan,

  /// Nunca pedida: folha 14 antes do diálogo do sistema.
  ask,

  /// Negada (uma vez ou de vez): folha 15, sem insistir com o sistema.
  denied,
}

/// No Android, "ainda não pedida" e "negada uma vez" têm o mesmo status;
/// [askedBefore] separa os dois.
CameraStep cameraStep(PermissionStatus status, {required bool askedBefore}) {
  if (status.isGranted || status.isLimited) return CameraStep.scan;
  if (status.isDenied && !askedBefore) return CameraStep.ask;
  return CameraStep.denied;
}

final cameraAccessProvider = Provider<CameraAccess>((ref) => CameraAccess(ref));

class CameraAccess {
  CameraAccess(this._ref);
  final Ref _ref;

  /// Guardado no aparelho ao pedir pela primeira vez.
  static const askedKey = 'camera_asked';

  Future<CameraStep> step() async {
    final status = await Permission.camera.status;
    final asked =
        await _ref.read(preferencesProvider).getBool(askedKey) ?? false;
    return cameraStep(status, askedBefore: asked);
  }

  /// Diálogo do sistema; verdadeiro se a pessoa permitiu.
  Future<bool> request() async {
    await _ref.read(preferencesProvider).setBool(askedKey, true);
    final status = await Permission.camera.request();
    return status.isGranted || status.isLimited;
  }

  /// Ajustes do Tino no sistema, para liberar a câmera.
  Future<void> openSettings() => openAppSettings();
}
