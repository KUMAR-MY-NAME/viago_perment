import 'package:flutter/material.dart';

class ParcelStatusBar extends StatelessWidget {
  final String currentStatus;

  const ParcelStatusBar({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final List<String> statuses = [
      'posted', // Changed from 'created' to 'posted' based on parcel.dart
      'accepted',
      'in_transit',
      'delivered',
    ];

    int currentStatusIndex = statuses.indexOf(currentStatus);
    if (currentStatusIndex == -1) {
      currentStatusIndex = 0; // Default to first status if not found
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: statuses.map((status) {
              int index = statuses.indexOf(status);
              bool isActive = index <= currentStatusIndex;
              bool isCurrent = index == currentStatusIndex;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Icon(
                        index == 0 ? Icons.create_new_folder : // posted
                        index == 1 ? Icons.check_circle : // accepted
                        index == 2 ? Icons.local_shipping : // in_transit
                        Icons.archive, // delivered
                        color: isActive
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.replaceAll('_', ' ').toCapitalized(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive
                            ? Theme.of(context).colorScheme.onBackground
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 5),
          Row(
            children: List.generate(statuses.length * 2 - 1, (index) {
              if (index.isEven) {
                // Circle part
                int statusIndex = index ~/ 2;
                bool isActive = statusIndex <= currentStatusIndex;
                return Container(
                  width: 24,
                  height: 2,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
                );
              } else {
                // Line part
                int lineIndex = (index - 1) ~/ 2;
                bool isActive = lineIndex < currentStatusIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
