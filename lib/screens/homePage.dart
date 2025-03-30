import 'dart:developer';
import 'package:expense/models/expense_model.dart';
import 'package:expense/models/income_model.dart';
import 'package:expense/screens/InsightsPage.dart';
import 'package:expense/screens/loginPage.dart';
import 'package:expense/services/AuthServices.dart';
import 'package:expense/widges/AlertBox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class ExpenseHomeScreen extends StatefulWidget {
  const ExpenseHomeScreen({super.key});

  @override
  _ExpenseHomeScreenState createState() => _ExpenseHomeScreenState();
}

class _ExpenseHomeScreenState extends State<ExpenseHomeScreen> {
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  String selectedFilter = "This Month";
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  void _logout() async {
    log("Logging out...");
    await AuthService().logout();
    log("Logged out successfully");
    Get.offAll(() => LoginPage());
  }

  double _calculateTotalAmount(Box<dynamic> box, String userId) {
    return box.values
        .where((entry) => entry.userId == userId)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  List<Map<String, dynamic>> _mergeTransactions(Box<Income> incomeBox, Box<Expense> expenseBox, String userId) {
    List<Map<String, dynamic>> transactions = [];
    
    // Add incomes with their Hive keys
    transactions.addAll(incomeBox.toMap().entries
        .where((entry) => entry.value.userId == userId)
        .map((entry) => {
              "id": entry.key, // Hive key as ID
              "type": "income",
              "category": entry.value.source,
              "amount": entry.value.amount,
              "date": entry.value.date,
              "description": entry.value.description ?? ""
            }));
    
    // Add expenses with their Hive keys
    transactions.addAll(expenseBox.toMap().entries
        .where((entry) => entry.value.userId == userId)
        .map((entry) => {
              "id": entry.key, // Hive key as ID
              "type": "expense",
              "category": entry.value.category,
              "amount": -entry.value.amount,
              "date": entry.value.date,
              "description": entry.value.description ?? ""
            }));
    
    transactions.sort((a, b) => b["date"].compareTo(a["date"]));
    return transactions;
  }

  bool _filterTransactions(Map<String, dynamic> transaction) {
    DateTime now = DateTime.now();
    DateTime transactionDate = transaction["date"];

    switch (selectedFilter) {
      case "Today":
        return transactionDate.year == now.year &&
            transactionDate.month == now.month &&
            transactionDate.day == now.day;
      case "This Week":
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return transactionDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            transactionDate.isBefore(now.add(const Duration(days: 1)));
      case "This Month":
        return transactionDate.year == now.year && transactionDate.month == now.month;
      case "See All":
      default:
        return true;
    }
  }

  Widget _buildStatCard(String title, String amount, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            title == "Income" ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.white,
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(int id) async {
    final expenseBox = Hive.box<Expense>('expenses');
    final incomeBox = Hive.box<Income>('income');
    
    if (expenseBox.containsKey(id)) {
      await expenseBox.delete(id);
    } else if (incomeBox.containsKey(id)) {
      await incomeBox.delete(id);
    }
    
    // No need to call setState() here because ValueListenableBuilder will handle updates
  }

  Widget buildTransactionTile(Map<String, dynamic> transaction) {
    bool isIncome = transaction["type"] == "income";
    DateTime date = transaction["date"];
    String formattedDate = DateFormat('dd MMM yyyy').format(date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncome ? Colors.green : Colors.red,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction["category"],
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction["description"] ?? "No description",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            "₹${transaction["amount"].toStringAsFixed(2)}",
            style: TextStyle(
              color: isIncome ? Colors.green : Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedFilter == label,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            selectedFilter = label;
          });
        }
      },
      selectedColor: Colors.purple[200],
      backgroundColor: Colors.grey[300],
      labelStyle: const TextStyle(color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text("User not logged in"));
    }

    String userId = _currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
                  Icon(Icons.notifications, color: Colors.grey[700]),
                ],
              ),
              const SizedBox(height: 10),
              
              // Account Balance Section
              ValueListenableBuilder(
                valueListenable: Hive.box<Income>('income').listenable(),
                builder: (context, Box<Income> incomeBox, _) {
                  return ValueListenableBuilder(
                    valueListenable: Hive.box<Expense>('expenses').listenable(),
                    builder: (context, Box<Expense> expenseBox, _) {
                      double totalIncome = _calculateTotalAmount(incomeBox, userId);
                      double totalExpenses = _calculateTotalAmount(expenseBox, userId);
                      double balance = totalIncome - totalExpenses;

                      return Column(
                        children: [
                          Text("Account Balance",
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                          const SizedBox(height: 5),
                          Text("₹${balance.toStringAsFixed(2)}",
                              style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),
              
              // Income & Expenses Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder(
                    valueListenable: Hive.box<Income>('income').listenable(),
                    builder: (context, Box<Income> incomeBox, _) {
                      return _buildStatCard("Income", "₹${_calculateTotalAmount(incomeBox, userId).toStringAsFixed(2)}", Colors.green);
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<Expense>('expenses').listenable(),
                    builder: (context, Box<Expense> expenseBox, _) {
                      return _buildStatCard("Expenses", "₹${_calculateTotalAmount(expenseBox, userId).toStringAsFixed(2)}", Colors.red);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
              
              // Transaction Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 10,
                  children: ["Today", "This Week", "This Month", "See All"]
                      .map((filter) => _buildFilterChip(filter))
                      .toList(),
                ),
              ),

              const SizedBox(height: 10),
              
              // Transactions List
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<Income>('income').listenable(),
                  builder: (context, Box<Income> incomeBox, _) {
                    return ValueListenableBuilder(
                      valueListenable: Hive.box<Expense>('expenses').listenable(),
                      builder: (context, Box<Expense> expenseBox, _) {
                        final transactions = _mergeTransactions(incomeBox, expenseBox, userId)
                            .where(_filterTransactions)
                            .toList();

                        if (transactions.isEmpty) {
                          return const Center(child: Text("No transactions yet."));
                        }

                        return ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            final id = transaction['id'];
                            
                            return Dismissible(
                              key: Key(id.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white, size: 28),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete Transaction"),
                                    content: const Text("Are you sure you want to delete this transaction?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) async {
                                await _deleteTransaction(id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Transaction deleted")));
                              },
                              child: buildTransactionTile(transaction),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddTransactionDialog(context);
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.home, color: Colors.purple),
              Icon(Icons.swap_horiz, color: Colors.grey[600]),
              const SizedBox(width: 40),
              IconButton(
                onPressed: () {
                  Get.to(() => SpendingInsightsScreen());
                },
                icon: Icon(Icons.pie_chart),
                color: const Color.fromARGB(255, 45, 31, 237),
              ),
              Icon(Icons.person, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}