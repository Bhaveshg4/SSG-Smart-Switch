import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScanner extends StatefulWidget {
  @override
  _BluetoothScannerState createState() => _BluetoothScannerState();
}

class _BluetoothScannerState extends State<BluetoothScanner> {
  BluetoothDevice? _selectedDevice;
  List<BluetoothDevice> _devices = [];
  bool _isDiscovering = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    await _requestPermissions();
    await _checkBluetoothState();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] != PermissionStatus.granted ||
        statuses[Permission.locationWhenInUse] != PermissionStatus.granted) {
      print('Permissions not granted');
    }
  }

  Future<void> _checkBluetoothState() async {
    final bool isEnabled =
        await FlutterBluetoothSerial.instance.isEnabled ?? false;
    if (!isEnabled) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isDiscovering = true;
      _devices = [];
    });

    try {
      final bool isDiscovering =
          await FlutterBluetoothSerial.instance.isDiscovering ?? false;

      if (!isDiscovering) {
        final Stream<BluetoothDiscoveryResult> stream =
            FlutterBluetoothSerial.instance.startDiscovery();
        stream.listen((result) {
          setState(() {
            if (result.device.isBonded) {
              _devices.add(result.device);
            }
          });
        }).onDone(() {
          setState(() {
            _isDiscovering = false;
          });
        });
      } else {
        await FlutterBluetoothSerial.instance.cancelDiscovery();
        setState(() {
          _isDiscovering = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isDiscovering = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
      });
      print('Connected to ${device.name} (${device.address})');
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connect to Smart Switch',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        shadowColor: Colors.black38,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isDiscovering
                      ? [
                          Colors.redAccent.shade200,
                          Colors.redAccent,
                          Colors.red,
                        ]
                      : [
                          Colors.blueAccent.shade200,
                          Colors.blueAccent,
                          Colors.blue,
                        ],
                ),
                borderRadius: BorderRadius.circular(_isDiscovering ? 30 : 15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isDiscovering ? null : _scanForDevices,
                icon: Icon(
                  _isDiscovering ? Icons.cancel : Icons.search,
                  size: 28,
                  color: Colors.white,
                ),
                label: Text(
                  _isDiscovering ? 'Stop Scanning' : 'Scan for Devices',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(_isDiscovering ? 30 : 15),
                  ),
                ),
              ),
            ),
          ),
          const Text(
              textAlign: TextAlign.center,
              "Make sure the smart switch is paired via\n bluetooth setting of smart phone "),
          Expanded(
            child: _devices.isEmpty
                ? const Center(
                    child: Text(
                      'No Devices Found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      BluetoothDevice device = _devices[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading:
                              const Icon(Icons.bluetooth, color: Colors.blue),
                          title: Text(
                            device.name ?? 'Unknown Device',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(device.address),
                          onTap: () {
                            setState(() {
                              _selectedDevice = device;
                            });
                          },
                          trailing: _selectedDevice == device
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          if (_selectedDevice != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isConnecting
                    ? null
                    : () async {
                        await _connectToDevice(_selectedDevice!);
                        if (_connection != null) {
                          // Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => BluetoothActions()));
                          Navigator.of(context).pushNamed(
                            '/chat',
                            arguments: _connection,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 8,
                ),
                child: _isConnecting
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Connect'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}
