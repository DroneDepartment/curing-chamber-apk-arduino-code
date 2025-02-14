import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> lcdText = ["Connecting...", ""];
  final String esp32Ip = "http://192.168.1.117"; // Change to your ESP32 IP
  bool isConnected = false;
  bool heaterOn = false;
  bool fanOn = false;

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 2), (timer) => fetchLcdText());
  }

  Future<void> fetchLcdText() async {
    try {
      final response = await http.get(Uri.parse('$esp32Ip/lcd'));
      if (response.statusCode == 200) {
        setState(() {
          lcdText = response.body.split("\n");
          if (lcdText.length < 2) lcdText.add("");
          isConnected = true;
        });
      } else {
        setState(() {
          lcdText = ["Error Fetching Data", ""];
          isConnected = false;
        });
      }

      // Fetch fan status
      final fanResponse =
          await http.get(Uri.parse('$esp32Ip/run_fan?state=check'));
      if (fanResponse.statusCode == 200) {
        setState(() {
          fanOn = fanResponse.body.contains("ON");
        });
      }

      // Fetch heater status
      final heaterResponse =
          await http.get(Uri.parse('$esp32Ip/run_heater?state=check'));
      if (heaterResponse.statusCode == 200) {
        setState(() {
          heaterOn = heaterResponse.body.contains("ON");
        });
      }
    } catch (e) {
      setState(() {
        lcdText = ["Error Fetching Data", ""];
        isConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Image.asset('assets/logo.png', height: 40),
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatusBulb(
                    label: "Connected",
                    color: isConnected ? Colors.green : Colors.red),
                StatusBulb(
                    label: "Heater",
                    color: heaterOn ? Colors.green : Colors.red),
                StatusBulb(
                    label: "Fan", color: fanOn ? Colors.green : Colors.red),
              ],
            ),
            SizedBox(height: 20),
            Container(
              width: 300,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lcdText[0],
                    style: TextStyle(
                      fontFamily: "Courier",
                      fontSize: 20,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    lcdText[1],
                    style: TextStyle(
                      fontFamily: "Courier",
                      fontSize: 20,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class StatusBulb extends StatelessWidget {
  final String label;
  final Color color;

  StatusBulb({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.lightbulb, size: 40, color: color),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.blue)),
      ],
    );
  }
}
