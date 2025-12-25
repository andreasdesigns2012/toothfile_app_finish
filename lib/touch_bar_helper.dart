import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:touch_bar/touch_bar.dart';

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

  static int get currentTabIndex => _currentTabIndex;

  static void setCurrentTabIndex(int index) {
    _currentTabIndex = index;
    debugPrint('TouchBarHelper: Set current tab index to $index');
  }

  static void setDashboardTouchBar({
    Function(int)? onTabSelected,
    List<TouchBarItem>? extraItems,
    int? currentTabIndex,
  }) {
    debugPrint('TouchBarHelper: setDashboardTouchBar called');
    debugPrint('Platform: ${defaultTargetPlatform}');
    debugPrint('Is macOS: ${defaultTargetPlatform == TargetPlatform.macOS}');

    // Only proceed on macOS
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      debugPrint('TouchBarHelper: Not macOS, skipping TouchBar setup');
      return;
    }

    try {
      final callback = onTabSelected ?? onTabSelect;
      if (callback == null) {
        debugPrint('TouchBarHelper: No callback provided');
        return;
      }

      // Store the current tab index for future reference
      if (currentTabIndex != null) {
        _currentTabIndex = currentTabIndex;
      }

      debugPrint('TouchBarHelper: Creating TouchBar with tab navigation');
      debugPrint('TouchBarHelper: Current tab index: $_currentTabIndex');

      // Create the TouchBar with tab navigation
      final touchBar = TouchBar(
        children: [
          TouchBarLabel('ToothFile', textColor: Colors.blue),
          TouchBarScrubber(
            children: [
              TouchBarScrubberLabel('📥 Received'),
              TouchBarScrubberLabel('📤 Send'),
              TouchBarScrubberLabel('📊 Tracker'),
              TouchBarScrubberLabel('🔔 Requests'),
              TouchBarScrubberLabel('👥 Directory'),
              TouchBarScrubberLabel('📋 Order'),
              TouchBarScrubberLabel('⚙️ Settings'),
            ],
            onSelect: (index) {
              debugPrint('TouchBarHelper: Tab selected: $index');
              callback(index);
            },
            selectedStyle: ScrubberSelectionStyle.outlineOverlay,
            mode: ScrubberMode.fixed,
            showArrowButtons: true,
          ),
          if (extraItems != null && extraItems.isNotEmpty) ...[
            TouchBarSpace.flexible(),
            ...extraItems,
          ],
        ],
      );

      debugPrint('TouchBarHelper: Setting TouchBar');
      setTouchBar(touchBar);
      debugPrint('TouchBarHelper: TouchBar set successfully');
    } catch (e, stackTrace) {
      debugPrint('TouchBarHelper: Error setting dashboard Touch Bar: $e');
      debugPrint('TouchBarHelper: Stack trace: $stackTrace');

      // Try to set a minimal TouchBar as fallback
      try {
        debugPrint('TouchBarHelper: Trying fallback TouchBar');
        final fallbackTouchBar = TouchBar(
          children: [TouchBarLabel('ToothFile')],
        );
        setTouchBar(fallbackTouchBar);
        debugPrint('TouchBarHelper: Fallback TouchBar set successfully');
      } catch (fallbackError) {
        debugPrint('TouchBarHelper: Fallback also failed: $fallbackError');
      }
    }
  }

  static void setPopupTouchBar({
    required BuildContext? context,
    required List<TouchBarHelperAction> actions,
  }) {
    debugPrint('TouchBarHelper: setPopupTouchBar called');
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      debugPrint('TouchBarHelper: Not macOS, skipping popup TouchBar');
      return;
    }

    try {
      final touchBar = TouchBar(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            TouchBarButton(
              label: actions[i].label,
              backgroundColor: actions[i].isDestructive
                  ? Colors.red
                  : actions[i].isPrimary
                  ? Colors.blue
                  : Colors.grey,
              onClick: actions[i].action,
            ),
            if (i < actions.length - 1) TouchBarSpace.flexible(),
          ],
        ],
      );

      setTouchBar(touchBar);
      debugPrint('TouchBarHelper: Popup TouchBar set successfully');
    } catch (e) {
      debugPrint('TouchBarHelper: Error setting popup Touch Bar: $e');
    }
  }

  static void restoreDefaultTouchBar() {
    debugPrint('TouchBarHelper: restoreDefaultTouchBar called');
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      debugPrint('TouchBarHelper: Not macOS, skipping restore');
      return;
    }

    try {
      final touchBar = TouchBar(children: [TouchBarLabel('ToothFile')]);
      setTouchBar(touchBar);
      debugPrint('TouchBarHelper: Default TouchBar restored');
    } catch (e) {
      debugPrint('TouchBarHelper: Error restoring Touch Bar: $e');
    }
  }
}
