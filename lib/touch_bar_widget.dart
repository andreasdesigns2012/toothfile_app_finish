import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A TouchBar-like floating tab bar for macOS that provides quick tab navigation
class TouchBarWidget extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final List<String> tabLabels;
  final List<IconData> tabIcons;

  const TouchBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.tabLabels,
    required this.tabIcons,
  });

  @override
  State<TouchBarWidget> createState() => _TouchBarWidgetState();
}

class _TouchBarWidgetState extends State<TouchBarWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      return const SizedBox.shrink(); // Only show on macOS
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Collapse/Expand button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'TouchBar',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            // TouchBar content
            if (_isExpanded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App name/label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ToothFile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Tab navigation
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800]?.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.tabLabels.length,
                        separatorBuilder: (context, index) => VerticalDivider(
                          width: 1,
                          color: Colors.grey[600],
                        ),
                        itemBuilder: (context, index) {
                          final isSelected = index == widget.currentIndex;
                          return GestureDetector(
                            onTap: () => widget.onTabSelected(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.tabIcons[index],
                                    color: isSelected ? Colors.blue : Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.tabLabels[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.blue : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Additional actions can go here
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800]?.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to manage TouchBar functionality
class TouchBarManager {
  static final TouchBarManager _instance = TouchBarManager._internal();
  factory TouchBarManager() => _instance;
  TouchBarManager._internal();

  Function(int)? onTabSelected;
  int _currentTabIndex = 0;

  int get currentTabIndex => _currentTabIndex;

  void setCurrentTabIndex(int index) {
    _currentTabIndex = index;
  }

  void setTabCallback(Function(int) callback) {
    onTabSelected = callback;
  }

  List<String> get tabLabels => [
    'Received',
    'Send',
    'Tracker',
    'Requests',
    'Directory',
    'Order',
    'Settings',
  ];

  List<IconData> get tabIcons => [
    Icons.download,
    Icons.send,
    Icons.analytics,
    Icons.notifications,
    Icons.people,
    Icons.description,
    Icons.settings,
  ];
}