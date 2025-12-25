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

  static void setDashboardTouchBar({
    Function(int)? onTabSelected,
    List<TouchBarItem>? extraItems,
  }) {
    if (defaultTargetPlatform != TargetPlatform.macOS) return;

    try {
      final callback = onTabSelected ?? onTabSelect;
      if (callback == null) return;

      final touchBar = TouchBar(
        children: [
          TouchBarLabel('Dashboard', textColor: Colors.blue),
          TouchBarScrubber(
            children: [
              TouchBarScrubberLabel('Received'),
              TouchBarScrubberLabel('Send'),
              TouchBarScrubberLabel('Tracker'),
              TouchBarScrubberLabel('Requests'),
              TouchBarScrubberLabel('Directory'),
              TouchBarScrubberLabel('Order'),
              TouchBarScrubberLabel('Settings'),
            ],
            onSelect: (index) {
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

      setTouchBar(touchBar);
    } catch (e) {
      debugPrint('Error setting dashboard Touch Bar: $e');
    }
  }

  static void setPopupTouchBar({
    required BuildContext? context,
    required List<TouchBarHelperAction> actions,
  }) {
    if (defaultTargetPlatform != TargetPlatform.macOS) return;

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
    } catch (e) {
      debugPrint('Error setting popup Touch Bar: $e');
    }
  }

  static void restoreDefaultTouchBar() {
    if (defaultTargetPlatform != TargetPlatform.macOS) return;

    try {
      final touchBar = TouchBar(children: [TouchBarLabel('ToothFile')]);
      setTouchBar(touchBar);
    } catch (e) {
      debugPrint('Error restoring Touch Bar: $e');
    }
  }
}
