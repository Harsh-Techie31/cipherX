import 'package:expense/screens/expensePage.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/incomePage.dart';



void showAddTransactionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Select Transaction Type",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(
              context,
              icon: Icons.arrow_upward_rounded,
              label: "Income",
              color: Colors.green,
              screen: IncomePage()
            ),
            const SizedBox(height: 10),
            _buildOption(
              context,
              icon: Icons.arrow_downward_rounded,
                          label: "Expense",
              color: Colors.redAccent,
              screen: ExpensePage()
            ),
            
            
          ],
        ),
      );
    },
  );
}

Widget _buildOption(BuildContext context, {required IconData icon, required String label, required Color color , required Widget screen}) {
  return GestureDetector(
    onTap: () {
      Navigator.pop(context); // Close dialog on selection
      Get.to(() => screen);
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}