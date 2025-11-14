import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_processor.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final TextEditingController _poolLengthController = TextEditingController();
  final TextEditingController _lapsController = TextEditingController();

  @override
  void dispose() {
    _poolLengthController.dispose();
    _lapsController.dispose();
    super.dispose();
  }

  void _addPoolInfo() {
    final dataProcessor = Provider.of<DataProcessor>(context, listen: false);

    double? poolLength = double.tryParse(_poolLengthController.text);
    int? laps = int.tryParse(_lapsController.text);

    if (poolLength != null && laps != null && poolLength > 0 && laps > 0) {
      dataProcessor.addPoolInfo(poolLength, laps);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid values')),
      );
    }
  }

  void _showPoolInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pool Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _poolLengthController,
              decoration: const InputDecoration(
                labelText: 'Pool Length (meters)',
                hintText: '25 or 50',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lapsController,
              decoration: const InputDecoration(
                labelText: 'Number of Laps',
                hintText: 'e.g., 20',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addPoolInfo,
            child: const Text('Calculate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: Consumer<DataProcessor>(
        builder: (context, dataProcessor, child) {
          if (dataProcessor.isProcessing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing your session...'),
                ],
              ),
            );
          }

          if (dataProcessor.metrics == null) {
            return const Center(
              child: Text('No data available'),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metrics Summary Cards
                  _buildMetricsSummary(dataProcessor.metrics!),

                  const SizedBox(height: 24),

                  // Add Pool Info Button
                  if (dataProcessor.metrics!.poolLength == null)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _showPoolInfoDialog,
                        icon: const Icon(Icons.pool),
                        label: const Text('Add Pool Info for Stroke Length'),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Signal Visualization
                  _buildSignalChart(dataProcessor),

                  const SizedBox(height: 24),

                  // Stroke Times Chart
                  _buildStrokeTimesChart(dataProcessor.metrics!),

                  const SizedBox(height: 24),

                  // Detailed Metrics
                  _buildDetailedMetrics(dataProcessor.metrics!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsSummary(SwimSessionMetrics metrics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Strokes',
                metrics.totalStrokes.toString(),
                Icons.gesture,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Duration',
                '${(metrics.sessionDuration / 60).toStringAsFixed(1)} min',
                Icons.timer,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Stroke Time',
                '${metrics.averageStrokeTime.toStringAsFixed(2)}s',
                Icons.speed,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Stroke Rate',
                '${metrics.strokeRate.toStringAsFixed(1)} /min',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),
        if (metrics.strokeLength != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Stroke Length',
                  '${metrics.strokeLength!.toStringAsFixed(2)} m',
                  Icons.straighten,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Avg Speed',
                  '${metrics.averageSpeed!.toStringAsFixed(2)} m/s',
                  Icons.rowing,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalChart(DataProcessor dataProcessor) {
    List<double> signal = dataProcessor.getProcessedSignal();
    List<int> timestamps = dataProcessor.getTimestamps();
    List<StrokePeak> peaks = dataProcessor.metrics!.peaks;

    if (signal.isEmpty) return const SizedBox();

    // Downsample for better performance
    int downsampleFactor = (signal.length / 500).ceil();
    List<FlSpot> spots = [];

    for (int i = 0; i < signal.length; i += downsampleFactor) {
      double time = timestamps[i] / 1000.0; // Convert to seconds
      spots.add(FlSpot(time, signal[i]));
    }

    // Peak markers
    List<FlSpot> peakSpots = peaks.map((peak) {
      double time = peak.timestamp / 1000.0;
      return FlSpot(time, peak.value);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rotation Signal with Detected Strokes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}s',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // Signal line
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    verticalLines: peaks.map((peak) {
                      return VerticalLine(
                        x: peak.timestamp / 1000.0,
                        color: Colors.red.withOpacity(0.5),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 3,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                const Text('Rotation Signal', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(
                  width: 20,
                  height: 3,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                const Text('Detected Strokes', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrokeTimesChart(SwimSessionMetrics metrics) {
    if (metrics.strokeTimes.isEmpty) return const SizedBox();

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < metrics.strokeTimes.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: metrics.strokeTimes[i],
              color: Colors.blue,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stroke Cycle Times',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(1)}s',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics(SwimSessionMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Total Session Time',
                '${(metrics.sessionDuration / 60).toStringAsFixed(2)} minutes'),
            _buildDetailRow('Total Strokes', '${metrics.totalStrokes}'),
            _buildDetailRow('Average Stroke Cycle Time',
                '${metrics.averageStrokeTime.toStringAsFixed(2)} seconds'),
            _buildDetailRow('Stroke Rate',
                '${metrics.strokeRate.toStringAsFixed(1)} strokes/min'),
            if (metrics.poolLength != null) ...[
              const Divider(),
              _buildDetailRow('Pool Length', '${metrics.poolLength} meters'),
              _buildDetailRow('Number of Laps', '${metrics.laps}'),
              _buildDetailRow('Total Distance',
                  '${(metrics.poolLength! * metrics.laps!).toStringAsFixed(0)} meters'),
              _buildDetailRow('Average Stroke Length',
                  '${metrics.strokeLength!.toStringAsFixed(2)} meters'),
              _buildDetailRow('Average Swimming Speed',
                  '${metrics.averageSpeed!.toStringAsFixed(2)} m/s'),
              _buildDetailRow(
                'Pace',
                '${(1000 / (metrics.averageSpeed! * 60)).toStringAsFixed(2)} min/km',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
