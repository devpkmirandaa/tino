import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tino/features/shopping/application/camera_access.dart';
import 'package:tino/features/shopping/domain/no_read_clock.dart';

void main() {
  group('Escanear decide pela permissão', () {
    test('permitida abre o scanner, pedida ou não', () {
      for (final asked in [false, true]) {
        expect(
          cameraStep(PermissionStatus.granted, askedBefore: asked),
          CameraStep.scan,
        );
        expect(
          cameraStep(PermissionStatus.limited, askedBefore: asked),
          CameraStep.scan,
        );
      }
    });

    test('nunca pedida mostra a folha 14', () {
      expect(
        cameraStep(PermissionStatus.denied, askedBefore: false),
        CameraStep.ask,
      );
    });

    test('negada uma vez ou de vez mostra a folha 15', () {
      expect(
        cameraStep(PermissionStatus.denied, askedBefore: true),
        CameraStep.denied,
      );
      expect(
        cameraStep(PermissionStatus.permanentlyDenied, askedBefore: true),
        CameraStep.denied,
      );
      expect(
        cameraStep(PermissionStatus.restricted, askedBefore: false),
        CameraStep.denied,
      );
    });
  });

  group('tempo sem leitura (03c)', () {
    final t0 = DateTime(2026, 11, 7, 10);

    test('só conta depois de começar e avisa aos 8 s', () {
      final clock = NoReadClock();
      expect(clock.isDue(t0.add(const Duration(minutes: 1))), isFalse);
      clock.restart(t0);
      expect(clock.isDue(t0.add(const Duration(seconds: 7))), isFalse);
      expect(clock.isDue(t0.add(const Duration(seconds: 8))), isTrue);
    });

    test('recomeçar adia o aviso; parar desliga', () {
      final clock = NoReadClock()..restart(t0);
      clock.restart(t0.add(const Duration(seconds: 6)));
      expect(clock.isDue(t0.add(const Duration(seconds: 10))), isFalse);
      expect(clock.isDue(t0.add(const Duration(seconds: 14))), isTrue);
      clock.stop();
      expect(clock.isDue(t0.add(const Duration(seconds: 30))), isFalse);
    });
  });
}
