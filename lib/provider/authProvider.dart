import 'dart:convert';

import 'package:dispatch_app_rider/model/response.dart';
import 'package:dispatch_app_rider/model/rider.dart';
import 'package:dispatch_app_rider/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Rider loggedInRider;

class AUthProvider with ChangeNotifier {
  final riderRef = FirebaseDatabase.instance.reference().child('riders');
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  bool isLoggedIn = false;
  Future<ResponseModel> login(String email, String password) async {
    try {
      final authResult = await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      final dataSnapShot = await riderRef.child(authResult.user.uid).once();
      loggedInRider = Rider(
        dataSnapShot.value['id'],
        dataSnapShot.value['fullname'],
        dataSnapShot.value['phoneNumber'],
        dataSnapShot.value['email'],
        password,
      );
      storeAutoData(loggedInRider);
      storeAppOnBoardingData(loggedInRider.id);
      return ResponseModel(true, "Rider SignIn Sucessfull");
    } catch (e) {
      return ResponseModel(false, e.toString());
    }
  }

  Future<ResponseModel> signUp(Rider rider) async {
    try {
      final authResult = await firebaseAuth.createUserWithEmailAndPassword(
          email: rider.email, password: rider.password);
      await riderRef.child(authResult.user.uid).set({
        "id": authResult.user.uid,
        "email": rider.email,
        "fullname": rider.fullName,
        "phoneNumber": rider.phoneNumber,
      });
      loggedInRider = new Rider(authResult.user.uid, rider.fullName,
          rider.fullName, rider.email, rider.password);
      final autoLoggedRider = Rider(authResult.user.uid, rider.email,
          rider.fullName, rider.phoneNumber, rider.password);
      storeAutoData(autoLoggedRider);
      storeAppOnBoardingData(loggedInRider.id);
      return ResponseModel(true, "Rider SignUp Sucessfull");
    } catch (e) {
      return ResponseModel(false, e.toString());
    }
  }

  Future<ResponseModel> logOut() async {
    try {
      await firebaseAuth.signOut();
      loggedInRider = null;
      deleteAutoData();
      return ResponseModel(true, "Rider LogOut Sucessfull");
    } catch (e) {
      return ResponseModel(false, e.toString());
    }
  }

  Future<ResponseModel> updateProfile(
      String fullname, String phoneNumber) async {
    try {
      riderRef
          .child(loggedInRider.id)
          .update({'fullname': fullname, 'phoneNumber': phoneNumber});
      loggedInRider = Rider(loggedInRider.id, fullname, phoneNumber,
          loggedInRider.email, loggedInRider.password);
      return ResponseModel(true, "Rider Profile Updated Sucessfully");
    } catch (e) {
      return ResponseModel(false, e.toString());
    }
  }

  Future<ResponseModel> updatePassword(String password) async {
    try {
      FirebaseUser user = await FirebaseAuth.instance.currentUser();
      await user.updatePassword(password);
      return ResponseModel(true, "Password Update Sucessfull");
    } catch (e) {
      return ResponseModel(false, e.toString());
    }
  }

  void storeAutoData(Rider rider) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final logOnData = json.encode({
      'id': rider.id,
      'fullName': rider.fullName,
      'password': rider.password,
      'email': rider.email,
      'phoneNumber': rider.phoneNumber
    });
    sharedPrefs.setString(Constant.autoLogOnData, logOnData);
  }

  void storeAppOnBoardingData(String riderId) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final logOnData = json.encode({
      'id': riderId,
    });
    sharedPrefs.setString(Constant.onBoardingData, logOnData);
  }

  void deleteAutoData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(Constant.autoLogOnData);
  }

  Future<bool> tryAutoLogin() async {
    final sharedPref = await SharedPreferences.getInstance();
    if (!sharedPref.containsKey(Constant.autoLogOnData)) {
      return false;
    }
    final sharedData = sharedPref.getString(Constant.autoLogOnData);
    final logOnData = json.decode(sharedData) as Map<String, Object>;
    loggedInRider = new Rider(
      logOnData['id'],
      logOnData['fullName'],
      logOnData['phoneNumber'],
      logOnData['email'],
      logOnData['password'],
    );
    isLoggedIn = true;
    return true;
  }

  Future<bool> isRiderOnBoarded() async {
    final sharedPref = await SharedPreferences.getInstance();
    if (!sharedPref.containsKey(Constant.onBoardingData)) {
      return false;
    }

    return true;
  }
}
