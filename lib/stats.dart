import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pangram/board_stats.dart';
import 'package:http/http.dart' as http;

class MaxScoreAllPuzzles extends StatefulWidget {
  final List<Bucket> maxScores;
  MaxScoreAllPuzzles(this.maxScores);

  @override
  State<StatefulWidget> createState() => MaxScoreAllPuzzlesState();
}

class MaxScoreAllPuzzlesState extends State<MaxScoreAllPuzzles> {
  @override
  Widget build(BuildContext context) {
    return BarChart(
      buildBarChartData(),
    );
  }

  BarChartData buildBarChartData() {
    List<BarChartGroupData> barGroups = <BarChartGroupData>[];
    int sum = widget.maxScores.fold(0, (sum, bucket) => sum + bucket.sum);
    for (Bucket bucket in widget.maxScores) {
      barGroups.add(BarChartGroupData(
        x: bucket.first + bucket.last - bucket.first,
        barRods: [
          BarChartRodData(
            y: (bucket.sum.toDouble() / sum),
            colors: [Colors.lightBlueAccent, Colors.greenAccent],
          )
        ],
        showingTooltipIndicators: [0],
      ));
    }

    return BarChartData(
      barGroups: barGroups,
    );
  }
}

class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  BoardStats? _stats;

  @override
  void initState() {
    super.initState();
    initialLoad();
  }

  Future initialLoad() async {
    print("initialLoad");
    String url = "boards/stats.json";
    http.Response response = await http.get(Uri.parse(url));
    BoardStats stats = BoardStats.fromJson(json.decode(response.body));

    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    var bodyChildren = <Widget>[];
    BoardStats? stats = _stats;
    if (stats == null) {
      bodyChildren = <Widget>[Text("Loading...")];
    } else {
      bodyChildren = <Widget>[
        MaxScoreAllPuzzles(stats.maxScores),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Stats"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bodyChildren,
        ),
      ),
    );
  }
}
