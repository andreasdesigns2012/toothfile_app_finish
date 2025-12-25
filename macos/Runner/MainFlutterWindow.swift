import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Register our custom TouchBar plugin
    TouchBarPlugin.register(with: flutterViewController)

    super.awakeFromNib()
  }
  
  // Override to provide custom TouchBar
  override func makeTouchBar() -> NSTouchBar? {
    let touchBar = NSTouchBar()
    touchBar.defaultItemIdentifiers = [.tabScrubber, .flexibleSpace, .appName]
    touchBar.delegate = self
    return touchBar
  }
}

// TouchBar delegate extension
extension MainFlutterWindow: NSTouchBarDelegate {
  func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
    switch identifier {
    case .tabScrubber:
      let scrubber = NSScrubber()
      scrubber.mode = .fixed
      scrubber.selectionOverlayStyle = .outlineOverlay
      scrubber.showsArrowButtons = true
      
      let item = NSCustomTouchBarItem(identifier: identifier)
      item.view = scrubber
      item.customizationLabel = "Tab Navigation"
      
      return item
      
    case .appName:
      let item = NSTextTouchBarItem(identifier: identifier)
      item.textColor = NSColor.systemBlue
      item.string = "ToothFile"
      item.customizationLabel = "App Name"
      return item
      
    default:
      return nil
    }
  }
}

// TouchBar item identifiers
extension NSTouchBarItem.Identifier {
  static let tabScrubber = NSTouchBarItem.Identifier("com.toothfile.touchbar.tabScrubber")
  static let appName = NSTouchBarItem.Identifier("com.toothfile.touchbar.appName")
  static let flexibleSpace = NSTouchBarItem.Identifier("NSTouchBarItemIdentifierFlexibleSpace")
}
