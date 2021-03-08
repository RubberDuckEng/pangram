List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
  int length = list.length;
  List<List<T>> chunks = <List<T>>[];

  for (int i = 0; i < length; i += chunkSize) {
    var end = (i + chunkSize < length) ? i + chunkSize : length;
    chunks.add(list.sublist(i, end));
  }
  return chunks;
}
