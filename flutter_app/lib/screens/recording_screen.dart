import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/data_processor.dart';
import 'results_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupFileReceivedCallback();
    _startTimerIfRecording();
    // Defer state reset until after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetSessionState();
    });
  }

  void _startTimerIfRecording() {
    // If recording is already in progress (user reconnected), start the UI timer
    final btService = Provider.of<BluetoothService>(context, listen: false);
    if (btService.isRecording && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          // Timer just triggers UI updates, elapsed time is calculated from start time
        });
      });
    }
  }

  void _resetSessionState() {
    // Reset recording state and clear old data only if previous session is complete
    final btService = Provider.of<BluetoothService>(context, listen: false);
    final dataProcessor = Provider.of<DataProcessor>(context, listen: false);

    // Only reset if we're coming from a completed session (processing state)
    // Don't reset if user is in the middle of recording and just reconnected
    if (btService.recordingState == RecordingState.processing ||
        btService.recordingState == RecordingState.downloading) {
      btService.resetRecordingState();
      dataProcessor.reset();
    }
  }

  void _setupFileReceivedCallback() {
    final btService = Provider.of<BluetoothService>(context, listen: false);
    final dataProcessor = Provider.of<DataProcessor>(context, listen: false);

    btService.onFileReceived = (fileData) async {
      // Process the received data
      await dataProcessor.processFileData(fileData);

      // Navigate to results screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ResultsScreen(),
          ),
        );
      }
    };
  }

  void _startRecording() {
    final btService = Provider.of<BluetoothService>(context, listen: false);
    final dataProcessor = Provider.of<DataProcessor>(context, listen: false);

    // Clear any previous session data before starting
    dataProcessor.reset();

    btService.startRecording();

    // Start timer for UI updates
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Timer just triggers UI updates, elapsed time is calculated from start time
      });
    });
  }

  void _stopRecording() {
    final btService = Provider.of<BluetoothService>(context, listen: false);
    btService.stopRecording();

    // Stop timer
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _getElapsedSeconds(BluetoothService btService) {
    if (btService.recordingStartTime == null) return 0;
    return DateTime.now().difference(btService.recordingStartTime!).inSeconds;
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording Session'),
      ),
      body: Consumer<BluetoothService>(
        builder: (context, btService, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Icon
                  _buildStatusIcon(btService.recordingState),

                  const SizedBox(height: 32),

                  // Timer
                  if (btService.isRecording)
                    Text(
                      _formatDuration(_getElapsedSeconds(btService)),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatureSettings: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                    ),

                  const SizedBox(height: 16),

                  // Status Text
                  Text(
                    _getStatusText(btService.recordingState),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  if (btService.statusMessage.isNotEmpty)
                    Text(
                      btService.statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 48),

                  // Instructions
                  _buildInstructions(btService.recordingState),

                  const SizedBox(height: 48),

                  // Control Buttons
                  _buildControlButtons(btService),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(RecordingState state) {
    IconData icon;
    Color color;

    switch (state) {
      case RecordingState.recording:
        icon = Icons.circle;
        color = Colors.red;
        break;
      case RecordingState.downloading:
        icon = Icons.download;
        color = Colors.blue;
        break;
      case RecordingState.processing:
        icon = Icons.analytics;
        color = Colors.orange;
        break;
      default:
        icon = Icons.pool;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 80, color: color),
    );
  }

  String _getStatusText(RecordingState state) {
    switch (state) {
      case RecordingState.recording:
        return 'Recording in Progress';
      case RecordingState.downloading:
        return 'Downloading Data';
      case RecordingState.processing:
        return 'Processing Results';
      default:
        return 'Ready to Record';
    }
  }

  Widget _buildInstructions(RecordingState state) {
    String instructions;

    switch (state) {
      case RecordingState.idle:
        instructions =
            '1. Press START to begin recording\n2. Device will disconnect (waterproof mode)\n3. Go swim!\n4. After swimming, reconnect and press STOP';
        break;
      case RecordingState.recording:
        instructions =
            'Recording is active. The device will continue recording even when disconnected.\n\nAfter your swim, reconnect to the device and press STOP.';
        break;
      case RecordingState.downloading:
        instructions = 'Please wait while data is being downloaded from the device...';
        break;
      case RecordingState.processing:
        instructions = 'Analyzing your swimming session...';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        instructions,
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildControlButtons(BluetoothService btService) {
    if (btService.recordingState == RecordingState.downloading ||
        btService.recordingState == RecordingState.processing) {
      return const CircularProgressIndicator();
    }

    if (btService.isRecording) {
      return ElevatedButton.icon(
        onPressed: _stopRecording,
        icon: const Icon(Icons.stop, size: 32),
        label: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text('STOP RECORDING', style: TextStyle(fontSize: 18)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _startRecording,
          icon: const Icon(Icons.play_arrow, size: 32),
          label: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text('START RECORDING', style: TextStyle(fontSize: 18)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
