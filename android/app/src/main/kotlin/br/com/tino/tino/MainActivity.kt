package br.com.tino.tino

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Vibração direta (TinoHaptics): não depende da "vibração ao tocar"
        // do Android. Uso de mídia: vibra também no modo silencioso.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tino/vibration")
            .setMethodCallHandler { call, result ->
                val timings = call.argument<List<Int>>("timings")
                val amplitudes = call.argument<List<Int>>("amplitudes")
                if (timings == null || amplitudes == null || timings.size != amplitudes.size) {
                    result.error("args", "timings e amplitudes do mesmo tamanho", null)
                } else {
                    result.success(
                        vibrate(timings.map { it.toLong() }.toLongArray(), amplitudes.toIntArray())
                    )
                }
            }
    }

    private fun vibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                ?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    /** Forma de onda: tempos alternando pausa e pulso (ms), intensidade 0–255. */
    private fun vibrate(timings: LongArray, amplitudes: IntArray): Boolean {
        val v = vibrator() ?: return false
        if (!v.hasVibrator()) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            v.vibrate(timings, -1)
            return true
        }
        // Sem controle de intensidade, só a duração diferencia os padrões.
        val amps = if (v.hasAmplitudeControl()) {
            amplitudes
        } else {
            IntArray(amplitudes.size) {
                if (amplitudes[it] > 0) VibrationEffect.DEFAULT_AMPLITUDE else 0
            }
        }
        val effect = VibrationEffect.createWaveform(timings, amps, -1)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            v.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_MEDIA))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(
                effect,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
        }
        return true
    }
}
