import 'package:flutter/material.dart';
import 'dart:math';

// A, B, C, D, E, F, G

class Game {
  final String center;
  final List<String> otherLetters;
  final List<String> validWords;

  Game(
      {required this.center,
      required this.otherLetters,
      required this.validWords});
}

// List of possible answers.S

// Some way to input leters
// Some way to list which words they've found.

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pangram Game',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'Pangram'),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;

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
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class PangramTile extends StatelessWidget {
  final String letter;
  final bool isCenter;

  PangramTile({Key? key, required this.letter, required this.isCenter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color =
        isCenter ? Colors.deepOrange.shade500 : Colors.yellow.shade800;
    return Stack(alignment: AlignmentDirectional.center, children: [
      SizedBox(
        height: 75.0,
        width: 75.0,
        child: CustomPaint(painter: HexagonPainter(color: color)),
      ),
      Text(letter),
    ]);
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

class PangramLayout extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    var centerSize =
        layoutChild(_PangramSlot.center, BoxConstraints.loose(size));
    positionChild(_PangramSlot.center,
        size.center(Offset.zero) - centerSize.center(Offset.zero));

    var radius = size.shortestSide / 2.0;
    const angleIncrement = pi / 3.0;
    const satelliteCount = 6;
    for (int i = 0; i < satelliteCount; ++i) {
      var slot = _PangramSlot.values[i + 1]; // The center slot is index 0.
      var satelliteSize = layoutChild(slot, BoxConstraints.loose(size));
      var angle = i * angleIncrement;
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

class PangramGame extends StatelessWidget {
  final Game game;

  PangramGame({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var children = [
      LayoutId(
          id: _PangramSlot.center,
          child: PangramTile(letter: game.center, isCenter: true))
    ];
    for (var i = 0; i < game.otherLetters.length; ++i) {
      var letter = game.otherLetters[i];
      children.add(LayoutId(
          id: _PangramSlot.values[i + 1],
          child: PangramTile(letter: letter, isCenter: false)));
    }
    return CustomMultiChildLayout(
        delegate: PangramLayout(), children: children);
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Game _game = new Game(
      center: "A",
      otherLetters: ["B", "C", "D", "E", "F", "G"],
      validWords: ["FADE"]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PangramGame(game: _game),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
