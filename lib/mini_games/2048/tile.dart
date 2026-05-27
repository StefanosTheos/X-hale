import 'package:flutter/material.dart';
import 'mycolor.dart';

class Tile extends StatelessWidget {
  final String number;
  final double width;
  final double height;
  final Color color;
  final double size;

  const Tile(
    this.number,
    this.width,
    this.height,
    this.color,
    this.size, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: MyColor.fontColorTwoFour,
          ),
        ),
      ),
    );
  }
}
