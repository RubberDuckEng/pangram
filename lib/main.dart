import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'board.dart';

// A, B, C, D, E, F, G

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
  final Board board;
  FoundWords({Key? key, required this.foundWords, required this.board})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.lightBlue.shade200,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.all(10),
      constraints: BoxConstraints(minWidth: 200, minHeight: 100),
      child: Text(
          "Found ${foundWords.length} of ${board.validWords.length}:\n${foundWords.join('\n')}"),
    );
  }
}

class PangramGame extends StatefulWidget {
  final Board board;
  final VoidCallback onWin;

  PangramGame({required this.board, required this.onWin})
      // Make the board Key so when the board changes State is dropped.
      : super(key: ObjectKey(board));

  @override
  _PangramGameState createState() => _PangramGameState();
}

class _PangramGameState extends State<PangramGame> {
  String typedWord = "";
  List<int> otherLettersOrder = List<int>.generate(6, (i) => i);

  // TODO: This is really business logic state rather than UI state.
  List<String> foundWords = <String>[];

  void typeLetter(String letter) {
    setState(() {
      typedWord += letter;
    });
  }

  void scramblePressed() {
    setState(() {
      otherLettersOrder.shuffle();
    });
  }

  void deletePressed() {
    setState(() {
      typedWord = typedWord.substring(0, typedWord.length - 1);
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
      var letter = widget.board.otherLetters[otherLettersOrder[i]];
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
        FoundWords(foundWords: foundWords, board: widget.board),
        Text(typedWord),
        CustomMultiChildLayout(delegate: PangramLayout(), children: children),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: typedWord == "" ? null : deletePressed,
                child: Text("DELETE")),
            ElevatedButton(
                onPressed: typedWord == "" ? null : enterPressed,
                child: Text("ENTER")),
            ElevatedButton(onPressed: scramblePressed, child: Text("SCRAMBLE")),
          ],
        ),
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
  List<Board>? _cachedBoards;

  Future<List<Board>> ensureBoards() async {
    if (_cachedBoards != null) return Future.value(_cachedBoards);
    http.Response response = await http.get(Uri.parse("boards.json"));
    var jsonBoards = json.decode(response.body);
    var inflatedBoards =
        jsonBoards.map<Board>((json) => Board.fromJson(json)).toList();
    _cachedBoards = inflatedBoards;
    print("Loaded ${inflatedBoards.length} boards.");
    return inflatedBoards;
  }

  Future<Board> nextBoard() async {
    var boards = await ensureBoards();
    int boardIndex = Random().nextInt(boards.length);
    return boards[boardIndex];
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
        tooltip: 'New Game',
        child: Icon(Icons.refresh_outlined),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
