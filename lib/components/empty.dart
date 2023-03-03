import 'package:flutter/material.dart';

class Empty extends StatelessWidget {
  const Empty({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 100, height: 15, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Container(width: 140, height: 15, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Container(width: 200, height: 15, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('EMPTY ...',
              style: TextStyle(color: Color.fromARGB(255, 43, 113, 90)))
        ],
      ),
    );
  }
}
