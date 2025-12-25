import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:toothfile/touch_bar_helper.dart';

void main() {
  runApp(const MacOSTouchBarTestApp());
}

class MacOSTouchBarTestApp extends StatelessWidget {
  const MacOSTouchBarTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'macOS TouchBar Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MacOSTouchBarTestPage(),
    );
  }
}

class MacOSTouchBarTestPage extends StatefulWidget {
  const MacOSTouchBarTestPage({super.key});

  @override
  State<MacOSTouchBarTestPage> createState() => _MacOSTouchBarTestPageState();
}

class _MacOSTouchBarTestPageState extends State<MacOSTouchBarTestPage> {
  int _currentTab = 0;
  final List<String> _tabNames = [
    'Received Files',
    'Send Files',
    'File Tracker',
    'Requests',
    'Directory',
    'Order Form',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('MacOS TouchBar Test: initState called');
    debugPrint('Platform: ${defaultTargetPlatform}');

    // Set up TouchBar callback
    TouchBarHelper.onTabSelect = (index) {
      debugPrint('MacOS TouchBar Test: Tab selected: $index');
      setState(() {
        _currentTab = index;
      });
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('MacOS TouchBar Test: Setting initial TouchBar');
      TouchBarHelper.setDashboardTouchBar(currentTabIndex: _currentTab);
    });
  }

  @override
  void dispose() {
    TouchBarHelper.onTabSelect = null;
    super.dispose();
  }

  void _testTouchBar() {
    debugPrint('MacOS TouchBar Test: Manual TouchBar test');
    TouchBarHelper.setDashboardTouchBar(currentTabIndex: _currentTab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('macOS TouchBar Test'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Tab: ${_tabNames[_currentTab]}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'TouchBar Index: $_currentTab',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),

            // Platform info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Platform: ${defaultTargetPlatform.toString().split(".").last}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (defaultTargetPlatform == TargetPlatform.macOS)
                    const Text(
                      '✅ TouchBar should be available',
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    )
                  else
                    Text(
                      '❌ TouchBar not available on ${defaultTargetPlatform.toString().split(".").last}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Manual test button
            ElevatedButton.icon(
              onPressed: _testTouchBar,
              icon: const Icon(Icons.touch_app),
              label: const Text('Test TouchBar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tab navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentTab = (_currentTab - 1).clamp(
                        0,
                        _tabNames.length - 1,
                      );
                    });
                    TouchBarHelper.setDashboardTouchBar(
                      currentTabIndex: _currentTab,
                    );
                  },
                  child: const Text('Previous Tab'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentTab = (_currentTab + 1).clamp(
                        0,
                        _tabNames.length - 1,
                      );
                    });
                    TouchBarHelper.setDashboardTouchBar(
                      currentTabIndex: _currentTab,
                    );
                  },
                  child: const Text('Next Tab'),
                ),
              ],
            ),

            const SizedBox(height: 40),

            const Text(
              'Check the Debug Console for TouchBar logs',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                'On macOS, you should see a TouchBar with tab navigation at the bottom of your screen. '
                'If you don\'t see it, check System Preferences > Keyboard > Touch Bar shows',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
