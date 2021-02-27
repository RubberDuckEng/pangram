import 'package:flutter/material.dart';
import 'dart:math';

// A, B, C, D, E, F, G

class Board {
  final String center;
  final List<String> otherLetters;
  final List<String> validWords;

  Board(
      {required this.center,
      required this.otherLetters,
      required this.validWords});
}

// List of possible answers.S

// Some way to input leters
// Some way to list which words they've found.

void main() {
  final Server server = Server();
  runApp(MyApp(server: server));
}

class MyApp extends StatelessWidget {
  final Server server;
  MyApp({required this.server});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pangram Game',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'Pangram', server: server),
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

  // TODO: Hit test within the hexagon.
  // @override
  // bool? hitTest(Offset position) {}

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
        Text(letter),
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

class PangramLayout extends MultiChildLayoutDelegate {
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

class FoundWords extends StatelessWidget {
  final List<String> foundWords;
  FoundWords({Key? key, required this.foundWords}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(foundWords.join(", "));
  }
}

class PangramGame extends StatefulWidget {
  final Board board;
  final VoidCallback onWin;

  PangramGame({Key? key, required this.board, required this.onWin})
      : super(key: key);

  @override
  _PangramGameState createState() => _PangramGameState();
}

class _PangramGameState extends State<PangramGame> {
  String typedWord = "";

  // TODO: This is really business logic state rather than UI state.
  List<String> foundWords = <String>[];

  void typeLetter(String letter) {
    setState(() {
      typedWord += letter;
    });
  }

  void enterPressed() {
    setState(() {
      var guessedWord = typedWord;
      typedWord = "";

      if (foundWords.contains(guessedWord)) {
        final snackBar =
            SnackBar(content: Text('Already found "$guessedWord"'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }

      if (!widget.board.validWords.contains(guessedWord)) {
        final snackBar =
            SnackBar(content: Text('"$guessedWord" is not a valid word'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }

      foundWords.add(guessedWord);
    });

    if (foundWords.length == widget.board.validWords.length) {
      widget.onWin();
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = [
      LayoutId(
          id: _PangramSlot.center,
          child: PangramTile(
            letter: widget.board.center,
            onPressed: typeLetter,
            isCenter: true,
          ))
    ];
    for (var i = 0; i < widget.board.otherLetters.length; ++i) {
      var letter = widget.board.otherLetters[i];
      children.add(LayoutId(
          id: _PangramSlot.values[i + 1],
          child: PangramTile(
            letter: letter,
            onPressed: typeLetter,
            isCenter: false,
          )));
    }
    return Column(
      children: [
        FoundWords(foundWords: foundWords),
        Text(typedWord),
        CustomMultiChildLayout(delegate: PangramLayout(), children: children),
        ElevatedButton(
            onPressed: typedWord == "" ? null : enterPressed,
            child: Text("ENTER")),
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title, required this.server}) : super(key: key);
  final String? title;
  final Server server;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Server {
  Future<Board> nextBoard() async {
    return Future.delayed(
      new Duration(milliseconds: 500),
      () {
        return Board(
            center: "A",
            otherLetters: ["B", "C", "D", "E", "F", "G"],
            validWords: ["FADE"]);
      },
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  Board? _board;

  // TODO: This belongs outside of this widget.
  @override
  void initState() {
    super.initState();
    getNextBoard();
  }

  Future getNextBoard() async {
    Board board = await widget.server.nextBoard();
    if (!mounted) {
      return;
    }
    setState(() {
      _board = board;
    });
  }

  void onWin() {
    if (_board == null) {
      return;
    }

    final snackBar = SnackBar(content: Text('A winner is you 🎉'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    setState(() {
      _board = null;
    });
    getNextBoard();
  }

  void onNextGame() {
    if (_board == null) {
      return;
    }

    setState(() {
      _board = null;
    });
    getNextBoard();
  }

  @override
  Widget build(BuildContext context) {
    Board? board = _board;
    var body = (board == null)
        ? Text("Loading...")
        : PangramGame(board: board, onWin: onWin);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            body,
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onNextGame,
        tooltip: 'Next Game',
        child: Icon(Icons.skip_next),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
