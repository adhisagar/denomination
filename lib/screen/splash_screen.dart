import 'dart:async';

import 'package:denomination/screen/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    startSplashScreenTimer();
  }

  startSplashScreenTimer() async { // Because we using Timer and it is a Future Object, we used async keyword
    var duration = const Duration(seconds: 2);
    return new Timer(duration, navigationToNextPage);

  }


  void navigationToNextPage() async {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>DashboardScreen()), (route)=>false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          body: Center(
            child: SizedBox(
              height: 150,
              width: MediaQuery.of(context).size.width*0.90,
              child: Image.asset('assets/icons/denomination_app_Icon.png',),
            ),
          ).animate()
              .fade() // uses `Animate.defaultDuration`
              .scale()
              .move(delay: 300.ms, duration: 600.ms), // runs after the above w/new duration

        )
    );
  }
}
