// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, use_build_context_synchronously

import 'dart:async';
import 'package:budget_tracker/Constants/constants.dart';
import 'package:budget_tracker/Screens/monthly.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExpenseTracker extends StatelessWidget {
  final User user;

  ExpenseTracker({required this.user});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kdark,
        centerTitle: true,
        title: Text(
          'Expense Tracker',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => logOut(context),
          icon: Icon(
            Icons.exit_to_app,
            color: kwhite,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MonthlyAnalysis(
                            user: user,
                          )));
            },
            icon: Icon(
              Icons.book,
              color: kwhite,
            ),
          ),
        ],
      ),
      body: Container(color: Colors.black, child: ExpenseCalendar(user: user)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(user: user),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sign Out Successfull")));
  }
}

class ExpenseCalendar extends StatefulWidget {
  final User user;

  const ExpenseCalendar({required this.user});

  @override
  _ExpenseCalendarState createState() => _ExpenseCalendarState();
}

class _ExpenseCalendarState extends State<ExpenseCalendar> {
  late DateTime _selectedDate;
  late StreamController<List<dynamic>> _expensesStreamController;
  late Stream<List<dynamic>> _expensesStream;
  double totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _expensesStreamController = StreamController<List<dynamic>>();
    _expensesStream = _expensesStreamController.stream;
    _fetchAndPopulateExpenses(_selectedDate);

    FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: widget.user.uid)
        .snapshots()
        .listen((event) {
      _fetchAndPopulateExpenses(_selectedDate);
    });
  }

  Future<List<dynamic>> getExpensesForDate(DateTime date) async {
    try {
      DateTime startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .orderBy('timestamp')
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching expenses for date: $e');
      return [];
    }
  }

  void _fetchAndPopulateExpenses(DateTime date) {
    getExpensesForDate(date).then((expenses) {
      _expensesStreamController.add(expenses);
      calculateTotalSpent(expenses);
    }).catchError((error) {
      print('Error fetching and populating expenses: $error');
    });
  }

  void calculateTotalSpent(List<dynamic> expenses) {
    double total = 0;
    for (var expense in expenses) {
      total += expense['amount'];

    }
    setState(() {
      totalSpent = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Expanded(child: SizedBox(height: height * 0.5, child: Calendar())),
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: kdark, borderRadius: BorderRadius.circular(15)),
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.symmetric(horizontal: 15),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            children: [
              Text(
                'Date : ${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
                style: TextStyle(color: kwhite, fontSize: 15),
              ),
              Text(
                'Total Spent : \u{20B9}${totalSpent.toStringAsFixed(2)}',
                style: TextStyle(color: kwhite, fontSize: 15),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Expanded(
          child: ExpenseList(
            user: widget.user,
            expensesStream: _expensesStream,
          ),
        ),
      ],
    );
  }

  Container Calendar() {
    return Container(
      decoration:
          BoxDecoration(color: kdark, borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.all(15),
      padding: EdgeInsets.all(8),
      child: TableCalendar(
        selectedDayPredicate: (day) {
          // Return true if the day is selected, false otherwise
          return isSameDay(_selectedDate, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
          });
          _fetchAndPopulateExpenses(selectedDay);
        },
        shouldFillViewport: true,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleTextStyle: TextStyle(color: kwhite, fontSize: 20),
          leftChevronIcon: const Icon(
            Icons.chevron_left,
            color: kwhite,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: kwhite,
          ),
          titleCentered: true,
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white),
          weekendStyle: TextStyle(color: Colors.red),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: mainColor,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.blue, // Set the color you want for the selected date
            shape: BoxShape.circle,
          ),

          defaultTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          weekendTextStyle: TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
          holidayTextStyle: TextStyle(
            color: Colors.green,
            fontSize: 16,
          ),
          outsideTextStyle: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          disabledTextStyle: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          rangeStartTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          rangeEndTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          weekNumberTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          cellMargin: EdgeInsets.all(2),
        ),
        firstDay: DateTime.utc(2022, 1, 1),
        lastDay: DateTime.utc(2060, 12, 31),
        focusedDay: _selectedDate,
        calendarFormat: CalendarFormat.month,
      ),
    );
  }

  @override
  void dispose() {
    _expensesStreamController.close();
    super.dispose();
  }
}

class ExpenseList extends StatelessWidget {
  final User user;
  final Stream<List<dynamic>> expensesStream;

  const ExpenseList({required this.user, required this.expensesStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: expensesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        List<dynamic>? expenses = snapshot.data;

        if (expenses == null || expenses.isEmpty) {
          return Center(
            child: Text(
              'No expenses for the selected date.',
              style: TextStyle(color: kwhite, fontSize: 20),
            ),
          );
        }

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            var expense = expenses[index];
            var timestamp = (expense['timestamp'] as Timestamp).toDate();
            var formattedDate = DateFormat.jm().format(timestamp);

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 4.0,
              color: kdark,
              child: ListTile(
                title: Text(
                  expense['title'],
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: kwhite, fontSize: 20),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u{20B9}${expense['amount']}',
                      style: TextStyle(color: kwhite, fontSize: 16),
                    ),
                    Text('Category: ${expense['category']}',
                        style: TextStyle(color: kwhite, fontSize: 16)),
                    Text('Time: $formattedDate',
                        style: TextStyle(color: kwhite, fontSize: 16)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.green,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              ModifyExpenseScreen(user: user, expense: expense),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: mainColor,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Expense'),
                            content: Text(
                                'Are you sure you want to delete this expense?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  deleteExpense(user, expense);
                                  Navigator.pop(context);
                                },
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
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

class AddExpenseScreen extends StatelessWidget {
  final User user;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String selectedCategory = 'Food';

  AddExpenseScreen({required this.user});

  void addExpense(BuildContext context) async {
    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('expenses').add({
        'userId': user.uid,
        'title': titleController.text,
        'amount': double.parse(amountController.text),
        'category': selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Expense"),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                onChanged: (value) {
                  selectedCategory = value!;
                },
                items: ['Food', 'Travel', 'Other'].map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => addExpense(context),
                child: Text('Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModifyExpenseScreen extends StatelessWidget {
  final User user;
  final Map<String, dynamic> expense;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String selectedCategory = 'Food';

  ModifyExpenseScreen({required this.user, required this.expense}) {
    titleController.text = expense['title'];
    amountController.text = expense['amount'].toString();
    selectedCategory = expense['category'];
  }

  void modifyExpense(BuildContext context) async {
    try {
      if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .where('title', isEqualTo: expense['title'])
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Assuming there's only one document with the same title for a user
          String documentId = querySnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('expenses')
              .doc(documentId)
              .update({
            'title': titleController.text,
            'amount': double.parse(amountController.text),
            'category': selectedCategory,
          });

          Navigator.pop(context);
        } else {
          print('Document does not exist. Unable to update.');
        }
      }
    } catch (e) {
      print('Error updating expense: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modify Expense'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              onChanged: (value) {
                selectedCategory = value!;
              },
              items: ['Food', 'Travel'].map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => modifyExpense(context),
          child: Text('Modify Expense'),
        ),
      ],
    );
  }
}

void deleteExpense(User user, Map<String, dynamic> expense) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .where('title', isEqualTo: expense['title'])
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Assuming there's only one document with the same title for a user
      String documentId = querySnapshot.docs.first.id;

      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(documentId)
          .delete();
    } else {
      print('Document does not exist. Unable to delete.');
    }
  } catch (e) {
    print('Error deleting expense: $e');
  }
}
