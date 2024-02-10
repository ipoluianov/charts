import 'history_node.dart';

class History {
  Map<String, HistoryNode> nodes = {};

  History() {}

  HistoryNode getNode(String conn) {
    HistoryNode node = HistoryNode(conn);
    if (nodes.containsKey(conn)) {
      var n = nodes[conn];
      if (n != null) {
        node = n;
      }
    } else {
      nodes[conn] = node;
    }
    return node;
  }
}
