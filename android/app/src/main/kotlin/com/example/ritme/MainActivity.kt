package com.example.ritme

import android.content.Intent
import android.net.Uri
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.ritme/app_utils"

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
                else -> result.notImplemented()
            }
        }
    }
}
