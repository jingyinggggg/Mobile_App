import 'package:flutter/material.dart';

typedef onSaveCallBack = Function(int currentpageIndex);

class RowButtons extends StatelessWidget{
  final onSaveCallBack onSave;

  RowButtons({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: 70,
      // padding: EdgeInsets.only(top: 60, bottom: 20),
      decoration: BoxDecoration(
        // color: Color(0xFF467BA1),
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFF467BA1), width: 1.5))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          GestureDetector(
            onTap: (){
              onSave(0);
            },
            child: singleButtonWidget("Converter"),
          ),
          GestureDetector(
            onTap: (){
              onSave(1);
            },
            child: singleButtonWidget("Rates"),
          ),
          GestureDetector(
            onTap: (){
              onSave(2);
            },
            child: singleButtonWidget("Info"),
          )
        ],
      )
    );
  }

  Widget singleButtonWidget(String text){
    return Container(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF467BA1)
        ),
      ),
    );
  }
}