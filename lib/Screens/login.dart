import 'package:budget_tracker/Constants/constants.dart';
import 'package:budget_tracker/Screens/dashboard.dart';
import 'package:budget_tracker/Screens/sign_up.dart';
import 'package:budget_tracker/services/auth_services.dart';
import 'package:budget_tracker/widgets/auth_gate.dart';
import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var isLoader = false;
  var authService = AuthService();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoader = true;
      });

      var data = {
        "email": _emailController.text,
        "password": _passwordController.text,
      };
      try {
        await authService.loginUser(data, context);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }

      setState(() {
        isLoader = false;
      });
    }
  }

  String? _validatePhoneNumber(value) {
    if (value!.isEmpty) {
      return 'Please Enter a Phone Number';
    }
    if (value.length != 10) {
      return 'Please Enter 10 digit Phone Number';
    }
    return null;
  }

  String? _validatePassword(value) {
    if (value!.isEmpty) {
      return 'Please Enter a Password';
    }
    if (value.length < 5) {
      return 'Please Enter a Strong Password';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kdark,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey, // Assign the key here
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 100),
                  child: Text(
                    "Login",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, color: kwhite),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  style: TextStyle(color: kwhite, fontSize: 18),
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.email_outlined),
                    suffixIconColor: kwhite,
                    filled: true,
                    fillColor: Colors.blue,
                    hintText: "Email",
                    hintStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kwhite, width: 2)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kwhite)),
                  ),
                  validator: (value) {
                    // Add your email validation logic here
                    // For example, you can use a regex pattern
                    if (value!.isEmpty || !value.contains('@')) {
                      return 'Please Enter a Valid Email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                TextFormField(
                  style: TextStyle(color: kwhite, fontSize: 18),
                  keyboardType: TextInputType.visiblePassword,
                  controller: _passwordController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  obscureText: true,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.password),
                    suffixIconColor: kwhite,
                    filled: true,
                    fillColor: Colors.blue,
                    hintText: "Password",
                    hintStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kwhite, width: 2)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kwhite)),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 50),
                Container(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                    ),
                    onPressed: () {
                      isLoader ? "" : _submitForm();
                    },
                    child: isLoader
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : Text(
                            "Login",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => MyForm()));
                    },
                    child: const Text(
                      "Register New User",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
