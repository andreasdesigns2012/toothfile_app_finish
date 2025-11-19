import 'package:flutter/material.dart';

class TeethSelector extends StatefulWidget {
  final Function(List<String>) onChange;

  const TeethSelector({Key? key, required this.onChange}) : super(key: key);

  @override
  _TeethSelectorState createState() => _TeethSelectorState();
}

class _TeethSelectorState extends State<TeethSelector> {
  List<String> _selectedTeeth = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dental Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Click on teeth to select them'),
          const Text('Selected Color: A1'),
          const SizedBox(height: 16.0),
          // Placeholder for the actual dental chart UI
          Center(
            child: Image.asset(
              'assets/dental_chart.png', // You'll need to add a dental chart image here
              height: 200,
            ),
          ),
          const SizedBox(height: 16.0),
          Text('Selected Teeth: ${_selectedTeeth.join(', ')}'),
        ],
      ),
    );
  }
}