package com.devsecure.mobile

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.content.Intent


class MainActivity : FlutterActivity() {
    private val CHANNEL = "clipboard_image"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "copyImageToClipboard") {
                val imagePath: String? = call.argument("path")
                if (imagePath != null) {
                        val file = File(imagePath)
                        if (!file.exists() || !file.canRead()) {
                            result.error("UNAVAILABLE", "Image file not found or cannot be read.", null)
                            return@setMethodCallHandler
                        }

                        val uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )
                        println("Oluşturulan URI: $uri")

                        // Grant temporary read permission on the URI to all recipients (via the clipboard).
                        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        val clip = ClipData.newUri(contentResolver, "Image", uri)

                        // This is the correct way to grant the permission using the intent flag:
                        context.grantUriPermission(context.packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

                        clipboard.setPrimaryClip(clip)





                        result.success("Image copied to clipboard")
                } else {
                    result.error("UNAVAILABLE", "Image path not found.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
