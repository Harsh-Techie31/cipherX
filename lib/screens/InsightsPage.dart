import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:expense/models/expense_model.dart';
import 'package:expense/models/income_model.dart';

class SpendingInsightsScreen extends StatefulWidget {
  const SpendingInsightsScreen({super.key});

  @override
  _SpendingInsightsScreenState createState() => _SpendingInsightsScreenState();
}

class _SpendingInsightsScreenState extends State<SpendingInsightsScreen> {
  double totalIncome = 0;
  double totalExpenses = 0;
  double savings = 0;
  Map<String, double> categorySpending = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final expenseBox = Hive.box<Expense>('expenses');
    final incomeBox = Hive.box<Income>('income');

    double incomeSum = 0;
    double expenseSum = 0;
    Map<String, double> categoryMap = {};

    for (var income in incomeBox.values) {
      incomeSum += income.amount;
    }

    for (var expense in expenseBox.values) {
      expenseSum += expense.amount;
      categoryMap[expense.category] = (categoryMap[expense.category] ?? 0) + expense.amount;
    }

    setState(() {
      totalIncome = incomeSum;
      totalExpenses = expenseSum;
      savings = totalIncome - totalExpenses;
      categorySpending = categoryMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Spending Insights"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 20),
            Text("Spending Breakdown", style: _sectionTitleStyle),
            const SizedBox(height: 10),
            _buildPieChart(),
            const SizedBox(height: 20),
            Text("Monthly Trends", style: _sectionTitleStyle),
            const SizedBox(height: 10),
            _buildBarChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.deepPurple.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow("Total Income", "₹${totalIncome.toStringAsFixed(2)}", Colors.green),
            _buildSummaryRow("Total Expenses", "₹${totalExpenses.toStringAsFixed(2)}", Colors.red),
            _buildSummaryRow("Savings", "₹${savings.toStringAsFixed(2)}", Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    if (categorySpending.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    List<PieChartSectionData> sections = categorySpending.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: entry.key,
        color: _getCategoryColor(entry.key),
        radius: 50,
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(PieChartData(sections: sections)),
    );
  }

  Widget _buildBarChart() {
    if (categorySpending.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    List<BarChartGroupData> bars = categorySpending.entries.map((entry) {
      return BarChartGroupData(
        x: categorySpending.keys.toList().indexOf(entry.key),
        barRods: [BarChartRodData(toY: entry.value, color: _getCategoryColor(entry.key))],
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: BarChart(BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(categorySpending.keys.toList()[value.toInt()], style: TextStyle(fontSize: 12));
              },
            ),
          ),
        ),
        barGroups: bars,
      )),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink
    ];
    return colors[category.hashCode % colors.length];
  }

  TextStyle get _sectionTitleStyle => const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
}
