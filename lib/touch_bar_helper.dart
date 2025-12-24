import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:touch_bar/touch_bar.dart';

class TouchBarHelper {
  static void setupTouchBar() {
    if (defaultTargetPlatform != TargetPlatform.macOS) return;

    try {
      final touchBar = TouchBar(
        children: [
          TouchBarLabel('ToothFile', textColor: Colors.blue),
          TouchBarButton(
            label: 'Refresh',
            backgroundColor: Colors.blue,
            onClick: () {
              debugPrint('Refresh clicked from Touch Bar');
            },
          ),
        ],
      );

      // setTouchBar is the method to activate it
      setTouchBar(touchBar);
    } catch (e) {
      debugPrint('Error setting up Touch Bar: $e');
    }
  }
}
