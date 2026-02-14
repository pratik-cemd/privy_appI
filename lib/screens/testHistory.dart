import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'myDevicesPage.dart';

class TesthistoryPage extends StatefulWidget {
  final String userMobile;
  final String name;
  final String age;
  final String gender;
  final String address;
  final String disease;

  const TesthistoryPage({
    super.key,
    required this.userMobile,
    required this.name,
    required this.age,
    required this.gender,
    required this.address,
    required this.disease,
  });

  @override
  State<TesthistoryPage> createState() => _TesthistoryPageState();
}

class _TesthistoryPageState extends State<TesthistoryPage> {
  final dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> testList = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadResults();
  }


  Future<void> _loadResults() async {
    final snapshot =
    await dbRef.child("Result/${widget.userMobile}").get();

    if (!snapshot.exists) return;

    List<Map<String, dynamic>> temp = [];

    for (final child in snapshot.children) {
      final timestamp = child.key!;
      final result = child
          .child("result")
          .value
          ?.toString() ?? "N/A";
      final deviceId = child
          .child("id")
          .value
          ?.toString() ?? "-";

      temp.add({
        "timestamp": timestamp,
        "result": result == "Absent"
            ? "Absent"
            : "$result mg/100ml",
        "deviceId": deviceId,
      });
    }

    temp.sort((a, b) =>
        b["timestamp"].compareTo(a["timestamp"]));

    setState(() {
      testList = temp;
    });
  }

  void _showMenu() async {
    final selected = await showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
      items: const [
        PopupMenuItem(
          value: 'share',
          child: Text("Share as  PDF"),
        ),
        PopupMenuItem(
          value: 'filter',
          child: Text("Find Test by Date"),
        ),
      ],
    );

    if (selected == 'share') {
      if (testList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No test history available")),
        );
        return;
      }
      _generateTablePdf();
    }
    // else if (selected == 'filter') {
    //   // _selectDateAndFindResult(context);
    // }
  }

  Future<void> _generateTablePdf() async {
    final pdf = pw.Document();

    final now = DateFormat("dd-MM-yyyy HH:mm:ss")
        .format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        build: (context) =>
        [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("PATIENT TEST HISTORY",
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text("Generated: $now",
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),

          pw.Text("Name: ${widget.name}"),
          pw.Text("Mobile: ${widget.userMobile}"),
          pw.Text(
              "Age/Gender: ${widget.age}Y / ${widget.gender}"),
          pw.Text("Disease: ${widget.disease}"),
          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: [
              "S.No",
              "Device ID",
              "Date",
              "Time",
              "Result"
            ],
            data: List.generate(testList.length, (index) {
              final item = testList[index];
              final parts =
              item["timestamp"].split("_");
              return [
                "${index + 1}",
                item["deviceId"],
                parts[0],
                parts.length > 1 ? parts[1] : "-",
                item["result"],
              ];
            }),
          ),

          pw.SizedBox(height: 20),
          pw.Divider(),

          pw.Text(
              "Device Sensitivity: 94.2%   Specificity: 94.5%"),
          pw.Text(
              "Powered by: Cutting Edge Medical Device Pvt. Ltd, Indore"),
          pw.Text("www.cemd.in"),
          pw.Text("Computer Generated PDF"),
        ],
        footer: (context) =>
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Page ${context.pageNumber} / ${context.pagesCount}",
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
      ),
    );

    final Uint8List bytes = await pdf.save();

    final directory =
    await getTemporaryDirectory();
    final file = File(
        "${directory.path}/History_${widget.name}.pdf");
    await file.writeAsBytes(bytes);

    _showShareDialog(file);
  }

  void _showShareDialog(File file) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Choose Action"),
            content: const Text(
                "Would you like to view the Test History or share it?"),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Printing.layoutPdf(
                    onLayout: (format) =>
                        file.readAsBytes(),
                  );
                },
                child: const Text("View"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles(
                      [XFile(file.path)]);
                },
                child: const Text("Share"),
              ),
            ],
          ),
    );
  }

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

            // if (selected == null) return;
            if (selected != null) {
              _handleNavigation(selected);
            }

            // if (selected == "home") {
            //   Navigator.pushNamed(context, "/home");
            // } else if (selected == "history") {
            //   Navigator.pushNamed(context, "/testHistory");
            // } else if (selected == "device") {
            //   Navigator.pushNamed(context, "/myDevice");
            // } else if (selected == "doctor") {
            //   Navigator.pushNamed(context, "/myDoctor");
            // }
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
                icon: const Icon(Icons.arrow_circle_down_outlined, color: Colors.blue),
                onPressed: () {
                  _showMenu();
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


          Padding(
            padding: const EdgeInsets.only(top: 90),
            child: StreamBuilder<DatabaseEvent>(
              stream: dbRef
                  .child("Result/${widget.userMobile}")
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return const Center(
                    child: Text(
                      "No Result Found",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final data = Map<dynamic, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);

                final dateKeys = data.keys.toList()
                  ..sort((a, b) => b.toString().compareTo(a.toString()));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, index) {
                    final dateTime = dateKeys[index];
                    final testData =
                    Map<dynamic, dynamic>.from(data[dateTime]);

                    final rawResult = testData["result"] ?? "N/A";

                    String displayResult =
                    rawResult.toString().toLowerCase() != "absent"
                        ? "${rawResult.toString()} mg/100ml"
                        : "Absent";

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// LEFT SIDE
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Proteins Contain Level",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Test Execution Date",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            /// RIGHT SIDE
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  displayResult,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dateTime,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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

  void _handleNavigation(String selected) {
    final routes = {
      "home": "/home",
      "history": "/testHistory",
      // "/myDevice": (context) => MyDevicesPage2(userMobile: userMobile ),
      "doctor": "/myDoctor",
    };

    if (routes.containsKey(selected)) {
      Navigator.pushNamed(context, routes[selected]!);
    }
  }
}


// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
//
// class TesthistoryPage extends StatefulWidget {
//   final String userMobile;
//   final String name;
//   final String age;
//   final String gender;
//   final String disease;
//
//   const TesthistoryPage({
//     super.key,
//     required this.userMobile,
//     required this.name,
//     required this.age,
//     required this.gender,
//     required this.disease,
//
//   });
//
//   @override
//   State<TesthistoryPage> createState() => _TesthistoryPageState();
// }
//
// class _TesthistoryPageState extends State<TesthistoryPage> {
//   final dbRef = FirebaseDatabase.instance.ref();
//
//   Map<dynamic, dynamic> displayedResults = {};
//   Map<dynamic, dynamic> fullResults = {};
//
//   bool _isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           "Test History",
//           style: TextStyle(color: Colors.white, fontSize: 22),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: IconButton(
//                 icon: const Icon(Icons.expand_circle_down,
//                     color: Colors.blue),
//                 onPressed: () {
//                   _showExportOptions(context);
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/images/main.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.only(top: 90),
//             child: StreamBuilder<DatabaseEvent>(
//               stream: dbRef
//                   .child("Result/${widget.userMobile}")
//                   .onValue,
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData ||
//                     snapshot.data?.snapshot.value == null) {
//                   return const Center(
//                     child: Text(
//                       "No Result Found",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   );
//                 }
//
//                 final firebaseData = Map<dynamic, dynamic>.from(
//                     snapshot.data!.snapshot.value as Map);
//
//                 // Always store full results
//                 fullResults = firebaseData;
//
//                 // Decide what to show
//                 final resultsToShow =
//                 displayedResults.isNotEmpty
//                     ? displayedResults
//                     : fullResults;
//
//                 final dateKeys = resultsToShow.keys.toList()
//                   ..sort((a, b) =>
//                       b.toString().compareTo(a.toString()));
//
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(12),
//                   itemCount: dateKeys.length,
//                   itemBuilder: (context, index) {
//                     final dateTime = dateKeys[index];
//                     final testData = Map<dynamic, dynamic>.from(
//                         resultsToShow[dateTime]);
//
//                     final rawResult =
//                         testData["result"] ?? "N/A";
//
//                     String displayResult =
//                     rawResult.toString().toLowerCase() !=
//                         "absent"
//                         ? "${rawResult.toString()} mg/100ml"
//                         : "Absent";
//
//                     return Card(
//                       elevation: 4,
//                       margin:
//                       const EdgeInsets.only(bottom: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius:
//                         BorderRadius.circular(12),
//                       ),
//                       child: Padding(
//                         padding:
//                         const EdgeInsets.all(14),
//                         child: Column(
//                           crossAxisAlignment:
//                           CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Proteins Contain Level: $displayResult",
//                               style:
//                               const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight:
//                                 FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 6),
//                             Text(
//                               "Test Execution Date: $dateTime",
//                               style:
//                               const TextStyle(
//                                   fontSize: 14),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//
//           if (_isLoading)
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: const Center(
//                 child:
//                 CircularProgressIndicator(
//                     color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   // =========================
//   // Popup Menu
//   // =========================
//
//   void _showExportOptions(BuildContext context) async {
//     final selected = await showMenu(
//       context: context,
//       position:
//       const RelativeRect.fromLTRB(0, 800, 0, 0),
//       items: const [
//         PopupMenuItem(
//           value: 'share',
//           child: Text("Share Test Reports"),
//         ),
//         PopupMenuItem(
//           value: 'find',
//           child: Text("Find Test by Date"),
//         ),
//         PopupMenuItem(
//           value: 'clear',
//           child: Text("Show All Results"),
//         ),
//       ],
//     );
//
//     if (selected == 'share') {
//       _shareAllResults();
//     } else if (selected == 'find') {
//       _selectDateAndFindResult(context);
//     } else if (selected == 'clear') {
//       setState(() {
//         displayedResults = {};
//       });
//     }
//   }
//
//   // =========================
//   // Share All
//   // =========================
//
//   Future<void> _shareAllResults() async {
//
//     // If user already filtered by date,
//     // share only displayed results
//     if (displayedResults.isNotEmpty) {
//       await _generateAndSharePdf(displayedResults);
//       return;
//     }
//
//     // Otherwise share all results
//     final snapshot =
//     await dbRef.child("Result/${widget.userMobile}").get();
//
//     if (!snapshot.exists || snapshot.value == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("No data to export")),
//       );
//       return;
//     }
//
//     final data =
//     Map<dynamic, dynamic>.from(snapshot.value as Map);
//
//     await _generateAndSharePdf(data);
//   }
//
//
//   // =========================
//   // Date Picker
//   // =========================
//
//   Future<void> _selectDateAndFindResult(
//       BuildContext context) async {
//     DateTime? pickedDate =
//     await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//
//     if (pickedDate == null) return;
//
//     await _filterResultByDate(pickedDate);
//   }
//
//   // =========================
//   // Filter Logic (dd-MM-yy)
//   // =========================
//
//   Future<void> _filterResultByDate(
//       DateTime selectedDate) async {
//
//
//     final snapshot =
//     await dbRef.child("Result/${widget.userMobile}").get();
//
//     if (!snapshot.exists ||
//         snapshot.value == null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(
//           content:
//           Text("No results found")));
//       return;
//     }
//
//     final data =
//     Map<dynamic, dynamic>.from(
//         snapshot.value as Map);
//
//     String formattedDate =
//         "${selectedDate.day.toString().padLeft(2, '0')}-"
//         "${selectedDate.month.toString().padLeft(2, '0')}-"
//         "${selectedDate.year.toString().substring(2)}";
//
//
//     // print("Selected Date: $selectedDate");
//     // print("Formatted Date: $formattedDate");
//     // print("Available Keys:");
//     // data.keys.forEach((key) => print(key));
//
//     Map<dynamic, dynamic> filteredData = {};
//
//     data.forEach((key, value) {
//       String keyDate =
//       key.toString().split("_")[0];
//
//       if (keyDate == formattedDate) {
//         filteredData[key] = value;
//       }
//     });
//
//     if (filteredData.isEmpty) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(
//           content: Text(
//               "No test found on selected date")));
//       return;
//     }
//
//     setState(() {
//       displayedResults = filteredData;
//     });
//   }
//
//   // =========================
//   // PDF Generator
//   // =========================
//
//   Future<void> _generateAndSharePdf(
//       Map<dynamic, dynamic> data) async {
//     final pdf = pw.Document();
//
//     final dateKeys = data.keys.toList()
//       ..sort((a, b) =>
//           b.toString().compareTo(a.toString()));
//
//     pdf.addPage(
//       pw.MultiPage(
//         build: (pw.Context context) {
//           return [
//             pw.Text(
//               displayedResults.isNotEmpty
//                   ? "Filtered Test Report"
//                   : "Test History Report",
//               style: pw.TextStyle(
//                 fontSize: 22,
//                 fontWeight:
//                 pw.FontWeight.bold,
//               ),
//             ),
//             pw.SizedBox(height: 20),
//             ...dateKeys.map((date) {
//               final testData = data[date];
//               final rawResult =
//                   testData["result"] ?? "N/A";
//
//               String displayResult =
//               rawResult
//                   .toString()
//                   .toLowerCase() !=
//                   "absent"
//                   ? "${rawResult.toString()} mg/100ml"
//                   : "Absent";
//
//               return pw.Container(
//                 margin:
//                 const pw.EdgeInsets.only(
//                     bottom: 10),
//                 padding:
//                 const pw.EdgeInsets.all(8),
//                 decoration:
//                 pw.BoxDecoration(
//                   border: pw.Border.all(),
//                 ),
//                 child: pw.Column(
//                   crossAxisAlignment:
//                   pw.CrossAxisAlignment
//                       .start,
//                   children: [
//                     pw.Text(
//                         "Protein Level: $displayResult"),
//                     pw.Text(
//                         "Test Date: $date"),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ];
//         },
//       ),
//     );
//
//     final output =
//     await getTemporaryDirectory();
//     final file = File(
//         "${output.path}/test_history.pdf");
//
//     await file.writeAsBytes(
//         await pdf.save());
//
//     await Share.shareXFiles(
//         [XFile(file.path)],
//         text:
//         "Here is my test history report");
//   }
// }



// import 'dart:async';
// import 'dart:io' show Platform, File;
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
//
//
// class TesthistoryPage extends StatefulWidget {
//
//   final String userMobile;
//   const TesthistoryPage({super.key, required this.userMobile});
//
//   @override
//   State<TesthistoryPage> createState() => _TestHistoryPageState();
// }
//
// class _TestHistoryPageState extends State<TesthistoryPage> {
//   final dbRef = FirebaseDatabase.instance.ref();
//   bool _isLoading = false;
//   Map<dynamic, dynamic> displayedResults = {};
//   Map<dynamic, dynamic> fullResults = {};
//
//
//
//
//   void _handleNavigation(String selected) {
//     final routes = {
//       "home": "/home",
//       "history": "/testHistory",
//       "device": "/myDevice",
//       "doctor": "/myDoctor",
//     };
//
//     final route = routes[selected];
//     if (route == null) return;
//
//     // Prevent stacking same screen
//     if (ModalRoute.of(context)?.settings.name == route) return;
//
//     Navigator.pushReplacementNamed(context, route);
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//
//
//         // 👇 Add this
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white),
//           onPressed: () async {
//             final selected = await showMenu<String>(
//               context: context,
//               position: const RelativeRect.fromLTRB(0, 80, 0, 0),
//               items: [
//                 const PopupMenuItem(
//                   value: "home",
//                   child: Row(
//                     children: [
//                       Icon(Icons.home, color: Colors.black),
//                       SizedBox(width: 8),
//                       Text("Home", style: TextStyle(color: Colors.black)),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: "history",
//                   child: Row(
//                     children: [
//                       Icon(Icons.history, color: Colors.black),
//                       SizedBox(width: 8),
//                       Text("Test History",
//                           style: TextStyle(color: Colors.black)),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: "device",
//                   child: Row(
//                     children: [
//                       Icon(Icons.devices, color: Colors.black),
//                       SizedBox(width: 8),
//                       Text("My Device",
//                           style: TextStyle(color: Colors.black)),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: "doctor",
//                   child: Row(
//                     children: [
//                       Icon(Icons.person, color: Colors.black),
//                       SizedBox(width: 8),
//                       Text("My Doctor",
//                           style: TextStyle(color: Colors.black)),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//
//             // if (selected == null) return;
//             if (selected != null) {
//               _handleNavigation(selected);
//             }
//
//             // if (selected == "home") {
//             //   Navigator.pushNamed(context, "/home");
//             // } else if (selected == "history") {
//             //   Navigator.pushNamed(context, "/testHistory");
//             // } else if (selected == "device") {
//             //   Navigator.pushNamed(context, "/myDevice");
//             // } else if (selected == "doctor") {
//             //   Navigator.pushNamed(context, "/myDoctor");
//             // }
//           },
//         ),
//         title: const Text(
//           "Test History ",
//           style: TextStyle(color: Colors.white, fontSize: 22),
//         ),
//
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: IconButton(
//                 icon: const Icon(Icons.expand_circle_down, color: Colors.blue),
//                 // onPressed: () async {
//                 //   final snapshot = await dbRef
//                 //       .child("Result/${widget.userMobile}")
//                 //       .get();
//                 //
//                 //   if (!snapshot.exists || snapshot.value == null) {
//                 //     ScaffoldMessenger.of(context).showSnackBar(
//                 //       const SnackBar(content: Text("No data to export")),
//                 //     );
//                 //     return;
//                 //   }
//                 //
//                 //   final data =
//                 //   Map<dynamic, dynamic>.from(snapshot.value as Map);
//                 //
//                 //   await _generateAndSharePdf(data);
//                 // },
//
//                 onPressed: () {
//                   _showExportOptions(context);
//                 },
//
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/images/main.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           // Padding(
//           //     padding: const EdgeInsets.only(top: 70),
//           //   child: StreamBuilder(
//           //   stream: dbRef.child("Result/${widget.userMobile}").onValue,
//           //   builder: (context, snapshot) {
//           //   if (!snapshot.hasData ||
//           //   snapshot.data?.snapshot.value == null) {
//           //   return const Center(
//           //   child: Text(
//           //   "No Result Found",
//           //   style: TextStyle(color: Colors.white),
//           //   ),
//           //   );
//           //   }
//           //
//           //   final data =
//           //   snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//           //
//           //   final dateKeys = data.keys.toList();
//           //
//           //   // Optional: sort latest first
//           //   dateKeys.sort((a, b) => b.compareTo(a));
//           //
//           //   return ListView.builder(
//           //   padding: const EdgeInsets.all(12),
//           //   itemCount: dateKeys.length,
//           //   itemBuilder: (context, index) {
//           //   final dateTime = dateKeys[index];
//           //   final testData = data[dateTime];
//           //
//           //   final rawResult = testData["result"] ?? "N/A";
//           //
//           //   String displayResult;
//           //
//           //   if (rawResult.toString().toLowerCase() != "absent") {
//           //   displayResult = "${rawResult.toString()} mg/100ml";
//           //   } else {
//           //   displayResult = "Absent";
//           //   }
//           //
//           //   return Card(
//           //   margin: const EdgeInsets.only(bottom: 12),
//           //   child: Padding(
//           //   padding: const EdgeInsets.all(14),
//           //   child: Column(
//           //   crossAxisAlignment: CrossAxisAlignment.start,
//           //   children: [
//           //   Text(
//           //   "Proteins Contain Level is: $displayResult",
//           //   style: const TextStyle(
//           //   fontSize: 16,
//           //   fontWeight: FontWeight.bold,
//           //   ),
//           //   ),
//           //   const SizedBox(height: 6),
//           //   Text(
//           //   "Test Execution Date: $dateTime",
//           //   style: const TextStyle(fontSize: 14),
//           //   ),
//           //   ],
//           //   ),
//           //   ),
//           //   );
//           //   },
//           //   );
//           //   },
//           //   ),
//           //   ),
//
//           Padding(
//             padding: const EdgeInsets.only(top: 90),
//             child: StreamBuilder<DatabaseEvent>(
//               stream: dbRef
//                   .child("Result/${widget.userMobile}")
//                   .onValue,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(
//                     child: CircularProgressIndicator(color: Colors.white),
//                   );
//                 }
//
//                 if (!snapshot.hasData ||
//                     snapshot.data?.snapshot.value == null) {
//                   return const Center(
//                     child: Text(
//                       "No Result Found",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   );
//                 }
//
//                 final data = Map<dynamic, dynamic>.from(
//                     snapshot.data!.snapshot.value as Map);
//
//                 final dateKeys = data.keys.toList()
//                   ..sort((a, b) => b.toString().compareTo(a.toString()));
//
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(12),
//                   itemCount: dateKeys.length,
//                   itemBuilder: (context, index) {
//                     final dateTime = dateKeys[index];
//                     final testData =
//                     Map<dynamic, dynamic>.from(data[dateTime]);
//
//                     final rawResult = testData["result"] ?? "N/A";
//
//                     String displayResult =
//                     rawResult.toString().toLowerCase() != "absent"
//                         ? "${rawResult.toString()} mg/100ml"
//                         : "Absent";
//
//                     return Card(
//                       elevation: 4,
//                       margin: const EdgeInsets.only(bottom: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(14),
//                         child: Column(
//                           crossAxisAlignment:
//                           CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Proteins Contain Level: $displayResult",
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 6),
//                             Text(
//                               "Test Execution Date: $dateTime",
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//
//             if (_isLoading)
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: const Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     CircularProgressIndicator(color: Colors.white),
//                     SizedBox(height: 16),
//                     // Text("Communicating with device…", style: TextStyle(color: Colors.white)),
//                     Text("Load the Test Result result…",
//                         style: TextStyle(color: Colors.white)),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _generateAndSharePdf(
//       Map<dynamic, dynamic> data) async {
//
//     final pdf = pw.Document();
//
//     final dateKeys = data.keys.toList()
//       ..sort((a, b) => b.toString().compareTo(a.toString()));
//
//     pdf.addPage(
//       pw.MultiPage(
//         build: (pw.Context context) {
//           return [
//             pw.Text(
//               "Test History Report",
//               style: pw.TextStyle(
//                 fontSize: 22,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//             pw.SizedBox(height: 20),
//
//             ...dateKeys.map((date) {
//               final testData = data[date];
//               final rawResult = testData["result"] ?? "N/A";
//
//               String displayResult =
//               rawResult.toString().toLowerCase() != "absent"
//                   ? "${rawResult.toString()} mg/100ml"
//                   : "Absent";
//
//               return pw.Container(
//                 margin: const pw.EdgeInsets.only(bottom: 10),
//                 padding: const pw.EdgeInsets.all(8),
//                 decoration: pw.BoxDecoration(
//                   border: pw.Border.all(),
//                 ),
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text("Protein Level: $displayResult"),
//                     pw.Text("Test Date: $date"),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ];
//         },
//       ),
//     );
//
//     final output = await getTemporaryDirectory();
//     final file = File("${output.path}/test_history.pdf");
//     await file.writeAsBytes(await pdf.save());
//
//     await Share.shareXFiles([XFile(file.path)],
//         text: "Here is my test history report");
//   }
//
//   void _showExportOptions(BuildContext context) async {
//     final RenderBox button =
//     context.findRenderObject() as RenderBox;
//
//     final RenderBox overlay =
//     Overlay.of(context).context.findRenderObject() as RenderBox;
//
//     final position = RelativeRect.fromRect(
//       Rect.fromPoints(
//         button.localToGlobal(Offset.zero, ancestor: overlay),
//         button.localToGlobal(button.size.bottomRight(Offset.zero),
//             ancestor: overlay),
//       ),
//       Offset.zero & overlay.size,
//     );
//
//     final selected = await showMenu(
//       context: context,
//       position: position,
//       items: const [
//         PopupMenuItem(
//           value: 'share',
//           child: Text("Share All PDFs"),
//         ),
//         PopupMenuItem(
//           value: 'find',
//           child: Text("Find Test by Date"),
//         ),
//       ],
//     );
//
//     if (selected == 'share') {
//       _shareAllResults();
//     } else if (selected == 'find') {
//       _selectDateAndFindResult(context);
//     }
//   }
//
//
//   Future<void> _shareAllResults() async {
//     final snapshot =
//     await dbRef.child("Result/${widget.userMobile}").get();
//
//     if (!snapshot.exists || snapshot.value == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("No data to export")),
//       );
//       return;
//     }
//
//     final data =
//     Map<dynamic, dynamic>.from(snapshot.value as Map);
//
//     await _generateAndSharePdf(data);
//   }
//
//   Future<void> _selectDateAndFindResult(BuildContext context) async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//
//     if (pickedDate == null) return;
//
//     await _filterResultByDate(pickedDate);
//   }
//
//   Future<void> _filterResultByDate(DateTime selectedDate) async {
//     final snapshot =
//     await dbRef.child("Result/${widget.userMobile}").get();
//
//     if (!snapshot.exists || snapshot.value == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("No results found")),
//       );
//       return;
//     }
//
//     final data =
//     Map<dynamic, dynamic>.from(snapshot.value as Map);
//
//     // Convert selected date to dd-MM-yy format
//     String formattedDate =
//         "${selectedDate.day.toString().padLeft(2, '0')}-"
//         "${selectedDate.month.toString().padLeft(2, '0')}-"
//         "${selectedDate.year.toString().substring(2)}";
//
//     Map<dynamic, dynamic> filteredData = {};
//
//     data.forEach((key, value) {
//       // Split key at "_" and take only date part
//       String keyDate = key.toString().split("_")[0];
//
//       if (keyDate == formattedDate) {
//         filteredData[key] = value;
//       }
//     });
//
//     if (filteredData.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("No test found on selected date")),
//       );
//       return;
//     }
//
//     setState(() {
//       displayedResults = filteredData;
//     });
//   }
//
//
//
//
//
//
//
// }