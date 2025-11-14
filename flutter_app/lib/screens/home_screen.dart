import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/data_processor.dart';
import 'recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    final btService = Provider.of<BluetoothService>(context, listen: false);
    await btService.initialize();
    await btService.scanForDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swim Stroke Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final btService =
                  Provider.of<BluetoothService>(context, listen: false);
              btService.scanForDevices();
            },
          ),
        ],
      ),
      body: Consumer<BluetoothService>(
        builder: (context, btService, child) {
          return Column(
            children: [
              // Connection Status Card
              _buildConnectionCard(btService),

              // Device List or Recording Controls
              Expanded(
                child: btService.isConnected
                    ? _buildConnectedView(btService)
                    : _buildDeviceList(btService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectionCard(BluetoothService btService) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (btService.connectionState) {
      case BluetoothConnectionState.connected:
        statusColor = Colors.green;
        statusIcon = Icons.bluetooth_connected;
        statusText = 'Connected to ${btService.connectedDevice?.name ?? "Device"}';
        break;
      case BluetoothConnectionState.connecting:
        statusColor = Colors.orange;
        statusIcon = Icons.bluetooth_searching;
        statusText = 'Connecting...';
        break;
      case BluetoothConnectionState.error:
        statusColor = Colors.red;
        statusIcon = Icons.bluetooth_disabled;
        statusText = 'Connection Error';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.bluetooth;
        statusText = 'Not Connected';
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (btService.statusMessage.isNotEmpty)
                        Text(
                          btService.statusMessage,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (btService.isConnected)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => btService.disconnect(),
                  ),
              ],
            ),
            if (btService.errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  btService.errorMessage,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(BluetoothService btService) {
    if (btService.devicesList.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bluetooth_searching,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No paired devices found'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => btService.scanForDevices(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: btService.devicesList.length,
      itemBuilder: (context, index) {
        final device = btService.devicesList[index];
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(device.name ?? 'Unknown Device'),
          subtitle: Text(device.address),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            bool connected = await btService.connectToDevice(device);
            if (connected && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connected successfully')),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildConnectedView(BluetoothService btService) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pool, size: 100, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Ready to Track',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Your device is connected and ready to record swimming sessions',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecordingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow, size: 32),
                label: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text(
                    'Start New Session',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  btService.requestStatus();
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Check Device Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
