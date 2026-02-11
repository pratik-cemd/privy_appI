import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEPage extends StatefulWidget {
  const BLEPage({super.key});

  @override
  State<BLEPage> createState() => _BLEPageState();
}

class _BLEPageState extends State<BLEPage> {

  final Guid serviceUuid = Guid("00FF");
  final Guid rxUuid = Guid("FF01");
  final Guid txUuid = Guid("FF02");

  BluetoothDevice? device;
  BluetoothCharacteristic? rxChar;
  BluetoothCharacteristic? txChar;

  String buffer = "";

  Future<void> startCommunication() async {

    BluetoothDevice? found;

    // Scan using service UUID (important for iOS)
    await FlutterBluePlus.startScan(
      withServices: [serviceUuid],
      timeout: const Duration(seconds: 5),
    );

    await for (final results in FlutterBluePlus.scanResults) {
      for (var r in results) {
        found = r.device;
        break;
      }
      if (found != null) break;
    }

    await FlutterBluePlus.stopScan();

    if (found == null) {
      showMessage("Device not found");
      return;
    }

    device = found;

    await device!.connect(
      autoConnect: false,
      timeout: const Duration(seconds: 10),
    );

    await device!.requestMtu(185);
    await Future.delayed(const Duration(milliseconds: 300));

    final services = await device!.discoverServices();

    for (var s in services) {
      if (s.uuid == serviceUuid) {
        for (var c in s.characteristics) {
          if (c.uuid == rxUuid) rxChar = c;
          if (c.uuid == txUuid) txChar = c;
        }
      }
    }

    if (rxChar == null || txChar == null) {
      showMessage("Characteristics not found");
      return;
    }

    // Enable notify
    await txChar!.setNotifyValue(true);
    await Future.delayed(const Duration(milliseconds: 500));

    txChar!.lastValueStream.listen((data) async {
      final chunk = String.fromCharCodes(data);
      buffer += chunk;

      if (buffer.contains("\n")) {
        final response = buffer.trim();
        buffer = "";

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Response"),
            content: Text(response),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );

        await device!.disconnect();
      }
    });

    // Send command
    const cmd = "a\r\n";

    await rxChar!.write(
      Uint8List.fromList(cmd.codeUnits),
      withoutResponse: true,  // matches ESP32 WRITE_NR
    );
  }

  void showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("BLE"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESP32 BLE iOS Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: startCommunication,
          child: const Text("Connect & Send"),
        ),
      ),
    );
  }
}
