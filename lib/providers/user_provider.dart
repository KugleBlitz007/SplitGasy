import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  double _balanceOwed = 0.0;
  double _balanceOwedToYou = 0.0;

  User? get user => _user;
  double get balanceOwed => _balanceOwed;
  double get balanceOwedToYou => _balanceOwedToYou;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void setBalances(double owed, double owedToYou) {
    _balanceOwed = owed;
    _balanceOwedToYou = owedToYou;
    notifyListeners();
  }
}