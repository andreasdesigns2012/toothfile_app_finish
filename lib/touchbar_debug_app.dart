import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:toothfile/touch_bar_helper.dart';

void main() {
  runApp(const TouchBarDebugApp());
}

class TouchBarDebugApp extends StatelessWidget {
  const TouchBarDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TouchBar Debug',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TouchBarDebugPage(),
    );
  }
}

class TouchBarDebugPage extends StatefulWidget {
  const TouchBarDebugPage({super.key});

  @override
  State<TouchBarDebugPage> createState() => _TouchBarDebugPageState();
}

class _TouchBarDebugPageState extends State<TouchBarDebugPage> {
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

  String _debugLog = '';

  @override
  void initState() {
    super.initState();
    _log('=== TouchBar Debug App Started ===');
    _log('Platform: ${defaultTargetPlatform}');
    _log('Is macOS: ${defaultTargetPlatform == TargetPlatform.macOS}');

    // Set up TouchBar callback
    TouchBarHelper.onTabSelect = (index) {
      _log('TouchBar tab selected: $index');
      setState(() {
        _currentTab = index;
      });
    };

    // Initial TouchBar setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _log('Setting up initial TouchBar...');
      TouchBarHelper.setDashboardTouchBar(currentTabIndex: _currentTab);
      _log('Initial TouchBar setup complete');
    });
  }

  @override
  void dispose() {
    TouchBarHelper.onTabSelect = null;
    super.dispose();
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    setState(() {
      _debugLog += '[$timestamp] $message\n';
    });
    debugPrint('TouchBarDebug: $message');
  }

  void _testTouchBar() {
    _log('Manual TouchBar test initiated');
    TouchBarHelper.setDashboardTouchBar(currentTabIndex: _currentTab);
    _log('TouchBar updated for tab $_currentTab');
  }

  void _clearLog() {
    setState(() {
      _debugLog = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TouchBar Debug App'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testTouchBar,
            tooltip: 'Test TouchBar',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLog,
            tooltip: 'Clear Log',
          ),
        ],
      ),
      body: Column(
        children: [
          // Current tab display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                Text(
                  'Current Tab: ${_tabNames[_currentTab]}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Index: $_currentTab',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Platform: ${defaultTargetPlatform.toString().split(".").last}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (defaultTargetPlatform == TargetPlatform.macOS)
                  const Text(
                    '✅ TouchBar should be available',
                    style: TextStyle(fontSize: 14, color: Colors.green),
                  )
                else
                  Text(
                    '❌ TouchBar not available on ${defaultTargetPlatform.toString().split(".").last}',
                    style: const TextStyle(fontSize: 14, color: Colors.orange),
                  ),
              ],
            ),
          ),

          // Tab navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentTab = (_currentTab - 1).clamp(
                        0,
                        _tabNames.length - 1,
                      );
                    });
                    _log('Switched to previous tab: $_currentTab');
                    TouchBarHelper.setDashboardTouchBar(
                      currentTabIndex: _currentTab,
                    );
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentTab = (_currentTab + 1).clamp(
                        0,
                        _tabNames.length - 1,
                      );
                    });
                    _log('Switched to next tab: $_currentTab');
                    TouchBarHelper.setDashboardTouchBar(
                      currentTabIndex: _currentTab,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),

          // Quick tab buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(_tabNames.length, (index) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentTab = index;
                    });
                    _log('Switched to tab: $index (${_tabNames[index]})');
                    TouchBarHelper.setDashboardTouchBar(
                      currentTabIndex: _currentTab,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentTab == index
                        ? Colors.blue
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(_tabNames[index]),
                );
              }),
            ),
          ),

          const Divider(),

          // Debug log
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Debug Log',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_debugLog.split('\n').length - 1} lines',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _debugLog.isEmpty
                              ? 'No debug output yet...'
                              : _debugLog,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: const Text(
              'Instructions:\n'
              '1. Run this app on a macOS device with TouchBar support\n'
              '2. Check the debug log for TouchBar setup messages\n'
              '3. Look for a TouchBar with tab navigation at the bottom of your screen\n'
              '4. If TouchBar doesn\'t appear, check System Preferences > Keyboard > Touch Bar shows\n'
              '5. Try switching tabs using the buttons above and watch the TouchBar update',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
