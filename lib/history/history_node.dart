import '../time_chart/history.dart';
import 'history_loading_task.dart';

class HistoryNode {
  final String connection;

  HistoryNode(this.connection);

  List<DataItemHistoryChartItemValueResponse> getHistory(
      String itemName, int minTime, int maxTime, int groupTimeRange) {
    List<DataItemHistoryChartItemValueResponse> res = [];
    return res;
  }

  List<HistoryLoadingTask> getLoadingTasks(String itemName) {
    List<HistoryLoadingTask> res = [];
    return res;
  }
}
