import Flutter
import UIKit

public class PlatoJobsCacheManagerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "plato_jobs_cache_manager", binaryMessenger: registrar.messenger())
    let instance = PlatoJobsCacheManagerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCacheDirectory":
      getCacheDirectory(result: result)
    case "getCacheSize":
      getCacheSize(result: result)
    case "clearCache":
      clearCache(result: result)
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getCacheDirectory(result: @escaping FlutterResult) {
    do {
      let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      let platoJobsCacheDir = cacheDir.appendingPathComponent("plato_jobs_cache")
      
      if !FileManager.default.fileExists(atPath: platoJobsCacheDir.path) {
        try FileManager.default.createDirectory(at: platoJobsCacheDir, withIntermediateDirectories: true, attributes: nil)
      }
      
      result(platoJobsCacheDir.path)
    } catch {
      result(FlutterError(code: "CACHE_ERROR", message: "Failed to get cache directory", details: error.localizedDescription))
    }
  }

  private func getCacheSize(result: @escaping FlutterResult) {
    do {
      let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      let platoJobsCacheDir = cacheDir.appendingPathComponent("plato_jobs_cache")
      
      let size = try getDirectorySize(at: platoJobsCacheDir)
      result(size)
    } catch {
      result(FlutterError(code: "CACHE_ERROR", message: "Failed to get cache size", details: error.localizedDescription))
    }
  }

  private func clearCache(result: @escaping FlutterResult) {
    do {
      let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      let platoJobsCacheDir = cacheDir.appendingPathComponent("plato_jobs_cache")
      
      if FileManager.default.fileExists(atPath: platoJobsCacheDir.path) {
        try FileManager.default.removeItem(at: platoJobsCacheDir)
      }
      
      result(true)
    } catch {
      result(FlutterError(code: "CACHE_ERROR", message: "Failed to clear cache", details: error.localizedDescription))
    }
  }

  private func getDirectorySize(at url: URL) throws -> Int64 {
    var size: Int64 = 0
    let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [])
    
    while let fileURL = enumerator?.nextObject() as? URL {
      let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
      if let fileSize = resourceValues.fileSize {
        size += Int64(fileSize)
      }
    }
    
    return size
  }
}
