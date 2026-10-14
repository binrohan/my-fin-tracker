package com.myfin.my_fin_tracker

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity so the fingerprint prompt (local_auth) can be shown.
class MainActivity : FlutterFragmentActivity() {
    private var pendingPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Bank and bKash messages for SMS suggestions. Read only, on request.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "myfin/sms").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(granted())
                "requestPermission" -> {
                    if (granted()) {
                        result.success(true)
                    } else {
                        pendingPermission?.success(false)
                        pendingPermission = result
                        requestPermissions(arrayOf(Manifest.permission.READ_SMS), SMS_REQUEST)
                    }
                }
                "inbox" -> {
                    if (!granted()) {
                        result.success(emptyList<Map<String, Any>>())
                    } else {
                        val since = (call.argument<Number>("since") ?: 0).toLong()
                        result.success(readInbox(since))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun granted() = checkSelfPermission(Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED

    private fun readInbox(since: Long): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        contentResolver.query(
            Uri.parse("content://sms/inbox"),
            arrayOf("address", "body", "date"),
            "date >= ?",
            arrayOf(since.toString()),
            "date DESC",
        )?.use { cursor ->
            while (cursor.moveToNext() && messages.size < 1000) {
                messages.add(
                    mapOf(
                        "sender" to (cursor.getString(0) ?: ""),
                        "body" to (cursor.getString(1) ?: ""),
                        "date" to cursor.getLong(2),
                    ),
                )
            }
        }
        return messages
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_REQUEST) {
            pendingPermission?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
            pendingPermission = null
        }
    }

    companion object {
        private const val SMS_REQUEST = 4127
    }
}
