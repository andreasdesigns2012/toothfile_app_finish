import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Simple TouchBar implementation using platform channels for macOS
class NativeTouchBarHelper {
  static const MethodChannel _channel = MethodChannel('toothfile.touchbar');
  static Function(int)? onTabSelect;

  static Future<void> setDashboardTouchBar({
    Function(int)? onTabSelected,
    int? currentTabIndex,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      debugPrint('NativeTouchBarHelper: Not macOS, skipping TouchBar setup');
      return;
    }

    try {
      final callback = onTabSelected ?? onTabSelect;
      if (callback == null) {
        debugPrint('NativeTouchBarHelper: No callback provided');
        return;
      }

      debugPrint('NativeTouchBarHelper: Setting up native TouchBar');
      
      // Set up method call handler for TouchBar events
      _channel.setMethodCallHandler((call) async {
        debugPrint('NativeTouchBarHelper: Received method call: ${call.method}');
        if (call.method == 'touchBarTabSelected') {
          final int index = call.arguments as int;
          debugPrint('NativeTouchBarHelper: Tab selected: $index');
          callback(index);
        }
      });

      // Call native code to set up TouchBar
      await _channel.invokeMethod('setupTouchBar', {
        'tabIndex': currentTabIndex ?? 0,
        'tabs': [
          'Received',
          'Send',
          'Tracker',
          'Requests',
          'Directory',
          'Order',
          'Settings'
        ],
      });
      
      debugPrint('NativeTouchBarHelper: Native TouchBar setup complete');
    } catch (e) {
      debugPrint('NativeTouchBarHelper: Error setting up TouchBar: $e');
    }
  }

  static Future<void> updateTouchBarTab(int currentTabIndex) async {
    if (defaultTargetPlatform != TargetPlatform.macOS) return;

    try {
      await _channel.invokeMethod('updateTouchBarTab', {
        'tabIndex': currentTabIndex,
      });
    } catch (e) {
      debugPrint('NativeTouchBarHelper: Error updating TouchBar tab: $e');
    }
  }

  static Future<void> restoreDefaultTouchBar() async {
    if (defaultTargetPlatform != TargetPlatform.macOS) return;

    try {
      await _channel.invokeMethod('restoreDefaultTouchBar');
    } catch (e) {
      debugPrint('NativeTouchBarHelper: Error restoring TouchBar: $e');
    }
  }
}