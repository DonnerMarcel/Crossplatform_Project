// lib/screens/data_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:collection/collection.dart'; // For firstOrNull

import '../models/models.dart';
import '../utils/formatters.dart'; // For currencyFormatter
// Import providers if needed to fetch group data by ID, or receive group object
// import '../providers.dart';

class DataDetailsScreen extends ConsumerWidget { // Can be ConsumerWidget if stateless
  final PaymentGroup group; // Receive the group data

  const DataDetailsScreen({super.key, required this.group});

  // --- Moved Pie Chart Helper Logic ---
  Map<String, double> _createPieDataMap() {
    final double totalGroupExpenses = group.totalGroupExpenses; // Use passed group
    group.userTotals; // Ensure totals are calculated on the group object
    Map<String, double> dataMap = {};
    if (totalGroupExpenses <= 0) {
      for (var user in group.members) { dataMap[user.name] = 0.01; }
      return dataMap;
    }
    for (var user in group.members) {
      if (user.totalPaid > 0) { dataMap[user.name] = user.totalPaid; }
    }
    if (dataMap.isEmpty && group.members.isNotEmpty) {
       for (var user in group.members) { dataMap[user.name] = 0.01; }
    }
    return dataMap;
  }

  List<Color> _createPieColorList(ThemeData theme) {
    List<Color> colorList = [];
    int colorIndex = 0;
    final fallbackColors = [ /* Define fallbacks */
        theme.colorScheme.primary, theme.colorScheme.secondary, theme.colorScheme.tertiary,
        Colors.lightBlue, Colors.lightGreen, Colors.orangeAccent, Colors.purpleAccent,
    ];
    for (var user in group.members) { // Assuming dataMap order matches members
      colorList.add(user.profileColor ?? fallbackColors[colorIndex % fallbackColors.length]);
      colorIndex++;
    }
     if (colorList.isEmpty && group.members.isNotEmpty) {
         colorList.add(fallbackColors[0]);
     }
    return colorList;
  }
  // --- End Moved Helper Logic ---


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No Scaffold/AppBar needed here if it's shown within MainScreen's body
    // Or add one if this screen should have its own AppBar when navigated to

    final theme = Theme.of(context);
    final Map<String, double> pieDataMap = _createPieDataMap();
    final List<Color> pieColorList = _createPieColorList(theme);
    final bool showChart = pieDataMap.isNotEmpty && group.totalGroupExpenses > 0;

    // Maybe use ListView if adding more details later
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text('Payment Distribution Details', style: theme.textTheme.headlineSmall), // Title for this page
           const SizedBox(height: 16),
           Card( // Pie Chart Card (Moved from Dashboard)
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: showChart
                    ? PieChart(
                        dataMap: pieDataMap,
                        animationDuration: const Duration(milliseconds: 800),
                        chartLegendSpacing: 32,
                        chartRadius: MediaQuery.of(context).size.width / 3.2 > 150 ? 150 : MediaQuery.of(context).size.width / 3.2,
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
          // --- Add More Details Here ---
          Text('Further Information', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              title: Text('Placeholder for more detailed statistics or expense list related to this group...'),
            ),
          ),
          // Add more widgets like expense list, specific stats etc.
        ],
      ),
    );
  }
}