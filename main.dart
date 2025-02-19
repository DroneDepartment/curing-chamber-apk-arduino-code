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

          // Replace "DC" with "°C" for numbers in lcdText
          lcdText[0] = lcdText[0].replaceAllMapped(RegExp(r'(\d+)DC'), (match) {
            return "${match.group(1)}°C"; // Correctly format the result as "109°C"
          });
          lcdText[1] = lcdText[1].replaceAllMapped(RegExp(r'(\d+)DC'), (match) {
            return "${match.group(1)}°C"; // Same for row2
          });

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

  // Send the button label to the ESP32 server
  Future<void> sendButtonPress(String buttonLabel) async {
    try {
      final response =
          await http.get(Uri.parse('$esp32Ip/button?button=$buttonLabel'));
      if (response.statusCode == 200) {
        print("Button pressed: $buttonLabel");
      } else {
        print("Failed to send button press");
      }
    } catch (e) {
      print("Error sending button press: $e");
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
                    label: "Connection",
                    color: isConnected
                        ? const Color.fromARGB(255, 19, 119, 23)
                        : const Color.fromARGB(255, 248, 6, 6)),
                StatusBulb(
                    label: "Heater",
                    color: heaterOn
                        ? const Color.fromARGB(255, 19, 119, 23)
                        : const Color.fromARGB(255, 248, 6, 6)),
                StatusBulb(
                    label: "Fan",
                    color: fanOn
                        ? const Color.fromARGB(255, 19, 119, 23)
                        : const Color.fromARGB(255, 248, 6, 6)),
              ],
            ),
            SizedBox(height: 20),
            Container(
              width: 300,
              height: 80,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 243, 247, 2),
                border: Border.all(
                    color: const Color.fromARGB(255, 15, 15, 15), width: 4),
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
                      color: const Color.fromARGB(255, 7, 7, 7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    lcdText[1],
                    style: TextStyle(
                      fontFamily: "Courier",
                      fontSize: 20,
                      color: const Color.fromARGB(255, 7, 7, 7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Buttons Section - Updated Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ButtonCard(
                        buttonLabel: "Enter",
                        icon: Icons.keyboard_return,
                        onPressed: () => sendButtonPress("Enter"),
                      ),
                      ButtonCard(
                        buttonLabel: "Down",
                        icon: Icons.arrow_downward,
                        onPressed: () => sendButtonPress("Down"),
                      ),
                      ButtonCard(
                        buttonLabel: "Up",
                        icon: Icons.arrow_upward,
                        onPressed: () => sendButtonPress("Up"),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ButtonCard(
                        buttonLabel: "Accept",
                        icon: Icons.check,
                        onPressed: () => sendButtonPress("Accept"),
                      ),
                      ButtonCard(
                        buttonLabel: "Clear",
                        icon: Icons.clear,
                        onPressed: () => sendButtonPress("Clear"),
                      ),
                      ButtonCard(
                        buttonLabel: "Back",
                        icon: Icons.arrow_back,
                        onPressed: () => sendButtonPress("Back"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        Text(label,
            style: TextStyle(
                fontSize: 16, color: const Color.fromARGB(255, 7, 7, 7))),
      ],
    );
  }
}

class ButtonCard extends StatelessWidget {
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  ButtonCard(
      {required this.buttonLabel, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: const Color.fromARGB(255, 14, 17, 238),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: const Color.fromARGB(255, 14, 17, 238),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.white),
              SizedBox(height: 8),
              Text(
                buttonLabel,
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
