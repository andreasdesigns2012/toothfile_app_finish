import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:touch_bar/touch_bar.dart';

class TouchBarHelper {
  static void setDashboardTouchBar({required Function(int) onTabSelected}) {
    if (defaultTargetPlatform != TargetPlatform.macOS) return;

    try {
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
              onTabSelected(index);
            },
            selectedStyle: ScrubberSelectionStyle.outlineOverlay,
            mode: ScrubberMode.fixed,
            showArrowButtons: true,
          ),
        ],
      );

      setTouchBar(touchBar);
    } catch (e) {
      debugPrint('Error setting dashboard Touch Bar: $e');
    }
  }

  static void setPopupTouchBar({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm',
    Color confirmColor = Colors.blue,
  }) {
    if (defaultTargetPlatform != TargetPlatform.macOS) return;

    try {
      final touchBar = TouchBar(
        children: [
          TouchBarButton(
            label: 'Cancel',
            backgroundColor: Colors.grey,
            onClick: onCancel,
          ),
          TouchBarSpace.flexible(),
          TouchBarButton(
            label: confirmLabel,
            backgroundColor: confirmColor,
            onClick: onConfirm,
          ),
        ],
      );

      setTouchBar(touchBar);
    } catch (e) {
      debugPrint('Error setting popup Touch Bar: $e');
    }
  }

  static void restoreDefaultTouchBar() {
    if (defaultTargetPlatform != TargetPlatform.macOS) return;

    // You can define a default touch bar or just clear it
    // For now, let's set it to the dashboard one if we had context,
    // but simpler is to just have a generic default.
    // Or we can leave it empty.
    try {
      final touchBar = TouchBar(children: [TouchBarLabel('ToothFile')]);
      setTouchBar(touchBar);
    } catch (e) {
      debugPrint('Error restoring Touch Bar: $e');
    }
  }
}
