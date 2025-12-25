import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:toothfile/touch_bar_helper.dart';

void main() {
  runApp(const TouchBarTestApp());
}

class TouchBarTestApp extends StatelessWidget {
  const TouchBarTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TouchBar Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TouchBarTestPage(),
    );
  }
}

class TouchBarTestPage extends StatefulWidget {
  const TouchBarTestPage({super.key});

  @override
  State<TouchBarTestPage> createState() => _TouchBarTestPageState();
}

class _TouchBarTestPageState extends State<TouchBarTestPage> {
  int _currentTab = 0;
  final List<String> _tabNames = [
    'Received Files',
    'Send Files', 
    'File Tracker',
    'Requests',
    'Directory',
    'Order Form',
    'Settings'
  ];

  @override
  void initState() {
    super.initState();
    // Set up TouchBar callback
    TouchBarHelper.onTabSelect = (index) {
      setState(() {
        _currentTab = index;
      });
    };
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TouchBarHelper.setDashboardTouchBar(currentTabIndex: _currentTab);
    });
  }

  @override
  void dispose() {
    TouchBarHelper.onTabSelect = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TouchBar Test'),
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
            const Text(
              'TouchBar should show tab navigation',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (defaultTargetPlatform == TargetPlatform.macOS)
              const Text(
                '✅ TouchBar is supported on macOS',
                style: TextStyle(fontSize: 16, color: Colors.green),
              )
            else
              Text(
                '❌ TouchBar not supported on ${defaultTargetPlatform.toString().split(".").last}',
                style: const TextStyle(fontSize: 16, color: Colors.orange),
              ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentTab = (_currentTab - 1).clamp(0, _tabNames.length - 1);
                    });
                    TouchBarHelper.setDashboardTouchBar(currentTabIndex: _currentTab);
                  },
                  child: const Text('Previous Tab'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentTab = (_currentTab + 1).clamp(0, _tabNames.length - 1);
                    });
                    TouchBarHelper.setDashboardTouchBar(currentTabIndex: _currentTab);
                  },
                  child: const Text('Next Tab'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}