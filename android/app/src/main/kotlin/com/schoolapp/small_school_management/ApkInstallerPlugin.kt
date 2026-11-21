package com.schoolapp.small_school_management

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * APK install karne ke liye native bridge.
 *
 * Dart side se yeh seedha nahi ho sakta kyunke Android 7+ pe file:// URI share
 * karna mana hai (FileUriExposedException), aur install intent ko content:// URI
 * + read-permission grant chahiye hota hai.
 *
 * Methods:
 *   canRequestInstall   -> Android 8+ pe "unknown sources" ki ijazat hai?
 *   openInstallSettings -> us ijazat ka settings page kholo
 *   installApk(path)    -> downloaded APK ka installer khole
 */
class ApkInstallerPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.schoolapp.small_school_management/installer"
        const val AUTHORITY = "com.schoolapp.small_school_management.fileprovider"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canRequestInstall" -> result.success(canRequestInstall())
            "openInstallSettings" -> result.success(openInstallSettings())
            "installApk" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("ARG_MISSING", "path argument nahi mila", null)
                } else {
                    installApk(path, result)
                }
            }
            else -> result.notImplemented()
        }
    }

    /** Android 8 (API 26) se pehle yeh permission maujood hi nahi thi. */
    private fun canRequestInstall(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun openInstallSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${context.packageName}")
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun installApk(path: String, result: MethodChannel.Result) {
        try {
            val file = File(path)
            if (!file.exists() || file.length() == 0L) {
                result.error("FILE_MISSING", "APK file nahi mili: $path", null)
                return
            }

            val uri: Uri = FileProvider.getUriForFile(context, AUTHORITY, file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                // Iske baghair installer ko file parhne ki ijazat nahi milti.
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: IllegalArgumentException) {
            // file_paths.xml mein yeh path cover nahi.
            result.error(
                "PATH_NOT_SHARED",
                "APK us folder mein nahi jo FileProvider share karta hai: ${e.message}",
                null
            )
        } catch (e: Exception) {
            result.error("INSTALL_FAILED", e.message, null)
        }
    }
}
