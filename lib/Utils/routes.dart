import 'package:flutter/material.dart';
import '../Pages/doctor_home_page.dart';
import '../Pages/login.dart';
import '../Pages/patient_home_page.dart';

class MyRoutes {
  static const String loginPage = "/loginPage";
  static const String doctorHomePage = "/doctorHome";
  static const String patientHomePage = "/patientHome";

  static final routes = <String, WidgetBuilder>{
    loginPage: (context) => const LoginPage(),
    doctorHomePage: (context) => const DoctorHomePage(),
    patientHomePage: (context) => const PatientHomePage(),
  };
}
