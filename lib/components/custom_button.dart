import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Function()? onTap;
  final String text;
  
  const CustomButton({
    super.key,
    required this.onTap,
    this.text = 'Sign In'
    });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 25),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Hide keyboard when button is tapped
            FocusScope.of(context).unfocus();
            
            // Call the onTap callback
            if (onTap != null) {
              onTap!();
            }
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.grey[400],
          child: Ink(
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Color(0xFF043E50),
              borderRadius: BorderRadius.circular(8)
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}