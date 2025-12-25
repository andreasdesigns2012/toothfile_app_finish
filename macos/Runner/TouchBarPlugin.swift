import Cocoa
import FlutterMacOS

public class TouchBarPlugin: NSObject, FlutterPlugin {
  private var touchBar: NSTouchBar?
  private var tabSelectionHandler: ((Int) -> Void)?
  private var currentTabIndex: Int = 0
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "toothfile.touchbar", binaryMessenger: registrar.messenger)
    let instance = TouchBarPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setupTouchBar":
      if let args = call.arguments as? [String: Any],
         let tabs = args["tabs"] as? [String],
         let tabIndex = args["tabIndex"] as? Int {
        setupTouchBar(tabs: tabs, currentTabIndex: tabIndex)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for setupTouchBar", details: nil))
      }
      
    case "updateTouchBarTab":
      if let args = call.arguments as? [String: Any],
         let tabIndex = args["tabIndex"] as? Int {
        updateTouchBarTab(index: tabIndex)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for updateTouchBarTab", details: nil))
      }
      
    case "restoreDefaultTouchBar":
      restoreDefaultTouchBar()
      result(nil)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func setupTouchBar(tabs: [String], currentTabIndex: Int) {
    self.currentTabIndex = currentTabIndex
    
    let touchBar = NSTouchBar()
    touchBar.delegate = self
    touchBar.defaultItemIdentifiers = [.tabScrubber, .flexibleSpace, .appName]
    
    self.touchBar = touchBar
    
    // Set the touch bar for the main window
    if let window = NSApplication.shared.mainWindow {
      window.touchBar = touchBar
      debugPrint("TouchBarPlugin: TouchBar set for main window")
    } else {
      debugPrint("TouchBarPlugin: No main window found")
    }
  }
  
  private func updateTouchBarTab(index: Int) {
    self.currentTabIndex = index
    // Force refresh of the touch bar
    if let window = NSApplication.shared.mainWindow {
      window.touchBar = nil
      window.touchBar = self.touchBar
      debugPrint("TouchBarPlugin: TouchBar refreshed for tab \(index)")
    }
  }
  
  private func restoreDefaultTouchBar() {
    if let window = NSApplication.shared.mainWindow {
      window.touchBar = nil
      debugPrint("TouchBarPlugin: TouchBar restored to default")
    }
  }
  
  func setTabSelectionHandler(_ handler: @escaping (Int) -> Void) {
    self.tabSelectionHandler = handler
  }
}

extension TouchBarPlugin: NSTouchBarDelegate {
  public func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
    switch identifier {
    case .tabScrubber:
      let scrubber = NSScrubber()
      scrubber.mode = .fixed
      scrubber.selectionOverlayStyle = .outlineOverlay
      scrubber.showsArrowButtons = true
      
      let item = NSCustomTouchBarItem(identifier: identifier)
      item.view = scrubber
      item.customizationLabel = "Tab Navigation"
      
      // Setup scrubber data source and delegate
      scrubber.dataSource = self
      scrubber.delegate = self
      
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

extension TouchBarPlugin: NSScrubberDataSource {
  public func numberOfItems(for scrubber: NSScrubber) -> Int {
    return 7 // Number of tabs
  }
  
  public func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
    let itemView = NSScrubberTextItemView()
    
    let tabNames = ["Received", "Send", "Tracker", "Requests", "Directory", "Order", "Settings"]
    itemView.textField?.stringValue = tabNames[index]
    
    if index == currentTabIndex {
      itemView.textField?.textColor = NSColor.systemBlue
      itemView.textField?.font = NSFont.boldSystemFont(ofSize: 14)
    } else {
      itemView.textField?.textColor = NSColor.labelColor
      itemView.textField?.font = NSFont.systemFont(ofSize: 14)
    }
    
    return itemView
  }
}

extension TouchBarPlugin: NSScrubberDelegate {
  public func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
    debugPrint("TouchBarPlugin: Tab selected: \(selectedIndex)")
    
    // Update current tab
    currentTabIndex = selectedIndex
    
    // Notify Flutter
    if let channel = FlutterMethodChannel(name: "toothfile.touchbar", binaryMessenger: FlutterMethodChannel(name: "toothfile.touchbar", binaryMessenger: FlutterViewController().binaryMessenger).binaryMessenger) {
      channel.invokeMethod("touchBarTabSelected", arguments: selectedIndex)
    }
    
    // Refresh the scrubber to show selection
    scrubber.reloadData()
  }
}

// TouchBar item identifiers
extension NSTouchBarItem.Identifier {
  static let tabScrubber = NSTouchBarItem.Identifier("com.toothfile.touchbar.tabScrubber")
  static let appName = NSTouchBarItem.Identifier("com.toothfile.touchbar.appName")
  static let flexibleSpace = NSTouchBarItem.Identifier("NSTouchBarItemIdentifierFlexibleSpace")
}