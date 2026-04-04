import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class MyDevicesPage extends StatefulWidget {
  final String userMobile;


  const MyDevicesPage({super.key, required this.userMobile});

  @override
  State<MyDevicesPage> createState() => _MyDevicesPageState();
}

class _MyDevicesPageState extends State<MyDevicesPage> {
  final dbRef = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 30),
          onPressed: () {},
        ),

        centerTitle: true,
        title: const Text(
          "Devie'ss",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                // onPressed: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => MyDevicesScanPage(
                //         userMobile: widget.userMobile,
                //       ),
                //     ),
                //   );
                // },
                onPressed: () {
                  _showDeviceScanPopup();
                },

              ),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [

          /// Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/main.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Device List From Realtime DB
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: StreamBuilder(

              stream: dbRef
                  .child("Devices/${widget.userMobile}")
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return const Center(
                    child: Text(
                      "No Device Found",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                Map<dynamic, dynamic> data =
                snapshot.data!.snapshot.value as Map;

                List deviceKeys = data.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: deviceKeys.length,
                  itemBuilder: (context, index) {
                    String key = deviceKeys[index];
                    Map device = data[key];

                    String status = device["activat"] ?? "Inactive";
                    int testCount = device["testCount"] ?? 0;

                    bool active = status.toLowerCase() == "active";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Device Name",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                              const Spacer(),
                              Text(
                                key,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text("status", style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                              ),
                              const Spacer(),
                              Text(
                                active
                                    ? "Active | Remaining Test: $testCount"
                                    : "Inactive | Please Recharge",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: active ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            ],
                          )

                          // const Text(
                          //   "Status",
                          //   style:
                          //   TextStyle(fontSize: 16, color: Colors.black54),
                          // ),
                          //
                          // Text(
                          //   active
                          //       ? "active | Remaining Test: $testCount"
                          //       : "Inactive | Please Recharge",
                          //   style: TextStyle(
                          //     fontSize: 16,
                          //     fontWeight: FontWeight.bold,
                          //     color: active ? Colors.green : Colors.red,
                          //   ),
                          // ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showDeviceScanPopup() {
    // keep persistent state here so re-builds don't recreate them
    final List<BluetoothDiscoveryResult> _popupDevices = [];
    bool _popupScanning = false;
    StreamSubscription<BluetoothDiscoveryResult>? _popupSubscription;

    Future<void> _startPopupScan(StateSetter setState) async {
      // ensure permissions
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.locationWhenInUse.request();
      await Permission.location.request();

      // ensure Bluetooth is enabled
      final isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
      if (!isEnabled) {
        // request to enable it (this shows Android's enable prompt)
        final enabled = await FlutterBluetoothSerial.instance.requestEnable();
        if (enabled != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enable Bluetooth to scan.")),
          );
          return;
        }
      }

      // clear old results
      _popupDevices.clear();
      setState(() => _popupScanning = true);

      // short delay (helps on many devices)
      await Future.delayed(const Duration(milliseconds: 300));

      // add already paired/bonded devices first (optional)
      try {
        final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
        for (var d in bonded) {
          final name = d.name ?? "";
          if (name.startsWith("SCINPY")) {
            final exists = _popupDevices.any((e) => e.device.address == d.address);
            if (!exists) {
              _popupDevices.add(BluetoothDiscoveryResult(device: d, rssi: 0));
              // refresh dialog UI
              setState(() {});
            }
          }
        }
      } catch (e) {
        // ignore, continue with discovery
      }

      // start discovery and keep subscription so we can cancel it
      _popupSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        final name = r.device.name ?? "";
        final rssi = r.rssi ?? 0;

        // Skip devices with RSSI = 0
        if (rssi == 0) return;


        if (name.startsWith("SCINPY")) {
          final exists = _popupDevices.any((e) => e.device.address == r.device.address);
          if (!exists) {
            _popupDevices.add(r);
            setState(() {}); // update UI
          }
        }
      }, onError: (err) {
        // handle errors if needed
      });

      // when discovery finishes, set scanning = false
      _popupSubscription?.onDone(() {
        setState(() => _popupScanning = false);
      });
    }

    // show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            // Start scanning once when the dialog is built
            // use Future.microtask so it runs after build
            Future.microtask(() {
              if (!_popupScanning && _popupDevices.isEmpty && _popupSubscription == null) {
                _startPopupScan(setState);
              }
            });

            return WillPopScope(
              // ensure discovery stops when dialog is closed via back button
              onWillPop: () async {
                try {
                  await _popupSubscription?.cancel();
                } catch (_) {}
                _popupSubscription = null;
                return true;
              },
              child: AlertDialog(
                title: Row(
                  children: [
                    const Expanded(child: Text("Search Devices", textAlign: TextAlign.center)),
                    IconButton(
                      icon: Icon(_popupScanning ? Icons.hourglass_empty : Icons.refresh),
                      onPressed: () async {
                        if (_popupScanning) return;
                        // restart scan
                        await _popupSubscription?.cancel();
                        _popupSubscription = null;
                        _popupDevices.clear();
                        setState(() => _popupScanning = true);
                        await _startPopupScan(setState);
                      },
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 320,
                  child: _popupScanning && _popupDevices.isEmpty
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text("Scanning for SCINPY devices…"),
                    ],
                  )
                      : _popupDevices.isEmpty
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.search_off, size: 48),
                      SizedBox(height: 8),
                      Text("No SCINPY devices found"),
                      SizedBox(height: 8),
                      Text("Make sure the device is powered on and Bluetooth is visible.")
                    ],
                  )
                      : ListView.separated(
                    itemCount: _popupDevices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = _popupDevices[i];
                      final deviceName = r.device.name ?? "Unknown";
                      final mac = r.device.address;
                      final rssi = r.rssi ?? 0;
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(deviceName),
                        subtitle: Text("MAC: $mac"),
                        trailing: Text("RSSI $rssi"),
                        onTap: () async {
                          // stop discovery first
                          await _popupSubscription?.cancel();
                          _popupSubscription = null;

                          // save to Firebase or handle selection here
                          // Example: call your save function (adjust to your db)
                          await _saveDeviceToFirebase(deviceName, mac);

                          Navigator.pop(dialogContext); // close dialog

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("$deviceName selected ($mac)")),
                          );
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await _popupSubscription?.cancel();
                      _popupSubscription = null;
                      Navigator.pop(dialogContext);
                    },
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) async {
      // cleanup after dialog closes (ensure subscription stopped)
      try {
        await _popupSubscription?.cancel();
      } catch (_) {}
      _popupSubscription = null;
    });
  }



  Future<void> _saveDeviceToFirebase(String deviceID, String mac) async {
    final now = DateTime.now();

    String formattedDate =
        "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/"
        "${now.year.toString().substring(2)} "
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}";

    await dbRef
        .child("Devices")
        .child(widget.userMobile)
        .child(deviceID)
        .set({
      "activat": "Inactive",
      "testCount": 0,
      "mac": mac,
      "dt": formattedDate,
    });
  }
}