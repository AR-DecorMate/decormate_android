package com.example.decormate_android

import com.google.ar.core.ArCoreApk
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val ARCORE_CHANNEL = "decormate/arcore"
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ARCORE_CHANNEL)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getAvailability" -> {
						val availability = ArCoreApk.getInstance().checkAvailability(this)
						result.success(
							mapOf(
								"availability" to availability.name,
								"supported" to availability.isSupported,
								"transient" to availability.isTransient,
							),
						)
					}

					else -> result.notImplemented()
				}
			}
	}
}
