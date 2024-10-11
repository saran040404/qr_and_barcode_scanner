import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TicketCheckInPage(),
    );
  }
}

class TicketCheckInPage extends StatefulWidget {
  @override
  _TicketCheckInPageState createState() => _TicketCheckInPageState();
}

class _TicketCheckInPageState extends State<TicketCheckInPage> {
  String scannedData = "Scana QR or barcode";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ticket Check-In"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _scanCodeAndNavigate(context),
              child: Text("Scan QR/Barcode"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanCodeAndNavigate(BuildContext context) async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        scannedData = result.rawContent;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayDataPage(scannedData: scannedData),
        ),
      );
    } catch (e) {
      print('Error scanning QR/barcode: $e');
    }
  }
}

class DisplayDataPage extends StatelessWidget {
  final String scannedData;

  DisplayDataPage({required this.scannedData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Display Data"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Scanned Data: $scannedData",
              style: TextStyle(fontSize: 20),
            ),
            TextFormField(
              onChanged: ,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _checkIn(scannedData, context),
              child: Text("Check In"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkIn(String data, BuildContext context) async {
    final String serverUrl = "http://192.168.73.63:5000"; // Corrected server URL
    final Map<String, String> headers = {"Content-Type": "application/json"};
    final Map<String, dynamic> body = {"user_id": data};

    try {
      var response = await http.post(
        Uri.parse('$serverUrl/check_in'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print("Server Response: ${response.body}");
        var message = json.decode(response.body)["message"];

        if (message == 'User not found') {
          _showAlert(context, "User not found", Colors.red);
        } else if (message == 'Already Checked In') {
          _showAlert(context, "Already Checked In", Colors.red);
        } else if (message == 'Check-in Successful') {
          await _updateStatus(serverUrl, data, context);
          _showAlert(context, "Check-in Successful", Colors.green);
        } else {
          _showAlert(context, "$message", Colors.red);
        }
      } else {
        _showAlert(context, "User Not Found", Colors.red);
      }
    } catch (e) {
      print('Error checking in on server: $e');
      _showAlert(context, "Error", Colors.red);
    }
  }

  Future<void> _updateStatus(String serverUrl, String data, BuildContext context) async {
    final Map<String, dynamic> updateBody = {"user_id": data, "status": 1};

    try {
      var updateResponse = await http.post(
        Uri.parse('$serverUrl/update_status'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(updateBody),
      );

      if (updateResponse.statusCode == 200) {
        print("Update Status Response: ${updateResponse.body}");
      } else {
        _showAlert(context, "Status Update Failed: Server Error", Colors.red);
      }
    } catch (e) {
      print('Error updating status on server: $e');
      _showAlert(context, "Error", Colors.red);
    }
  }

  void _showAlert(BuildContext context, String message, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alert"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
