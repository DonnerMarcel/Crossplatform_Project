// lib/screens/data_details_screen.dart
import 'dart:math'; // For max function

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:collection/collection.dart';

import '../models/models.dart';
import '../services/profile_image_cache_provider.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart'; // For defaultPortionCost

class DataDetailsScreen extends ConsumerWidget {
  final PaymentGroup group;

  const DataDetailsScreen({super.key, required this.group});

  // --- Pie Chart Helper (remains the same) ---
  Map<String, double> _createPieDataMap() {
    Map<String, double> dataMap = {};
    if (group.expenses.isEmpty) {
      for (var user in group.members) {
        dataMap[user.name] = 0.01;
      }
      return dataMap;
    }
    for (var user in group.members) {
      dataMap[user.name] = (user.totalPaid ?? 0) > 0 ? user.totalPaid! : 0.01;
    }
    if (dataMap.values.every((v) => v <= 0.01) && group.members.isNotEmpty) {
      dataMap.clear();
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
      theme.colorScheme.primary, theme.colorScheme.secondary, theme.colorScheme.tertiary,
      Colors.lightBlue, Colors.lightGreen, Colors.orangeAccent, Colors.purpleAccent,
    ];
    final pieDataMapKeys = _createPieDataMap().keys.toList();
    for (var userName in pieDataMapKeys) {
      final user = group.members.firstWhereOrNull((member) => member.name == userName);
      colorList.add(user?.profileColor ?? fallbackColors[colorIndex % fallbackColors.length]);
      colorIndex++;
    }
    if (colorList.isEmpty && group.members.isNotEmpty) {
      colorList.add(fallbackColors[0]);
    }
    return colorList;
  }

  // --- NEW: Algorithm to calculate payment probabilities ---
  Map<String, double> _calculatePaymentProbabilities(
      List<User> members, double hysteresis) {
    if (members.isEmpty || hysteresis <= 0) {
      return {for (var member in members) member.id: 0.0};
    }

    // User sums (using totalPaid from User model)
    Map<String, double> userSums = {
      for (var member in members) member.id: member.totalPaid ?? 0.0
    };

    // 1. Identify Xmax
    double xMax = 0.0;
    if (userSums.isNotEmpty) {
      xMax = userSums.values.reduce(max);
    }

    // 2. Determine calculation group based on outliers
    List<User> calculationGroup = [];
    bool outliersFound = false;
    for (var member in members) {
      if (xMax - (userSums[member.id] ?? 0.0) > hysteresis) {
        outliersFound = true;
        break; // Found at least one outlier
      }
    }

    if (outliersFound) {
      for (var member in members) {
        if (xMax - (userSums[member.id] ?? 0.0) > hysteresis) {
          calculationGroup.add(member);
        }
      }
    } else {
      calculationGroup.addAll(members);
    }

    if (calculationGroup.isEmpty) {
      return {for (var member in members) member.id: 0.0};
    }

    // 4. Find Xmin in calculation group
    double xMin = calculationGroup
        .map((user) => userSums[user.id] ?? 0.0)
        .reduce(min);

    // 7. Calculate weights
    Map<String, double> weights = {};
    for (var member in members) { // Iterate all members to assign 0 weight if not in calc group
      if (calculationGroup.any((calcMember) => calcMember.id == member.id)) {
        double userSum = userSums[member.id] ?? 0.0;
        double weight = hysteresis - (userSum - xMin);
        weights[member.id] = max(0.0, weight); // Clamp to 0 if negative
      } else {
        weights[member.id] = 0.0;
      }
    }

    // 8. Calculate total weight
    double totalWeight = weights.values.fold(0.0, (sum, item) => sum + item);

    // 9. Calculate probabilities
    Map<String, double> probabilities = {};
    if (totalWeight == 0) {
      // If total weight is 0 (e.g., all paid amounts are similar and Hysteresis is small, or H=0)
      // Distribute equally among calculation group, or 0 if no one in calculation group (already handled)
      if (calculationGroup.isNotEmpty) {
        double equalProbability = 1.0 / calculationGroup.length;
        for (var member in members) {
            probabilities[member.id] = calculationGroup.any((calcMember) => calcMember.id == member.id) ? equalProbability : 0.0;
        }
      } else {
         for (var member in members) {
            probabilities[member.id] = 0.0;
        }
      }
    } else {
      for (var memberId in weights.keys) {
        probabilities[memberId] = (weights[memberId] ?? 0.0) / totalWeight;
      }
    }
    return probabilities;
  }
  // --- END NEW ALGORITHM ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final PaymentGroup currentGroup = group; // Using the passed group

