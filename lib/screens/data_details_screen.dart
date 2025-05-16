// lib/screens/data_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:collection/collection.dart'; // For firstOrNull

import '../models/models.dart';
import '../utils/formatters.dart'; // For currencyFormatter

class DataDetailsScreen extends ConsumerWidget {
  final PaymentGroup group;

  const DataDetailsScreen({super.key, required this.group});

  // --- Pie Chart Helper ---
  Map<String, double> _createPieDataMap() {
    final double totalGroupExpenses = group.totalPaid;
    Map<String, double> dataMap = {};

    if (totalGroupExpenses <= 0) {
      for (var user in group.members) {
        dataMap[user.name] = 0.01;
      }
      return dataMap;
    }

    for (var user in group.members) {
      if ((user.totalPaid ?? 0) > 0) {
        dataMap[user.name] = user.totalPaid!;
      }
    }

    if (dataMap.isEmpty && group.members.isNotEmpty) {
      for (var user in group.members) {
        dataMap[user.name] = 0.01;
      }
    }

    return dataMap;
  }

  List<Color> _createPieColorList(ThemeData theme) {
    List<Color> colorList = [];
    int colorIndex = 0;
    final fallbackColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.orangeAccent,
      Colors.purpleAccent,
    ];

    for (var user in group.members) {
      colorList.add(user.profileColor ?? fallbackColors[colorIndex % fallbackColors.length]);
      colorIndex++;
    }

    if (colorList.isEmpty && group.members.isNotEmpty) {
      colorList.add(fallbackColors[0]);
    }

    return colorList;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final Map<String, double> pieDataMap = _createPieDataMap();
    final List<Color> pieColorList = _createPieColorList(theme);
    final bool showChart = pieDataMap.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Distribution Details', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: showChart
                  ? PieChart(
                dataMap: pieDataMap,
                animationDuration: const Duration(milliseconds: 800),
                chartLegendSpacing: 32,
                chartRadius: MediaQuery.of(context).size.width / 3.2 > 150
                    ? 150
                    : MediaQuery.of(context).size.width / 3.2,
                colorList: pieColorList,
                initialAngleInDegree: 0,
                chartType: ChartType.ring,
                ringStrokeWidth: 32,
                legendOptions: LegendOptions(
                  showLegendsInRow: false,
                  legendPosition: LegendPosition.right,
                  showLegends: true,
                  legendShape: BoxShape.circle,
                  legendTextStyle: theme.textTheme.bodyMedium!,
                ),
                chartValuesOptions: const ChartValuesOptions(
                  showChartValueBackground: true,
                  showChartValues: true,
                  showChartValuesInPercentage: true,
                  showChartValuesOutside: false,
                  decimalPlaces: 1,
                ),
              )
                  : const Center(
                heightFactor: 3,
                child: Text("No expense data to display chart."),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // --- Total Paid Info Section ---
          Text('Group Total Paid: ${currencyFormatter.format(group.totalPaid)}',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ...group.members.map((member) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: member.profileColor ?? theme.colorScheme.primary,
                child: Text(member.name[0]),
              ),
              title: Text(member.name),
              subtitle: Text('Total Paid: ${currencyFormatter.format(member.totalPaid ?? 0)}'),
            ),
          )),
        ],
      ),
    );
  }
}
