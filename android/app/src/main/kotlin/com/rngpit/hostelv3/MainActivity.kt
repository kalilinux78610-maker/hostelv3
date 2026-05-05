package com.rngpit.hostelv3

import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        // Enable edge-to-edge for Android 15+ compatibility
        // This ensures proper inset handling and removes deprecated Window color APIs
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
