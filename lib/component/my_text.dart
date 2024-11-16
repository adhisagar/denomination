
import 'package:flutter/material.dart';

class MyText extends StatelessWidget {
  String? title;
  double? fontSize;
  FontWeight? fontWeight;
  Color? color;
  TextAlign textAlign;
  int isOverflow;


  MyText({super.key,required this.title, this.fontSize,this.fontWeight,this.color,this.textAlign=TextAlign.start,this.isOverflow=0});

  @override
  Widget build(BuildContext context) {
    return Text(title!,style: TextStyle(fontSize: fontSize,fontWeight: fontWeight,color: color,),textAlign: textAlign,overflow: isOverflow==0?TextOverflow.visible:TextOverflow.ellipsis,);
  }
}
