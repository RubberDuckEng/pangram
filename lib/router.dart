import 'package:flutter/material.dart';
import 'package:pangram/game_state.dart';

import 'board.dart';
import 'server.dart';
import 'main.dart';

class PangramApp extends StatefulWidget {
  final Server server;

  PangramApp({required this.server});

  @override
  State<StatefulWidget> createState() => _PangramAppState();
}

class _PangramAppState extends State<PangramApp> {
  late final PangramRouterDelegate _routerDelegate =
      PangramRouterDelegate(server: widget.server);
  final PangramRouteInformationParser _routeInformationParser =
      PangramRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pangram 2.0',
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
    );
  }
}

class PangramRoutePath {
  final String? boardId;
  final bool isUnknown;

  PangramRoutePath.home()
      : boardId = null,
        isUnknown = false;

  PangramRoutePath.board(this.boardId) : isUnknown = false;

  PangramRoutePath.unknown()
      : boardId = null,
        isUnknown = true;

  factory PangramRoutePath.parseBoard(String string) {
    if (Board.isValidId(string)) {
      return PangramRoutePath.board(string);
    }
    return PangramRoutePath.unknown();
  }

  bool get isHomePage => boardId == null;

  bool get isBoardPage => boardId != null;
}

class PangramRouteInformationParser
    extends RouteInformationParser<PangramRoutePath> {
  @override
  Future<PangramRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final path = routeInformation.location ?? "";
    final uri = Uri.parse(path);
    // Handle '/'
    if (uri.pathSegments.isEmpty) {
      return PangramRoutePath.home();
    }

    // Handle '/board/:id'
    if (uri.pathSegments.length == 2) {
      if (uri.pathSegments[0] != 'board') return PangramRoutePath.unknown();
      var remaining = uri.pathSegments[1];
      return PangramRoutePath.parseBoard(remaining);
    }

    // Handle unknown routes
    return PangramRoutePath.unknown();
  }

  @override
  RouteInformation restoreRouteInformation(PangramRoutePath path) {
    if (path.isUnknown) {
      return RouteInformation(location: '/404');
    }
    if (path.isHomePage) {
      return RouteInformation(location: '/');
    }
    if (path.isBoardPage) {
      return RouteInformation(location: '/board/${path.boardId}');
    }
    return RouteInformation();
  }
}

class PangramRouterDelegate extends RouterDelegate<PangramRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<PangramRoutePath> {
  final Server server;

  PangramRouterDelegate({required this.server})
      : navigatorKey = GlobalKey<NavigatorState>();

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  PangramRoutePath _currentPath = PangramRoutePath.home();

  @override
  PangramRoutePath get currentConfiguration => _currentPath;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          key: ValueKey('Home'),
          child: HomeScreen(server: server, routerDelegate: this),
        ),
        if (_currentPath.isUnknown)
          MaterialPage(key: ValueKey('UnknownPage'), child: UnknownScreen())
        else if (_currentPath.isBoardPage)
          MaterialPage(
              key: ValueKey('BoardPage'),
              child: BoardScreen(server: server, id: _currentPath.boardId!))
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        // Update the list of pages by setting _selectedBook to null
        _currentPath = PangramRoutePath.home();
        notifyListeners();
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(PangramRoutePath path) async {
    _currentPath = path;
  }

  void showBoard(Board board) {
    _currentPath = PangramRoutePath.board(board.id);
    notifyListeners();
  }
}

class UnknownScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text('404!'),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Server server;
  final PangramRouterDelegate routerDelegate;

  HomeScreen({required this.server, required this.routerDelegate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            routerDelegate.showBoard(await server.nextBoard());
            // Navigator.of(context) ...
          },
          child: Text('PLAY'),
        ),
      ),
    );
  }
}

class BoardScreen extends StatefulWidget {
  final Server server;
  final String id;

  BoardScreen({required this.id, required this.server});

  @override
  _BoardScreenState createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  GameState? _game;

  @override
  void initState() {
    super.initState();
    initialLoad();
  }

  Future initialLoad() async {
    Board? board = await widget.server.getBoard(widget.id);
    // TODO: This is a hack.
    if (board != null) {
      setState(() {
        _game = GameState(board);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    GameState? game = _game;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
          child: game == null
              ? Text("Loading...")
              : PangramGame(game: game, onWin: () {})),
    );
  }
}
