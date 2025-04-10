import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Graph App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'MQTT Graph'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MqttServerClient client;
  StreamSubscription? subscription;
  final List<double> temperatureValues = [];
  final List<double> humidityValues = [];
  final List<num> timestamps = [];

  @override
  void initState() {
    super.initState();
    setupMqtt();
  }

  Future<void> setupMqtt() async {
    client = MqttServerClient('localhost', '');
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    final connMess =
        MqttConnectMessage()
            .withClientIdentifier('flutter_client_${Random().nextInt(1000)}')
            .authenticateAs("python", "Zalter21@21")
            .startClean();
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      client.disconnect();
      print('Exception: $e');
      exit(1);
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.subscribe("sensor/datenGlatt", MqttQos.atMostOnce);
      subscription = client.updates!.listen((
        List<MqttReceivedMessage<MqttMessage>> c,
      ) {
        final MqttMessage recMess = c[0].payload;
        if (recMess is MqttPublishMessage) {
          final String message = MqttPublishPayload.bytesToStringAsString(
            recMess.payload.message,
          );
          try {
            final Map<String, dynamic> jsonData = jsonDecode(message);
            final double temperature =
                (jsonData['temperatur'] as num).toDouble();
            final double humidity =
                (jsonData['luftfeuchtigkeit'] as num).toDouble();
            final num timestamp = jsonData['timestamp'] as num;
            print(temperature);
            setState(() {
              temperatureValues.add(temperature);
              if (temperatureValues.length > 100) {
                temperatureValues.removeAt(0);
              }
              humidityValues.add(humidity);
              if (humidityValues.length > 100) {
                humidityValues.removeAt(0);
              }
              timestamps.add(timestamp);
              if (timestamps.length > 100) {
                timestamps.removeAt(0);
              }
            });
          } catch (e) {
            print("Error parsing MQTT message: $e");
          }
        }
      });
    } else {
      print("SOmething went wront");
      exit(1);
    }
  }

  void onDisconnected() {
    // Handle disconnection logic if needed
  }

  @override
  void dispose() {
    subscription?.cancel();
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text('Temperature Data', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  size: const Size(double.infinity, 300),
                  painter: GraphPainter(temperatureValues),
                ),
              ),
              const Text('Humidity Data', style: TextStyle(fontSize: 18)),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  size: const Size(double.infinity, 300),
                  painter: GraphPainter(humidityValues),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<double> data;
  final List<num>? timestamps;
  GraphPainter(this.data, {this.timestamps});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Draw axis lines
    final axisPaint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 1;
    // x-axis at the bottom and y-axis on the left
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);

    // Determine min and max values for y
    double minY = data.reduce(min);
    double maxY = data.reduce(max);
    double rangeY = maxY - minY;
    if (rangeY == 0) rangeY = 1;

    // Prepare for path drawing
    final paintLine =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
    final path = Path();

    // Determine x positions based on timestamps if provided and matching data length.
    List<double> xPositions = [];
    if (timestamps != null && timestamps!.length == data.length) {
      num minX = timestamps!.reduce(min);
      num maxX = timestamps!.reduce(max);
      double rangeX = (maxX - minX).toDouble();
      if (rangeX == 0) rangeX = 1;
      for (int i = 0; i < data.length; i++) {
        double normalizedX = ((timestamps![i] - minX) / rangeX).toDouble();
        xPositions.add(normalizedX * size.width);
      }
      // Draw x-axis labels (min, mid, max)
      _drawText(canvas, Offset(0, size.height + 2), minX.toString());
      _drawText(
        canvas,
        Offset(size.width / 2, size.height + 2),
        ((minX + maxX) / 2).toString(),
      );
      _drawText(canvas, Offset(size.width, size.height + 2), maxX.toString());
    } else {
      double stepX = size.width / (data.length - 1);
      for (int i = 0; i < data.length; i++) {
        xPositions.add(i * stepX);
      }
      // Fallback labels for x axis
      _drawText(canvas, Offset(0, size.height + 2), '0');
      _drawText(
        canvas,
        Offset(size.width, size.height + 2),
        (data.length - 1).toString(),
      );
    }

    // Draw the graph line
    for (int i = 0; i < data.length; i++) {
      double normalizedY = (data[i] - minY) / rangeY;
      double y = size.height - (normalizedY * size.height);
      double x = xPositions[i];
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paintLine);

    // Draw y-axis labels (min and max)
    _drawText(canvas, Offset(2, size.height - 14), minY.toString());
    _drawText(canvas, Offset(2, 0), maxY.toString());
  }

  // Helper method to draw text using TextPainter.
  void _drawText(Canvas canvas, Offset offset, String text) {
    final span = TextSpan(
      style: const TextStyle(color: Colors.black, fontSize: 10),
      text: text,
    );
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return true;
  }
}
