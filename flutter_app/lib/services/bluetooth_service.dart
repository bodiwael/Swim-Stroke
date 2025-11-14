import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum BluetoothConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

enum RecordingState {
  idle,
  recording,
  downloading,
  processing,
}

class BluetoothService extends ChangeNotifier {
  BluetoothConnection? _connection;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  RecordingState _recordingState = RecordingState.idle;

  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _connectedDevice;

  String _statusMessage = '';
  String _errorMessage = '';

  // File transfer variables
  bool _receivingFile = false;
  int _expectedFileSize = 0;
  String _fileName = '';
  List<int> _fileBuffer = [];

  // Getters
  BluetoothConnectionState get connectionState => _connectionState;
  RecordingState get recordingState => _recordingState;
  List<BluetoothDevice> get devicesList => _devicesList;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String get statusMessage => _statusMessage;
  String get errorMessage => _errorMessage;

  bool get isConnected => _connectionState == BluetoothConnectionState.connected;
  bool get isRecording => _recordingState == RecordingState.recording;

  // Initialize Bluetooth
  Future<void> initialize() async {
    try {
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled == null || !isEnabled) {
        await FlutterBluetoothSerial.instance.requestEnable();
      }
    } catch (e) {
      _setError('Bluetooth initialization failed: $e');
    }
  }

  // Scan for devices
  Future<void> scanForDevices() async {
    try {
      _devicesList = [];
      notifyListeners();

      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      _devicesList = devices;
      notifyListeners();
    } catch (e) {
      _setError('Device scan failed: $e');
    }
  }

  // Connect to device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _connectionState = BluetoothConnectionState.connecting;
      _statusMessage = 'Connecting to ${device.name}...';
      notifyListeners();

      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      _connectionState = BluetoothConnectionState.connected;
      _statusMessage = 'Connected to ${device.name}';

      // Listen for incoming data
      _connection!.input!.listen(
        _handleIncomingData,
        onDone: () {
          _disconnect();
        },
        onError: (error) {
          _setError('Connection error: $error');
          _disconnect();
        },
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Connection failed: $e');
      _connectionState = BluetoothConnectionState.error;
      notifyListeners();
      return false;
    }
  }

  // Disconnect
  Future<void> disconnect() async {
    await _disconnect();
  }

  Future<void> _disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      _connectedDevice = null;
      _connectionState = BluetoothConnectionState.disconnected;
      _statusMessage = 'Disconnected';
      notifyListeners();
    } catch (e) {
      _setError('Disconnect error: $e');
    }
  }

  // Send command
  Future<void> sendCommand(String command) async {
    if (_connection == null || !_connection!.isConnected) {
      _setError('Not connected to device');
      return;
    }

    try {
      _connection!.output.add(Uint8List.fromList('$command\n'.codeUnits));
      await _connection!.output.allSent;
      debugPrint('Sent command: $command');
    } catch (e) {
      _setError('Failed to send command: $e');
    }
  }

  // Start recording
  Future<void> startRecording() async {
    await sendCommand('SS');
    _recordingState = RecordingState.recording;
    _statusMessage = 'Recording started';
    notifyListeners();
  }

  // Stop recording and download data
  Future<void> stopRecording() async {
    await sendCommand('ST');
    _recordingState = RecordingState.downloading;
    _statusMessage = 'Downloading data...';
    _fileBuffer.clear();
    notifyListeners();
  }

  // Request status
  Future<void> requestStatus() async {
    await sendCommand('STATUS');
  }

  // Delete last file
  Future<void> deleteLastFile() async {
    await sendCommand('DELETE');
  }

  // Handle incoming data
  void _handleIncomingData(Uint8List data) {
    if (_receivingFile) {
      _receiveFileData(data);
    } else {
      _handleTextData(data);
    }
  }

  void _handleTextData(Uint8List data) {
    String message = String.fromCharCodes(data).trim();
    debugPrint('Received: $message');

    if (message.startsWith('FILE_START')) {
      _receivingFile = true;
      _fileBuffer.clear();
      _statusMessage = 'Receiving file...';
      notifyListeners();
    } else if (message.startsWith('SIZE:')) {
      _expectedFileSize = int.tryParse(message.substring(5)) ?? 0;
      debugPrint('Expected file size: $_expectedFileSize bytes');
    } else if (message.startsWith('NAME:')) {
      _fileName = message.substring(5);
      debugPrint('File name: $_fileName');
    } else if (message.startsWith('OK:')) {
      _statusMessage = message.substring(3);
      notifyListeners();
    } else if (message.startsWith('ERROR:')) {
      _setError(message.substring(6));
    } else if (message.startsWith('STATUS:')) {
      _statusMessage = message.substring(7);
      notifyListeners();
    }
  }

  void _receiveFileData(Uint8List data) {
    String dataString = String.fromCharCodes(data);

    if (dataString.contains('FILE_END')) {
      _receivingFile = false;
      _recordingState = RecordingState.processing;
      _statusMessage = 'File received: ${_fileBuffer.length} bytes';
      debugPrint('File transfer complete: ${_fileBuffer.length} bytes');

      // Trigger callback with file data
      _onFileReceived(_fileBuffer);

      notifyListeners();
    } else {
      _fileBuffer.addAll(data);

      // Update progress
      if (_expectedFileSize > 0) {
        double progress = (_fileBuffer.length / _expectedFileSize) * 100;
        _statusMessage = 'Downloading: ${progress.toStringAsFixed(1)}%';
        notifyListeners();
      }
    }
  }

  // File received callback
  Function(List<int>)? onFileReceived;

  void _onFileReceived(List<int> fileData) {
    if (onFileReceived != null) {
      onFileReceived!(fileData);
    }
  }

  // Set recording state back to idle
  void resetRecordingState() {
    _recordingState = RecordingState.idle;
    _statusMessage = '';
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _statusMessage = '';
    debugPrint('Error: $message');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}
