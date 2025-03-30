import 'package:expense/screens/homePage.dart';
import 'package:expense/screens/loginPage.dart';
// import 'package:expense/screens/signupPage.dart';
import 'package:expense/services/AuthServices.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
// import 'package:expense/screens/expense_home_screen.dart'; // Update this with the actual path

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  void _startSplashSequence() async {
    await Future.delayed(const Duration(seconds: 2)); // Show first image for 2s
    setState(() {
      _currentImageIndex = 1;
    });

    await Future.delayed(const Duration(seconds: 2)); // Show second image for 2s

    // Navigate to home screen
    if (mounted) {
      String? userId = await AuthService().getUserFromLocalStorage();

      if(userId!=null){
          Get.to(()=>ExpenseHomeScreen());
      }else{
        Get.to(()=>LoginPage());
      }
      


      // Navigator.pushReplacement(
      //   context,
      //   // MaterialPageRoute(builder: (context) => const ExpenseHomeScreen()),
      //   MaterialPageRoute(builder: (context) => const ExpenseHomeScreen()),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800), // Smooth fade transition
        child: Image.asset(
          _currentImageIndex == 0 ? 'assets/splash1.png' : 'assets/splash2.png',
          key: ValueKey<int>(_currentImageIndex),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
