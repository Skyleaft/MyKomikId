import 'package:flutter/material.dart';

class StatusSelectionSheet {
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final statuses = [
          'Reading',
          'Completed',
          'OnHold',
          'Dropped',
          'PlanToRead',
        ];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...statuses.map(
                (status) => ListTile(
                  title: Text(status),
                  onTap: () => Navigator.pop(context, status),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
