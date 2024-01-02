import 'dart:async';
import 'package:budget_tracker/Constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MonthlyAnalysis extends StatefulWidget {
  final User user;
  MonthlyAnalysis({required this.user});
  @override
  _MonthlyAnalysisState createState() => _MonthlyAnalysisState();
}

class _MonthlyAnalysisState extends State<MonthlyAnalysis> {
  late DateTime _selectedMonth;
  late StreamController<List<dynamic>> _monthlyExpensesStreamController;
  late Stream<List<dynamic>> _monthlyExpensesStream;
  double totalSpent = 0;
  double totalCredit = 0;
  String selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    totalSpent = 0;
    totalCredit = 0;
    _monthlyExpensesStreamController = StreamController<List<dynamic>>();
    _monthlyExpensesStream = _monthlyExpensesStreamController.stream;
    _fetchAndPopulateMonthlyExpenses(_selectedMonth);
  }

  Future<List<dynamic>> getMonthlyExpenses(DateTime selectedMonth) async {
    try {
      DateTime startOfMonth =
          DateTime(selectedMonth.year, selectedMonth.month, 1, 0, 0, 0);
      DateTime endOfMonth =
          DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(FirebaseAuth.instance.currentUser!.uid)
          .doc('expenses')
          .collection('Debit')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .orderBy('timestamp')
          .get();

      QuerySnapshot creditQuerySnapshot = await FirebaseFirestore.instance
          .collection(FirebaseAuth.instance.currentUser!.uid)
          .doc('expenses')
          .collection('Credit')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .orderBy('timestamp')
          .get();

      List<DocumentSnapshot> allDocs =
          querySnapshot.docs + creditQuerySnapshot.docs;
      allDocs.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

      return allDocs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching monthly expenses: $e');
      return [];
    }
  }

  void _fetchAndPopulateMonthlyExpenses(DateTime selectedMonth) {
    getMonthlyExpenses(selectedMonth).then((monthlyExpenses) {
      _monthlyExpensesStreamController.add(monthlyExpenses);
      calculateTotalMonthlyExpense(monthlyExpenses);
    }).catchError((error) {
      print('Error fetching and populating monthly expenses: $error');
    });
  }

  void calculateTotalMonthlyExpense(List<dynamic> monthlyExpenses) {
    double totalS = 0;
    double totalC = 0;

    for (var expense in monthlyExpenses) {
      if (expense['type'] == 'Debit') {
        totalS += expense['amount'];
      } else {
        totalC += expense['amount'];
      }
    }
    setState(() {
      totalSpent = totalS;
      totalCredit = totalC;
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2022),
      lastDate: DateTime(2060),
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
      });
      _fetchAndPopulateMonthlyExpenses(_selectedMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: kwhite,
          ),
        ),
        backgroundColor: kdark,
        centerTitle: true,
        title: const Text(
          'Monthly Analysis',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kdark,
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _selectMonth(context),
                  child: const Text('Select Month'),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  dropdownColor: kdark,
                  style: TextStyle(color: kwhite),
                  value: selectedType,
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                  items: ['Credit', 'Debit', 'All'].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text(
                      'Total Monthly Spent',
                      style: TextStyle(color: kwhite, fontSize: 18),
                    ),
                    Text(
                      '\u{20B9}${totalSpent.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: kwhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text(
                      'Total Monthly Credit',
                      style: TextStyle(color: kwhite, fontSize: 18),
                    ),
                    Text(
                      '\u{20B9}${totalCredit.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: kwhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: MonthlyExpenseList(
              user: widget.user,
              monthlyExpensesStream: _monthlyExpensesStream,
              selected: selectedType,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _monthlyExpensesStreamController.close();
    super.dispose();
  }
}

class MonthlyExpenseList extends StatelessWidget {
  final User user;
  final Stream<List<dynamic>> monthlyExpensesStream;
  final String selected;

  MonthlyExpenseList(
      {required this.user,
      required this.monthlyExpensesStream,
      required this.selected});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: monthlyExpensesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        List<dynamic>? monthlyExpenses = snapshot.data;
        if (monthlyExpenses == null || monthlyExpenses.isEmpty) {
          return const Center(
            child: Text(
              'No expenses for the selected month.',
              style: TextStyle(color: kwhite, fontSize: 20),
            ),
          );
        }

        List<dynamic> filteredExpenses = monthlyExpenses.where((expense) {
          if (selected == 'All') {
            return true;
          } else if (selected == 'Credit') {
            return expense['type'] == 'Credit';
          } else if (selected == 'Debit') {
            return expense['type'] == 'Debit';
          }
          return false;
        }).toList();

        return ListView.builder(
          itemCount: filteredExpenses.length,
          itemBuilder: (context, index) {
            var expense = filteredExpenses[index];
            var timestamp = (expense['timestamp'] as Timestamp).toDate();
            var formattedDate = DateFormat.yMMMMd().format(timestamp);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 4.0,
              color: kdark,
              child: ListTile(
                title: Text(
                  expense['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kwhite,
                    fontSize: 20,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u{20B9}${expense['amount']}',
                      style: const TextStyle(color: kwhite, fontSize: 16),
                    ),
                    Text(
                      'Category: ${expense['category']}',
                      style: const TextStyle(color: kwhite, fontSize: 16),
                    ),
                    Text(
                      'Type: ${expense['type']}',
                      style: const TextStyle(color: kwhite, fontSize: 16),
                    ),
                    Text(
                      'Time: $formattedDate',
                      style: const TextStyle(color: kwhite, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
