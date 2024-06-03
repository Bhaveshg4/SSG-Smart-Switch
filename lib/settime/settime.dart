import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class SetTime extends StatefulWidget {
  final BluetoothConnection connection;
  final void Function(String time, String date) onSetTime;

  const SetTime({super.key, required this.connection, required this.onSetTime});

  @override
  _SetTimeState createState() => _SetTimeState();
}

class _SetTimeState extends State<SetTime> {
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  void _sendMessage(String text) async {
    if (text.isNotEmpty && widget.connection.isConnected) {
      try {
        widget.connection.output
            .add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await widget.connection.output.allSent;
        _showSuccessPopup();
      } catch (e) {
        // Handle error
      }
    }
  }

  void _setTime() {
    final time = _timeController.text.trim();
    final date = _dateController.text.trim();
    if (time.isNotEmpty && date.isNotEmpty) {
      final message = '#ST$time,$date<CR><LF>';
      _sendMessage(message);
    } else {
      // Optionally, show an error message or handle invalid input
    }
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Time and Date have been set successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Time and Date'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (HH:MM:SS)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'\d+')),
                  TimeInputFormatter(),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (DD/MM/YYYY)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'\d+')),
                  DateInputFormatter(),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _setTime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 16.0,
                  ),
                ),
                child: const Text(
                  'Set Time',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom input formatter to enforce HH:MM:SS format
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    int offset = 0;

    if (newText.length >= 2) {
      buffer.write(newText.substring(0, 2) + ':');
      offset = 3;
    } else if (newText.isNotEmpty) {
      buffer.write(newText);
      offset = newText.length;
    }

    if (newText.length >= 4) {
      buffer.write(newText.substring(2, 4) + ':');
      offset = 6;
    } else if (newText.length > 2) {
      buffer.write(newText.substring(2));
      offset = newText.length + 1;
    }

    if (newText.length >= 6) {
      buffer.write(newText.substring(4, 6));
      offset = 8;
    } else if (newText.length > 4) {
      buffer.write(newText.substring(4));
      offset = newText.length + 2;
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

// Custom input formatter to enforce DD/MM/YYYY format
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    int offset = 0;

    if (newText.length >= 2) {
      buffer.write(newText.substring(0, 2) + '/');
      offset = 3;
    } else if (newText.isNotEmpty) {
      buffer.write(newText);
      offset = newText.length;
    }

    if (newText.length >= 4) {
      buffer.write(newText.substring(2, 4) + '/');
      offset = 6;
    } else if (newText.length > 2) {
      buffer.write(newText.substring(2));
      offset = newText.length + 1;
    }

    if (newText.length >= 8) {
      buffer.write(newText.substring(4, 8));
      offset = 10;
    } else if (newText.length > 4) {
      buffer.write(newText.substring(4));
      offset = newText.length + 2;
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
