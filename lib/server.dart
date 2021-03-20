import 'dart:convert';
import 'dart:math';

import 'board.dart';
import 'manifest.dart';

import 'package:http/http.dart' as http;

class Server {
  Manifest? _cachedManifest;
  static const String boardsDirectory = 'boards';

  Future<dynamic> _fetchJson(String url) async {
    print("Loading $url");
    http.Response response = await http.get(Uri.parse(url));
    return json.decode(response.body);
  }

  Future<Manifest> ensureManifest() async {
    if (_cachedManifest != null) return Future.value(_cachedManifest);
    var jsonManifest = await _fetchJson("$boardsDirectory/manifest.json");
    Manifest manifest = Manifest.fromJson(jsonManifest);
    _cachedManifest = manifest;
    return manifest;
  }

  Future<Board> nextBoard() async {
    Manifest manifest = await ensureManifest();
    int boardIndex = Random().nextInt(manifest.totalBoards);
    int chunkIndex = boardIndex ~/ manifest.chunkSize;
    String chunkName = manifest.chunkNameFromIndex(chunkIndex);
    List<dynamic> chunkJson = await _fetchJson("$boardsDirectory/$chunkName");
    List<Board> chunk =
        chunkJson.map((boardJson) => Board.fromJson(boardJson)).toList();
    int chunkLocalBoardIndex = boardIndex % manifest.chunkSize;
    return chunk[chunkLocalBoardIndex];
  }

  Future<Board?> getBoard(String id) async {
    Manifest manifest = await ensureManifest();
    String? chunkName = manifest.findChunkNameForBoardId(id);
    if (chunkName == null) {
      return null;
    }
    List<dynamic> chunkJson = await _fetchJson("$boardsDirectory/$chunkName");
    List<Board> chunk =
        chunkJson.map((boardJson) => Board.fromJson(boardJson)).toList();

    for (var board in chunk) {
      if (board.id == id) return board;
    }
    return null;
  }
}
