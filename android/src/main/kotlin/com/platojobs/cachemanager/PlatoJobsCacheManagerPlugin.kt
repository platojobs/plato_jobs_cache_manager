package com.platojobs.cachemanager

import android.content.Context
import android.os.Environment
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/** PlatoJobsCacheManagerPlugin */
class PlatoJobsCacheManagerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "plato_jobs_cache_manager")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getCacheDirectory" -> {
                try {
                    val cacheDir = context.cacheDir
                    val platoJobsCacheDir = File(cacheDir, "plato_jobs_cache")
                    if (!platoJobsCacheDir.exists()) {
                        platoJobsCacheDir.mkdirs()
                    }
                    result.success(platoJobsCacheDir.absolutePath)
                } catch (e: Exception) {
                    result.error("CACHE_ERROR", "Failed to get cache directory", e.message)
                }
            }
            "getCacheSize" -> {
                try {
                    val cacheDir = context.cacheDir
                    val platoJobsCacheDir = File(cacheDir, "plato_jobs_cache")
                    val size = getDirectorySize(platoJobsCacheDir)
                    result.success(size)
                } catch (e: Exception) {
                    result.error("CACHE_ERROR", "Failed to get cache size", e.message)
                }
            }
            "clearCache" -> {
                try {
                    val cacheDir = context.cacheDir
                    val platoJobsCacheDir = File(cacheDir, "plato_jobs_cache")
                    deleteDirectory(platoJobsCacheDir)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("CACHE_ERROR", "Failed to clear cache", e.message)
                }
            }
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getDirectorySize(directory: File): Long {
        var size = 0L
        if (directory.exists() && directory.isDirectory) {
            directory.listFiles()?.forEach { file ->
                size += if (file.isDirectory) {
                    getDirectorySize(file)
                } else {
                    file.length()
                }
            }
        }
        return size
    }

    private fun deleteDirectory(directory: File): Boolean {
        if (directory.exists() && directory.isDirectory) {
            directory.listFiles()?.forEach { file ->
                if (file.isDirectory) {
                    deleteDirectory(file)
                } else {
                    file.delete()
                }
            }
        }
        return directory.delete()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
