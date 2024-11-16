
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'my_text.dart';

class Helper{


  void showToast(BuildContext context,String message){
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.white,
        textColor: Colors.black,
        fontSize: 15.0
    );


  }
}