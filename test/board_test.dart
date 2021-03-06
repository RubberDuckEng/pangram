import 'package:test/test.dart';
import 'package:pangram/board.dart';

void main() {
  test('Board ids are sorted', () {
    var board =
        Board(center: 'a', otherLetters: ['z', 'b', 'c'], validWords: []);
    expect(board.id, 'a:bcz');
  });
}
