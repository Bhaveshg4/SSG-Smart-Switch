import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpdateClockB extends StatefulWidget {
  final Function(String) onUpdate;

  const UpdateClockB({required this.onUpdate, super.key});

  @override
  _UpdateClockBState createState() => _UpdateClockBState();
}

class _UpdateClockBState extends State<UpdateClockB> {
  final TextEditingController _periodsController = TextEditingController();
  List<Period> _periods = [];

  void _generatePeriods() {
    int count = int.tryParse(_periodsController.text) ?? 0;
    setState(() {
      _periods = List.generate(count, (_) => Period());
    });
  }

  void _updateClock() {
    if (_periods.isNotEmpty) {
      String periodsCount = _periods.length.toString().padLeft(2, '0');
      StringBuffer messageBuilder = StringBuffer('#SB$periodsCount');

      for (Period period in _periods) {
        messageBuilder.write(
            '*${period.onTimeController.text}&${period.offTimeController.text}\n');
      }

      messageBuilder.write('<CR><LF>');

      widget.onUpdate(messageBuilder.toString());
      _showSuccessPopup();
    }
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Clock has been updated successfully.'),
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
        title: const Text(
          'Communication Protocol B',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _periodsController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Periods',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _generatePeriods,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Generate Periods',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _periods.length,
                      itemBuilder: (context, index) {
                        return PeriodWidget(
                          key: UniqueKey(),
                          period: _periods[index],
                          onRemove: () {
                            setState(() {
                              _periods.removeAt(index);
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade500],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton.icon(
                onPressed: _updateClock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.update, color: Colors.white),
                label: const Text(
                  'Update Clock',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Period {
  TextEditingController onTimeController = TextEditingController();
  TextEditingController offTimeController = TextEditingController();
}

class PeriodWidget extends StatelessWidget {
  final Period period;
  final VoidCallback onRemove;

  const PeriodWidget({
    required Key key,
    required this.period,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: period.onTimeController,
              decoration: const InputDecoration(
                labelText: 'On Time (HH:MM:SS)',
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
              controller: period.offTimeController,
              decoration: const InputDecoration(
                labelText: 'Off Time (HH:MM:SS)',
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
            ElevatedButton(
              onPressed: onRemove,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Remove Period',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
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
