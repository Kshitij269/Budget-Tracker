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
  late double totalMonthlyExpense;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    totalMonthlyExpense = 0;
    _monthlyExpensesStreamController = StreamController<List<dynamic>>();
    _monthlyExpensesStream = _monthlyExpensesStreamController.stream;
    _fetchAndPopulateMonthlyExpenses(_selectedMonth);
  }

  Future<List<dynamic>> getMonthlyExpenses(DateTime selectedMonth) async {
    try {
      DateTime startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1, 0, 0, 0);
      DateTime endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .orderBy('timestamp')
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
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
    double total = 0;
    for (var expense in monthlyExpenses) {
      total += expense['amount'];
    }
    setState(() {
      totalMonthlyExpense = total;
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
          onPressed: (){
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back,color: kwhite,),
        ),
        backgroundColor: kdark,
        centerTitle: true,
        title: Text(
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
            margin: EdgeInsets.symmetric(horizontal: 15,vertical: 10),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _selectMonth(context),
                  child: Text('Select Month'),
                ),
                SizedBox(height: 16),
                Text(
                  'Total Monthly Expense',
                  style: TextStyle(color: kwhite, fontSize: 18),
                ),
                Text(
                  '\u{20B9}${totalMonthlyExpense.toStringAsFixed(2)}',
                  style: TextStyle(color: kwhite, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: MonthlyExpenseList(
              user: widget.user,
              monthlyExpensesStream: _monthlyExpensesStream,
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

  MonthlyExpenseList({required this.user, required this.monthlyExpensesStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: monthlyExpensesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        List<dynamic>? monthlyExpenses = snapshot.data;
        if (monthlyExpenses == null || monthlyExpenses.isEmpty) {
          return Center(
            child: Text(
              'No expenses for the selected month.',
              style: TextStyle(color: kwhite, fontSize: 20),
            ),
          );
        }

        return ListView.builder(
          itemCount: monthlyExpenses.length,
          itemBuilder: (context, index) {
            var expense = monthlyExpenses[index];
            var timestamp = (expense['timestamp'] as Timestamp).toDate();
            var formattedDate = DateFormat.yMMMMd().format(timestamp);

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 4.0,
              color: kdark,
              child: ListTile(
                title: Text(
                  expense['title'],
                  style: TextStyle(
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
                      style: TextStyle(color: kwhite, fontSize: 16),
                    ),
                    Text(
                      'Category: ${expense['category']}',
                      style: TextStyle(color: kwhite, fontSize: 16),
                    ),
                    Text(
                      'Time: $formattedDate',
                      style: TextStyle(color: kwhite, fontSize: 16),
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
