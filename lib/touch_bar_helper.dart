import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'touch_bar_widget.dart';

class TouchBarHelperAction {
  final String label;
  final VoidCallback action;
  final bool isDestructive;
  final bool isPrimary;

  TouchBarHelperAction({
    required this.label,
    required this.action,
    this.isDestructive = false,
    this.isPrimary = false,
  });
}

class TouchBarHelper {
  static Function(int)? onTabSelect;
  static int _currentTabIndex = 0;
  static TouchBarManager _touchBarManager = TouchBarManager();

  static int get currentTabIndex => _currentTabIndex;

  static void setCurrentTabIndex(int index) {
    _currentTabIndex = index;
    debugPrint('TouchBarHelper: Set current tab index to $index');
  }

  /// Creates a TouchBar widget that can be embedded in the UI
  static Widget createTouchBarWidget() {
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      debugPrint('TouchBarHelper: Not macOS, returning empty widget');
      return const SizedBox.shrink();
    }

    debugPrint('TouchBarHelper: Creating TouchBar widget');

    return TouchBarWidget(
      currentIndex: _currentTabIndex,
      onTabSelected: (index) {
        debugPrint('TouchBarHelper: Tab selected: $index');
        if (onTabSelect != null) {
          onTabSelect!(index);
        }
      },
      tabLabels: _touchBarManager.tabLabels,
      tabIcons: _touchBarManager.tabIcons,
    );
  }

  /// Sets up the TouchBar (now just updates the internal state)
  static void setDashboardTouchBar({
    Function(int)? onTabSelected,
    List<dynamic>? extraItems,
    int? currentTabIndex,
  }) {
    debugPrint('TouchBarHelper: setDashboardTouchBar called');
    debugPrint('Platform: ${defaultTargetPlatform}');
    debugPrint('Is macOS: ${defaultTargetPlatform == TargetPlatform.macOS}');

    if (defaultTargetPlatform != TargetPlatform.macOS) {
      debugPrint('TouchBarHelper: Not macOS, skipping TouchBar setup');
      return;
    }

    try {
      // Store the current tab index for future reference
      if (currentTabIndex != null) {
        _currentTabIndex = currentTabIndex;
      }

      // Set the callback
      if (onTabSelected != null) {
        onTabSelect = onTabSelected;
      }

      debugPrint(
        'TouchBarHelper: TouchBar state updated for tab $_currentTabIndex',
      );
      debugPrint(
        'TouchBarHelper: TouchBar widget will be available via createTouchBarWidget()',
      );
    } catch (e) {
      debugPrint('TouchBarHelper: Error updating TouchBar state: $e');
    }
  }

  /// Sets popup TouchBar (deprecated - use regular TouchBar)
  static void setPopupTouchBar({
    required BuildContext? context,
    required List<TouchBarHelperAction> actions,
  }) {
    debugPrint('TouchBarHelper: setPopupTouchBar called (deprecated)');
    // This is now handled by the regular TouchBar widget
  }

  /// Restores default TouchBar state
  static void restoreDefaultTouchBar() {
    debugPrint('TouchBarHelper: restoreDefaultTouchBar called');
    _currentTabIndex = 0;
    if (onTabSelect != null) {
      onTabSelect!(0);
    }
  }
}