    final Map<String, double> pieDataMap = _createPieDataMap();
    final List<Color> pieColorList = _createPieColorList(theme);
    final bool showChart = currentGroup.expenses.isNotEmpty && pieDataMap.values.any((v) => v > 0.01);

    double totalExpenseAmount = 0.0;
    double averageExpenseAmount = 0.0;
    if (currentGroup.expenses.isNotEmpty) {
      totalExpenseAmount = currentGroup.expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      averageExpenseAmount = totalExpenseAmount / currentGroup.expenses.length;
    }

    // --- NEW: Calculate Hysteresis and Probabilities ---
    // Use defaultPortionCost (from constants.dart) if average is 0, times 2 as a factor
    double hysteresisFactor = 2.0;
    double baseHysteresisValue = averageExpenseAmount > 0 ? averageExpenseAmount : 20;
    double hysteresis = baseHysteresisValue * hysteresisFactor;
    // Ensure hysteresis is not ridiculously small if defaultPortionCost is also small
    if (hysteresis < 1.0 && currentGroup.members.isNotEmpty) { // Arbitrary small threshold
        hysteresis = 20 * currentGroup.members.length * 2; // Alternative fallback
        hysteresis = max(hysteresis, 10.0); // Absolute minimum Hysteresis
    }

    Map<String, double> paymentProbabilities = {};
    if (currentGroup.members.isNotEmpty) {
        paymentProbabilities = _calculatePaymentProbabilities(currentGroup.members, hysteresis);
    }
    // --- END NEW ---

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Distribution Details', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: showChart
                  ? PieChart(/* ... PieChart code remains the same ... */
                      dataMap: pieDataMap,
                      animationDuration: const Duration(milliseconds: 800),
                      chartLegendSpacing: 32,
                      chartRadius: MediaQuery.of(context).size.width / 3.2 > 150
                          ? 150
                          : MediaQuery.of(context).size.width / 3.2,
                      colorList: pieColorList,
                      initialAngleInDegree: 0,
                      chartType: ChartType.ring,
                      ringStrokeWidth: 28,
                      legendOptions: LegendOptions(
                        showLegendsInRow: false,
                        legendPosition: LegendPosition.right,
                        showLegends: true,
                        legendShape: BoxShape.circle,
                        legendTextStyle: theme.textTheme.bodyMedium!,
                      ),
                      chartValuesOptions: const ChartValuesOptions(
                        showChartValueBackground: false,
                        showChartValues: true,
                        showChartValuesInPercentage: true,
                        showChartValuesOutside: false,
                        decimalPlaces: 1,
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          "No expense data to display chart.",
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Group Statistics', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20)),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
                  title: const Text('Total Group Expenses'),
                  trailing: Text(
                    currencyFormatter.format(totalExpenseAmount),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.functions_outlined, color: theme.colorScheme.secondary),
                  title: const Text('Average Expense Amount'),
                  trailing: Text(
                    currentGroup.expenses.isEmpty
                        ? 'N/A'
                        : currencyFormatter.format(averageExpenseAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: currentGroup.expenses.isEmpty ? Colors.grey : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- NEW: Next Payer Probabilities Section ---
          Text('Next Payer Probabilities', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20)),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: currentGroup.members.isEmpty
                ? const ListTile(title: Text('No members in this group to calculate probabilities.'))
                : Column(
                    children: currentGroup.members.map((member) {
                      final probability = paymentProbabilities[member.id] ?? 0.0;
                      final imageCache = ref.watch(profileImageCacheProvider);
                      final imageUrl = imageCache[member.id];

                      return ListTile(
                      leading: imageUrl != null
                          ? CircleAvatar(
                        backgroundImage: NetworkImage(imageUrl),
                      )
                          : CircleAvatar(
                        backgroundColor: member.profileColor ?? theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
                      ),
                      title: Text(member.name, style: theme.textTheme.titleMedium),
                        trailing: Text(
                          '${(probability * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: probability > 0 ? theme.colorScheme.primary : Colors.grey,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 24),
          // --- END NEW SECTION ---

          Text('Member Contributions', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20)),
          const SizedBox(height: 12),
          if (currentGroup.members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  "No members in this group.",
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...currentGroup.members.map((member) {
              final imageCache = ref.watch(profileImageCacheProvider);
              final imageUrl = imageCache[member.id];
              
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: imageUrl != null
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(imageUrl),
                  )
                      : CircleAvatar(
                    backgroundColor: member.profileColor ?? theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(member.name, style: theme.textTheme.titleMedium),
                  subtitle: Text('Total Paid: ${currencyFormatter.format(member.totalPaid ?? 0)}'),
                ),
              );
            }
            )
        ],
      ),
    );
  }
}
