import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Required by flutter_local_notifications so foreground notifications
    // are displayed instead of being silently dropped (#312).
    // FlutterAppDelegate already conforms to UNUserNotificationCenterDelegate,
    // so the direct assignment type-checks at compile time. The previous
    // shape used `self as? UNUserNotificationCenterDelegate`, which would
    // silently resolve to nil (and drop foreground notifications) if a
    // future Flutter / plugin reorganisation ever lost the conformance.
    // With the unconditional assignment, that scenario surfaces as a
    // compile error instead.
    UNUserNotificationCenter.current().delegate = self
    // Exclude the documents folder from iCloud backup.
    try! setExcludeFromiCloudBackup(isExcluded: true)
    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    registerSfSymbolChannel(self)
    return launched
  }
}

/// Renders an SF Symbol to PNG so the Flutter home card can show the same
/// `fork.knife` glyph as the widget. The glyph is black on a clear
/// background; Flutter tints it.
private func registerSfSymbolChannel(_ appDelegate: FlutterAppDelegate) {
  guard let registrar = appDelegate.registrar(forPlugin: "SfSymbolIcon") else {
    return
  }
  let channel = FlutterMethodChannel(
    name: "com.opennutritracker/sf_symbol",
    binaryMessenger: registrar.messenger()
  )
  channel.setMethodCallHandler { call, result in
    guard call.method == "png",
      let args = call.arguments as? [String: Any],
      let name = args["name"] as? String
    else {
      result(FlutterMethodNotImplemented)
      return
    }
    let pointSize = (args["pointSize"] as? NSNumber)?.doubleValue ?? 20
    let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
    guard let image = UIImage(systemName: name, withConfiguration: config)?
      .withTintColor(.black, renderingMode: .alwaysOriginal),
      let data = image.pngData()
    else {
      result(
        FlutterError(
          code: "missing",
          message: "SF Symbol \(name) is not available",
          details: nil
        )
      )
      return
    }
    result(FlutterStandardTypedData(bytes: data))
  }
}

private func setExcludeFromiCloudBackup(isExcluded: Bool) throws {
    var fileOrDirectoryURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = isExcluded
    try fileOrDirectoryURL.setResourceValues(values)
}
