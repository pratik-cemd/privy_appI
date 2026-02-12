import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class TesthistoryPage extends StatefulWidget {
  final String userMobile;
  const TesthistoryPage({super.key, required this.userMobile});

  @override
  State<TesthistoryPage> createState() => _TestHistoryPageState();
}

class _TestHistoryPageState extends State<TesthistoryPage> {
  final dbRef = FirebaseDatabase.instance.ref();

  bool _isLoading = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,


        // 👇 Add this
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () async {
            final selected = await showMenu<String>(
              context: context,
              position: const RelativeRect.fromLTRB(0, 80, 0, 0),
              items: [
                const PopupMenuItem(
                  value: "home",
                  child: Row(
                    children: [
                      Icon(Icons.home, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Home", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "history",
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Test History",
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "device",
                  child: Row(
                    children: [
                      Icon(Icons.devices, color: Colors.black),
                      SizedBox(width: 8),
                      Text("My Device",
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "doctor",
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.black),
                      SizedBox(width: 8),
                      Text("My Doctor",
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ],
            );

            if (selected == null) return;

            if (selected == "home") {
              Navigator.pushNamed(context, "/home");
            } else if (selected == "history") {
              Navigator.pushNamed(context, "/testHistory");
            } else if (selected == "device") {
              Navigator.pushNamed(context, "/myDevice");
            } else if (selected == "doctor") {
              Navigator.pushNamed(context, "/myDoctor");
            }
          },
        ),
        title: const Text(
          "Test History ",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () {
                  //add the share pdf  and my file
                },

              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/main.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(top: 100),
          //   child: StreamBuilder(
          //     stream: dbRef
          //         .child("Result/${widget.userMobile}")
          //         .onValue,
          //     builder: (context, snapshot) {
          //       if (!snapshot.hasData ||
          //           snapshot.data?.snapshot.value == null) {
          //         return const Center(
          //           child: Text("No Result Found",
          //               style: TextStyle(color: Colors.white)),
          //         );
          //       }
          //
          //       final data = snapshot.data!.snapshot.value as Map<
          //           dynamic,
          //           dynamic>;
          //       final keys = data.keys.toList();
          //
          //       return ListView.builder(
          //         padding: const EdgeInsets.all(12),
          //         itemCount: keys.length,
          //         itemBuilder: (context, i) {
          //           final key = keys[i];
          //           final device = data[key];
          //
          //           final status = device["st"] ?? "Inactive";
          //           final testCount = device["testCount"] ?? 0;
          //           final mac = device["mac"] ?? "";
          //           final active = status.toLowerCase() == "active";
          //
          //           return InkWell(
          //             onTap: () async {
          //               if (!active) {
          //                 _showPopup("Status", "Please contact CEMD");
          //                 return;
          //               }
          //               if (testCount <= 0) {
          //                 _showPopup("Status", "Please Recharge");
          //                 return;
          //               }
          //               await _connectSendAndRead(mac, key);
          //             },
          //             child: Card(
          //               margin: const EdgeInsets.only(bottom: 12),
          //               child: Padding(
          //                 padding: const EdgeInsets.all(14),
          //                 child: Column(
          //                   crossAxisAlignment: CrossAxisAlignment.start,
          //                   children: [
          //                     Text("Device: $key"),
          //                     const SizedBox(height: 6),
          //                     Text(
          //                       active
          //                           ? "Active | Remaining: $testCount"
          //                           : "Inactive",
          //                       style: TextStyle(
          //                         color: active ? Colors.green : Colors
          //                             .redAccent,
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             ),
          //           );
          //         },
          //       );
          //     },
          //   ),
          // ),

            Padding(
              padding: const EdgeInsets.only(top: 70),
            child: StreamBuilder(
            stream: dbRef.child("Result/${widget.userMobile}").onValue,
            builder: (context, snapshot) {
            if (!snapshot.hasData ||
            snapshot.data?.snapshot.value == null) {
            return const Center(
            child: Text(
            "No Result Found",
            style: TextStyle(color: Colors.white),
            ),
            );
            }

            final data =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            final dateKeys = data.keys.toList();

            // Optional: sort latest first
            dateKeys.sort((a, b) => b.compareTo(a));

            return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dateKeys.length,
            itemBuilder: (context, index) {
            final dateTime = dateKeys[index];
            final testData = data[dateTime];

            final rawResult = testData["result"] ?? "N/A";

            String displayResult;

            if (rawResult.toString().toLowerCase() != "absent") {
            displayResult = "${rawResult.toString()} mg/100ml";
            } else {
            displayResult = "Absent";
            }

            return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
            "Proteins Contain Level is: $displayResult",
            style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            ),
            ),
            const SizedBox(height: 6),
            Text(
            "Test Execution Date: $dateTime",
            style: const TextStyle(fontSize: 14),
            ),
            ],
            ),
            ),
            );
            },
            );
            },
            ),
            ),


            if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    // Text("Communicating with device…", style: TextStyle(color: Colors.white)),
                    Text("Load the Test Result result…",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

}