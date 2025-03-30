import 'package:expense/models/expense_model.dart';
import 'package:expense/models/income_model.dart';
import 'package:expense/screens/homePage.dart';
import 'package:expense/screens/loginPage.dart';
import 'package:expense/screens/signupPage.dart';
import 'package:expense/screens/splashScreen.dart';
import 'package:expense/services/AuthServices.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(1)) {
   Hive.registerAdapter(IncomeAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
     Hive.registerAdapter(ExpenseAdapter());
    
  }

  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Income>('income');
  
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      
      home:  SplashScreen(),
    );
  }
}



// // class HomePage {
// }