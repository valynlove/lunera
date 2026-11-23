package com.example.ritme

import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.net.Uri
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.ritme/app_utils"
    private val toneLock = Any()
    private var activeToneTrack: AudioTrack? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val url = call.argument<String>("url")?.trim()
                    if (!url.isNullOrEmpty()) {
                        val uri = Uri.parse(url)
                        val scheme = uri.scheme?.lowercase()
                        val host = uri.host?.lowercase() ?: ""
                        val trustedHost = host == "github.com" ||
                            host.endsWith(".github.com") ||
                            host == "githubusercontent.com" ||
                            host.endsWith(".githubusercontent.com")
                        if (scheme == "https" && trustedHost) {
                            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.error("UNTRUSTED_URL", "Only HTTPS GitHub URLs are allowed", null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL is null or empty", null)
                    }
                }
                "setSecureScreen" -> {
                    val secure = call.argument<Boolean>("secure") ?: false
                    if (secure) {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                "playReferenceTone" -> {
                    val hz = (call.argument<Number>("hz")?.toDouble() ?: 175.0).coerceIn(65.0, 440.0)
                    val durationMs = (call.argument<Number>("durationMs")?.toInt() ?: 1400).coerceIn(200, 2500)
                    result.success(playGentleSineTone(hz, durationMs))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playGentleSineTone(hz: Double, durationMs: Int): Boolean {
        return try {
            val sampleRate = 44100
            val count = ((sampleRate * durationMs) / 1000.0).roundToInt().coerceAtLeast(1)
            val fadeSamples = min(count / 4, (sampleRate * 0.06).roundToInt().coerceAtLeast(1))
            val pcm = ShortArray(count)
            val amplitude = 0.16 * Short.MAX_VALUE

            for (i in 0 until count) {
                var env = 1.0
                if (i < fadeSamples) {
                    env = 0.5 * (1.0 - cos(PI * i / fadeSamples))
                } else if (i >= count - fadeSamples) {
                    val rem = count - 1 - i
                    env = 0.5 * (1.0 - cos(PI * rem / fadeSamples))
                }
                val sample = sin(2.0 * PI * hz * i / sampleRate) * amplitude * env
                pcm[i] = sample.roundToInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
            }

            val bufferBytes = pcm.size * 2
            val track = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .setBufferSizeInBytes(bufferBytes)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                AudioTrack(
                    AudioManager.STREAM_MUSIC,
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferBytes,
                    AudioTrack.MODE_STATIC
                )
            }

            track.write(pcm, 0, pcm.size)

            synchronized(toneLock) {
                stopActiveToneLocked()
                activeToneTrack = track
                track.play()
            }

            thread(isDaemon = true) {
                try {
                    Thread.sleep(durationMs.toLong() + 80L)
                } catch (_: InterruptedException) {
                    return@thread
                }
                synchronized(toneLock) {
                    if (activeToneTrack === track) {
                        stopActiveToneLocked()
                    } else {
                        runCatching {
                            track.stop()
                            track.release()
                        }
                    }
                }
            }
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun stopActiveToneLocked() {
        val current = activeToneTrack ?: return
        activeToneTrack = null
        runCatching {
            if (current.playState == AudioTrack.PLAYSTATE_PLAYING) {
                current.stop()
            }
            current.release()
        }
    }

    override fun onDestroy() {
        synchronized(toneLock) {
            stopActiveToneLocked()
        }
        super.onDestroy()
    }
}
