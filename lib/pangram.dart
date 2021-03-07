import 'package:flutter/material.dart';
import 'dart:math';

class HexagonPainter extends CustomPainter {
  final Color color;
  Path? _lastDrawnPath;

  HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var radius = size.shortestSide / 2.0;
    var center = size.center(Offset.zero);

    const angleIncrement = pi / 3.0;
    const count = 6;
    List<Offset> points = [];
    for (int i = 0; i < count; ++i) {
      var angle = i * angleIncrement;
      points.add(center + Offset(cos(angle), sin(angle)) * radius);
    }

    var path = Path();
    path.addPolygon(points, true);
    var paint = Paint();
    paint.color = color;
    canvas.drawPath(path, paint);

    _lastDrawnPath = path;
  }

  @override
  bool? hitTest(Offset position) {
    return _lastDrawnPath?.contains(position);
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class PangramTile extends StatelessWidget {
  final String letter;
  final bool isCenter;
  final ValueChanged<String> onPressed;

  PangramTile(
      {Key? key,
      required this.letter,
      required this.onPressed,
      required this.isCenter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color =
        isCenter ? Colors.deepOrange.shade500 : Colors.yellow.shade800;
    return GestureDetector(
      onTap: () {
        onPressed(letter);
      },
      child: Stack(alignment: AlignmentDirectional.center, children: [
        SizedBox(
          height: 75.0,
          width: 75.0,
          child: CustomPaint(painter: HexagonPainter(color: color)),
        ),
        Text(letter.toUpperCase(), style: TextStyle(fontSize: 24)),
      ]),
    );
  }
}

enum _PangramSlot {
  center,
  first,
  second,
  third,
  fourth,
  fifth,
  sixth,
}

class PangramLayoutDelegate extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    var centerSize =
        layoutChild(_PangramSlot.center, BoxConstraints.loose(size));
    positionChild(_PangramSlot.center,
        size.center(Offset.zero) - centerSize.center(Offset.zero));

    var radius = size.shortestSide / 3.0;
    const angleIncrement = pi / 3.0;
    const satelliteCount = 6;
    for (int i = 0; i < satelliteCount; ++i) {
      var slot = _PangramSlot.values[i + 1]; // The center slot is index 0.
      var satelliteSize = layoutChild(slot, BoxConstraints.loose(size));
      var angle = i * angleIncrement + pi / 6.0;
      var satelliteOffset = size.center(Offset.zero) +
          Offset(cos(angle), sin(angle)) * radius -
          satelliteSize.center(Offset.zero);
      positionChild(slot, satelliteOffset);
    }
  }

  Size getSize(BoxConstraints constraints) => Size(200, 200);

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) => false;
}

class PangramButtons extends StatelessWidget {
  final String center;
  final List<String> otherLetters;
  final ValueChanged<String> typeLetter;

  const PangramButtons({
    Key? key,
    required this.center,
    required this.otherLetters,
    required this.typeLetter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var children = [
      LayoutId(
          id: _PangramSlot.center,
          child: PangramTile(
            letter: center,
            onPressed: typeLetter,
            isCenter: true,
          ))
    ];
    for (var i = 0; i < otherLetters.length; ++i) {
      var letter = otherLetters[i];
      children.add(LayoutId(
          id: _PangramSlot.values[i + 1],
          child: PangramTile(
            letter: letter,
            onPressed: typeLetter,
            isCenter: false,
          )));
    }
    return CustomMultiChildLayout(
        delegate: PangramLayoutDelegate(), children: children);
  }
}
