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
import 'mydoctor.dart';
import 'user_model.dart';
import  'myprofile.dart';


// class TesthistoryPage extends StatefulWidget {
//   final UserModel user;
//   final String? patientMobile; // NEW (optional)
//
//   const TesthistoryPage({
//     super.key,
//     required this.user,
//     this.patientMobile, // optional
//   });
//
//   @override
//   State<TesthistoryPage> createState() => _TesthistoryPageState();
// }
// class _TesthistoryPageState extends State<TesthistoryPage> {
//   final dbRef = FirebaseDatabase.instance.ref();
//   List<Map<String, dynamic>> testList = [];
//   bool _isLoading = false;
//   late String targetMobile;
//
//   DateTime? _selectedDate;
//   DateTimeRange? _selectedRange;
//
//   @override
//   void initState() {
//     super.initState();
//     // ✅ If doctor clicked patient → use that mobile
//     // ✅ Otherwise use logged in user mobile
//     targetMobile = widget.patientMobile ?? widget.user.mobile;
//     _loadResults();
//   }
//
//
//   Future<void> _loadResults() async {
//     // print("mobile number "+targetMobile);
//     final snapshot =
//     await dbRef.child("Result/${targetMobile}").get();
//
//     if (!snapshot.exists) return;
//
//     List<Map<String, dynamic>> temp = [];
//
//     for (final child in snapshot.children) {
//       final timestamp = child.key!;
//       final result = child
//           .child("result")
//           .value
//           ?.toString() ?? "N/A";
//       final deviceId = child
//           .child("id")
//           .value
//           ?.toString() ?? "-";
//
//       temp.add({
//         "timestamp": timestamp,
//         "result": result == "Absent"
//             ? "Absent"
//             : "$result mg/100ml",
//         "deviceId": deviceId,
//       });
//     }
//
//     temp.sort((a, b) =>
//         b["timestamp"].compareTo(a["timestamp"]));
//
//     setState(() {
//       testList = temp;
//     });
//   }
//
//   void _showMenu() async {
//     final selected = await showMenu(
//       context: context,
//       position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
//       items: const [
//         PopupMenuItem(
//           value: 'share',
//           child: Text("Share as  PDF"),
//         ),
//         PopupMenuItem(
//           value: 'filter',
//           child: Text("Find Test by Date"),
//         ),
//       ],
//     );
//
//     if (selected == 'share') {
//       if (testList.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("No test history available")),
//         );
//         return;
//       }
//       _generateTablePdf();
//     }
//     // else if (selected == 'filter') {
//     //   // _selectDateAndFindResult(context);
//     // }
//
//     else if (selected == 'filter') {
//       showModalBottomSheet(
//         context: context,
//         builder: (_) {
//           return SafeArea(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 ListTile(
//                   leading: const Icon(Icons.calendar_today),
//                   title: const Text("Filter by Single Date"),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _pickSingleDate();
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.date_range),
//                   title: const Text("Filter by Date Range"),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _pickDateRange();
//                   },
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     }
//   }
//
//   //   Future<void> _selectDateAndFindResult(BuildContext context) async {
//   //   DateTime? pickedDate = await showDatePicker(
//   //     context: context,
//   //     initialDate: DateTime.now(),
//   //     firstDate: DateTime(2020),
//   //     lastDate: DateTime.now(),
//   //   );
//   //
//   //   if (pickedDate == null) return;
//   //
//   //   await _filterResultByDate(pickedDate);
//   // }
//
//   Future<void> _generateTablePdf() async {
//     final pdf = pw.Document();
//
//     final now = DateFormat("dd-MM-yyyy HH:mm:ss")
//         .format(DateTime.now());
//
//     pdf.addPage(
//       pw.MultiPage(
//         build: (context) =>
//         [
//           pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//             children: [
//               pw.Text("PATIENT TEST HISTORY",
//                   style: pw.TextStyle(
//                       fontSize: 18,
//                       fontWeight: pw.FontWeight.bold)),
//               pw.Text("Generated: $now",
//                   style: const pw.TextStyle(fontSize: 10)),
//             ],
//           ),
//           pw.SizedBox(height: 10),
//           pw.Divider(),
//
//           pw.Text("Name: ${widget.user.name}"),
//           pw.Text("Mobile: ${targetMobile}"),
//           pw.Text(
//               "Age/Gender: ${widget.user.age}Y / ${widget.user.gender}"),
//           pw.Text("Disease: ${widget.user.disease}"),
//           pw.SizedBox(height: 20),
//
//           pw.Table.fromTextArray(
//             headers: [
//               "S.No",
//               "Device ID",
//               "Date",
//               "Time",
//               "Result"
//             ],
//             data: List.generate(testList.length, (index) {
//               final item = testList[index];
//               final parts =
//               item["timestamp"].split("_");
//               return [
//                 "${index + 1}",
//                 item["deviceId"],
//                 parts[0],
//                 parts.length > 1 ? parts[1] : "-",
//                 item["result"],
//               ];
//             }),
//           ),
//
//           pw.SizedBox(height: 20),
//           pw.Divider(),
//
//           pw.Text(
//               "Device Sensitivity: 94.2%   Specificity: 94.5%"),
//           pw.Text(
//               "Powered by: Cutting Edge Medical Device Pvt. Ltd, Indore"),
//           pw.Text("www.cemd.in"),
//           pw.Text("Computer Generated PDF"),
//         ],
//         footer: (context) =>
//             pw.Align(
//               alignment: pw.Alignment.centerRight,
//               child: pw.Text(
//                 "Page ${context.pageNumber} / ${context.pagesCount}",
//                 style: const pw.TextStyle(fontSize: 10),
//               ),
//             ),
//       ),
//     );
//
//     final Uint8List bytes = await pdf.save();
//
//     final directory =
//     await getTemporaryDirectory();
//     final file = File(
//         "${directory.path}/History_${widget.user.name}.pdf");
//     await file.writeAsBytes(bytes);
//
//     _showShareDialog(file);
//   }
//
//   void _showShareDialog(File file) {
//     showDialog(
//       context: context,
//       builder: (_) =>
//           AlertDialog(
//             title: const Text("Choose Action"),
//             content: const Text(
//                 "Would you like to view the Test History or share it?"),
//             actions: [
//               TextButton(
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   await Printing.layoutPdf(
//                     onLayout: (format) =>
//                         file.readAsBytes(),
//                   );
//                 },
//                 child: const Text("View"),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   await Share.shareXFiles(
//                       [XFile(file.path)]);
//                 },
//                 child: const Text("Share"),
//               ),
//             ],
//           ),
//     );
//   }
//
//   //🔹 Single Date Picker
//   Future<void> _pickSingleDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//
//     if (picked != null) {
//       setState(() {
//         _selectedDate = picked;
//         _selectedRange = null; // clear range if single selected
//       });
//     }
//   }
//
//   //🔹 Date Range Picker
//   Future<void> _pickDateRange() async {
//     final picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//
//     if (picked != null) {
//       setState(() {
//         _selectedRange = picked;
//         _selectedDate = null; // clear single date
//       });
//     }
//   }
//
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
//                   value: "profile",
//                   child: Row(
//                     children: [
//                       Icon(Icons.person, color: Colors.black),
//                       SizedBox(width: 8),
//                       Text("My Profile",
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
//                       Icon(Icons.people, color: Colors.black),
//                       SizedBox(width: 8),
//                       Text("My Doctor",
//                           style: TextStyle(color: Colors.black)),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//
//             // // if (selected == null) return;
//             // if (selected != null) {
//             //   _handleNavigation(selected);
//             // }
//
//             if (selected == "home") {
//               Navigator.pushNamed(context, "/home");
//             }
//             // else if (selected == "history") {
//             //   // Navigator.pushNamed(context, "/testHistory");
//             //   Navigator.push(
//             //     context,
//             //     MaterialPageRoute(
//             //       builder: (_) => TesthistoryPage(
//             //         userMobile: widget.userMobile,
//             //         name: widget.name,
//             //         age: widget.age,
//             //         gender: widget.gender,
//             //         address: widget.address,
//             //         disease: widget.disease,
//             //       ),
//             //     ),
//             //   );
//             // }
//             else if (selected == "device") {
//               // Navigator.pushNamed(context, "/myDevice");
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => MyDevicesPage2(
//                     user: widget.user,
//                   ),
//                 ),
//               );
//             }
//             else if (selected == "profile") {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => MyProfileScreen(
//                     user: widget.user,
//                   ),
//                 ),
//               );
//             }
//
//
//             else if (selected == "doctor") {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => MyDoctorPage(
//                     user: widget.user,
//                   ),
//                 ),
//               );
//             }
//
//         //     else if (selected == "doctor") {
//         //       Navigator.pushNamed(context, "/myDoctor");
//         //       // Navigator.push(
//         //       //   context,
//         //       //   MaterialPageRoute(
//         //       //     builder: (_) => MyDoctorPage(
//         //       //       mobile: widget.userMobile,
//         //       //       name: widget.name,
//         //       //       age: widget.age,
//         //       //       email: widget.email,
//         //       //       address: widget.address,
//         //       //       gender: widget.gender,
//         //       //       imageBase64: widget.imageBase64,
//         //       //       disease: widget.disease,
//         //       //       type: widget.type,
//         //       //       specialization: widget.specialization,
//         //       //       clinicName: clinicName,
//         //       //
//         //       //       // allDoctorsType: null,   // only used for admin
//         //       //       // 👇 This is the part you wanted
//         //       //       allDoctorsType: type.toLowerCase() == "admin" ? "aallDoct" : null,
//         //       //     ),
//         //       //   ),
//         //       // );
//         //     }
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
//                 icon: const Icon(Icons.arrow_circle_down_outlined, color: Colors.blue),
//                 onPressed: () {
//                   _showMenu();
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
//
//
//           Padding(
//             padding: const EdgeInsets.only(top: 90),
//             child: StreamBuilder<DatabaseEvent>(
//               stream: dbRef
//                   .child("Result/${targetMobile}")
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
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//
//                             /// LEFT SIDE
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Text(
//                                   "Proteins Contain Level",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 SizedBox(height: 6),
//                                 Text(
//                                   "Test Execution Date",
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                               ],
//                             ),
//
//                             /// RIGHT SIDE
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Text(
//                                   displayResult,
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blue,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 6),
//                                 Text(
//                                   dateTime,
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//
//
//               },
//             ),
//           ),
//
//           if (_isLoading)
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
//   // void _handleNavigation(String selected) {
//   //   final routes = {
//   //     "home": "/home",
//   //     "history": "/testHistory",
//   //     "/myDevice": "/myDevice",
//   //     "doctor": "/myDoctor",
//   //   };
//   //
//   //   if (routes.containsKey(selected)) {
//   //     Navigator.pushNamed(context, routes[selected]!);
//   //   }
//   //   // MaterialApp(
//   //   //   routes: {
//   //   //     "/home": (context) => HomeScreen(),
//   //   //     "/testHistory": (context) => TestHistoryScreen(),
//   //   //     "/myDevice": (context) => MyDevicesPage2(userMobile: userMobile),
//   //   //     "/myDoctor": (context) => MyDoctorScreen(),
//   //   //   },
//   //   // );
//   // }
//
//
// }
//
//
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:pdf/pdf.dart';
// // import 'package:pdf/widgets.dart' as pw;
// // import 'package:path_provider/path_provider.dart';
// // import 'package:share_plus/share_plus.dart';
// //
// // class TesthistoryPage extends StatefulWidget {
// //   final String userMobile;
// //   final String name;
// //   final String age;
// //   final String gender;
// //   final String disease;
// //
// //   const TesthistoryPage({
// //     super.key,
// //     required this.userMobile,
// //     required this.name,
// //     required this.age,
// //     required this.gender,
// //     required this.disease,
// //
// //   });
// //
// //   @override
// //   State<TesthistoryPage> createState() => _TesthistoryPageState();
// // }
// //
// // class _TesthistoryPageState extends State<TesthistoryPage> {
// //   final dbRef = FirebaseDatabase.instance.ref();
// //
// //   Map<dynamic, dynamic> displayedResults = {};
// //   Map<dynamic, dynamic> fullResults = {};
// //
// //   bool _isLoading = false;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       extendBodyBehindAppBar: true,
// //       appBar: AppBar(
// //         backgroundColor: Colors.transparent,
// //         elevation: 0,
// //         centerTitle: true,
// //         title: const Text(
// //           "Test History",
// //           style: TextStyle(color: Colors.white, fontSize: 22),
// //         ),
// //         actions: [
// //           Padding(
// //             padding: const EdgeInsets.only(right: 10),
// //             child: CircleAvatar(
// //               backgroundColor: Colors.white,
// //               child: IconButton(
// //                 icon: const Icon(Icons.expand_circle_down,
// //                     color: Colors.blue),
// //                 onPressed: () {
// //                   _showExportOptions(context);
// //                 },
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //       body: Stack(
// //         children: [
// //           Container(
// //             decoration: const BoxDecoration(
// //               image: DecorationImage(
// //                 image: AssetImage("assets/images/main.png"),
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //           ),
// //
// //           Padding(
// //             padding: const EdgeInsets.only(top: 90),
// //             child: StreamBuilder<DatabaseEvent>(
// //               stream: dbRef
// //                   .child("Result/${widget.userMobile}")
// //                   .onValue,
// //               builder: (context, snapshot) {
// //                 if (!snapshot.hasData ||
// //                     snapshot.data?.snapshot.value == null) {
// //                   return const Center(
// //                     child: Text(
// //                       "No Result Found",
// //                       style: TextStyle(color: Colors.white),
// //                     ),
// //                   );
// //                 }
// //
// //                 final firebaseData = Map<dynamic, dynamic>.from(
// //                     snapshot.data!.snapshot.value as Map);
// //
// //                 // Always store full results
// //                 fullResults = firebaseData;
// //
// //                 // Decide what to show
// //                 final resultsToShow =
// //                 displayedResults.isNotEmpty
// //                     ? displayedResults
// //                     : fullResults;
// //
// //                 final dateKeys = resultsToShow.keys.toList()
// //                   ..sort((a, b) =>
// //                       b.toString().compareTo(a.toString()));
// //
// //                 return ListView.builder(
// //                   padding: const EdgeInsets.all(12),
// //                   itemCount: dateKeys.length,
// //                   itemBuilder: (context, index) {
// //                     final dateTime = dateKeys[index];
// //                     final testData = Map<dynamic, dynamic>.from(
// //                         resultsToShow[dateTime]);
// //
// //                     final rawResult =
// //                         testData["result"] ?? "N/A";
// //
// //                     String displayResult =
// //                     rawResult.toString().toLowerCase() !=
// //                         "absent"
// //                         ? "${rawResult.toString()} mg/100ml"
// //                         : "Absent";
// //
// //                     return Card(
// //                       elevation: 4,
// //                       margin:
// //                       const EdgeInsets.only(bottom: 12),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius:
// //                         BorderRadius.circular(12),
// //                       ),
// //                       child: Padding(
// //                         padding:
// //                         const EdgeInsets.all(14),
// //                         child: Column(
// //                           crossAxisAlignment:
// //                           CrossAxisAlignment.start,
// //                           children: [
// //                             Text(
// //                               "Proteins Contain Level: $displayResult",
// //                               style:
// //                               const TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight:
// //                                 FontWeight.bold,
// //                               ),
// //                             ),
// //                             const SizedBox(height: 6),
// //                             Text(
// //                               "Test Execution Date: $dateTime",
// //                               style:
// //                               const TextStyle(
// //                                   fontSize: 14),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     );
// //                   },
// //                 );
// //               },
// //             ),
// //           ),
// //
// //           if (_isLoading)
// //             Container(
// //               color: Colors.black.withOpacity(0.5),
// //               child: const Center(
// //                 child:
// //                 CircularProgressIndicator(
// //                     color: Colors.white),
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // =========================
// //   // Popup Menu
// //   // =========================
// //
// //   void _showExportOptions(BuildContext context) async {
// //     final selected = await showMenu(
// //       context: context,
// //       position:
// //       const RelativeRect.fromLTRB(0, 800, 0, 0),
// //       items: const [
// //         PopupMenuItem(
// //           value: 'share',
// //           child: Text("Share Test Reports"),
// //         ),
// //         PopupMenuItem(
// //           value: 'find',
// //           child: Text("Find Test by Date"),
// //         ),
// //         PopupMenuItem(
// //           value: 'clear',
// //           child: Text("Show All Results"),
// //         ),
// //       ],
// //     );
// //
// //     if (selected == 'share') {
// //       _shareAllResults();
// //     } else if (selected == 'find') {
// //       _selectDateAndFindResult(context);
// //     } else if (selected == 'clear') {
// //       setState(() {
// //         displayedResults = {};
// //       });
// //     }
// //   }
// //
// //   // =========================
// //   // Share All
// //   // =========================
// //
// //   Future<void> _shareAllResults() async {
// //
// //     // If user already filtered by date,
// //     // share only displayed results
// //     if (displayedResults.isNotEmpty) {
// //       await _generateAndSharePdf(displayedResults);
// //       return;
// //     }
// //
// //     // Otherwise share all results
// //     final snapshot =
// //     await dbRef.child("Result/${widget.userMobile}").get();
// //
// //     if (!snapshot.exists || snapshot.value == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("No data to export")),
// //       );
// //       return;
// //     }
// //
// //     final data =
// //     Map<dynamic, dynamic>.from(snapshot.value as Map);
// //
// //     await _generateAndSharePdf(data);
// //   }
// //
// //
// //   // =========================
// //   // Date Picker
// //   // =========================
// //
// //   Future<void> _selectDateAndFindResult(
// //       BuildContext context) async {
// //     DateTime? pickedDate =
// //     await showDatePicker(
// //       context: context,
// //       initialDate: DateTime.now(),
// //       firstDate: DateTime(2020),
// //       lastDate: DateTime.now(),
// //     );
// //
// //     if (pickedDate == null) return;
// //
// //     await _filterResultByDate(pickedDate);
// //   }
// //
// //   // =========================
// //   // Filter Logic (dd-MM-yy)
// //   // =========================
// //
// //   Future<void> _filterResultByDate(
// //       DateTime selectedDate) async {
// //
// //
// //     final snapshot =
// //     await dbRef.child("Result/${widget.userMobile}").get();
// //
// //     if (!snapshot.exists ||
// //         snapshot.value == null) {
// //       ScaffoldMessenger.of(context)
// //           .showSnackBar(const SnackBar(
// //           content:
// //           Text("No results found")));
// //       return;
// //     }
// //
// //     final data =
// //     Map<dynamic, dynamic>.from(
// //         snapshot.value as Map);
// //
// //     String formattedDate =
// //         "${selectedDate.day.toString().padLeft(2, '0')}-"
// //         "${selectedDate.month.toString().padLeft(2, '0')}-"
// //         "${selectedDate.year.toString().substring(2)}";
// //
// //
// //     // print("Selected Date: $selectedDate");
// //     // print("Formatted Date: $formattedDate");
// //     // print("Available Keys:");
// //     // data.keys.forEach((key) => print(key));
// //
// //     Map<dynamic, dynamic> filteredData = {};
// //
// //     data.forEach((key, value) {
// //       String keyDate =
// //       key.toString().split("_")[0];
// //
// //       if (keyDate == formattedDate) {
// //         filteredData[key] = value;
// //       }
// //     });
// //
// //     if (filteredData.isEmpty) {
// //       ScaffoldMessenger.of(context)
// //           .showSnackBar(const SnackBar(
// //           content: Text(
// //               "No test found on selected date")));
// //       return;
// //     }
// //
// //     setState(() {
// //       displayedResults = filteredData;
// //     });
// //   }
// //
// //   // =========================
// //   // PDF Generator
// //   // =========================
// //
// //   Future<void> _generateAndSharePdf(
// //       Map<dynamic, dynamic> data) async {
// //     final pdf = pw.Document();
// //
// //     final dateKeys = data.keys.toList()
// //       ..sort((a, b) =>
// //           b.toString().compareTo(a.toString()));
// //
// //     pdf.addPage(
// //       pw.MultiPage(
// //         build: (pw.Context context) {
// //           return [
// //             pw.Text(
// //               displayedResults.isNotEmpty
// //                   ? "Filtered Test Report"
// //                   : "Test History Report",
// //               style: pw.TextStyle(
// //                 fontSize: 22,
// //                 fontWeight:
// //                 pw.FontWeight.bold,
// //               ),
// //             ),
// //             pw.SizedBox(height: 20),
// //             ...dateKeys.map((date) {
// //               final testData = data[date];
// //               final rawResult =
// //                   testData["result"] ?? "N/A";
// //
// //               String displayResult =
// //               rawResult
// //                   .toString()
// //                   .toLowerCase() !=
// //                   "absent"
// //                   ? "${rawResult.toString()} mg/100ml"
// //                   : "Absent";
// //
// //               return pw.Container(
// //                 margin:
// //                 const pw.EdgeInsets.only(
// //                     bottom: 10),
// //                 padding:
// //                 const pw.EdgeInsets.all(8),
// //                 decoration:
// //                 pw.BoxDecoration(
// //                   border: pw.Border.all(),
// //                 ),
// //                 child: pw.Column(
// //                   crossAxisAlignment:
// //                   pw.CrossAxisAlignment
// //                       .start,
// //                   children: [
// //                     pw.Text(
// //                         "Protein Level: $displayResult"),
// //                     pw.Text(
// //                         "Test Date: $date"),
// //                   ],
// //                 ),
// //               );
// //             }).toList(),
// //           ];
// //         },
// //       ),
// //     );
// //
// //     final output =
// //     await getTemporaryDirectory();
// //     final file = File(
// //         "${output.path}/test_history.pdf");
// //
// //     await file.writeAsBytes(
// //         await pdf.save());
// //
// //     await Share.shareXFiles(
// //         [XFile(file.path)],
// //         text:
// //         "Here is my test history report");
// //   }
// // }
//
//
//
// // import 'dart:async';
// // import 'dart:io' show Platform, File;
// // import 'dart:typed_data';
// //
// // import 'package:flutter/material.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// // import 'package:permission_handler/permission_handler.dart';
// //
// // import 'package:pdf/pdf.dart';
// // import 'package:pdf/widgets.dart' as pw;
// // import 'package:path_provider/path_provider.dart';
// // import 'package:share_plus/share_plus.dart';
// //
// //
// // class TesthistoryPage extends StatefulWidget {
// //
// //   final String userMobile;
// //   const TesthistoryPage({super.key, required this.userMobile});
// //
// //   @override
// //   State<TesthistoryPage> createState() => _TestHistoryPageState();
// // }
// //
// // class _TestHistoryPageState extends State<TesthistoryPage> {
// //   final dbRef = FirebaseDatabase.instance.ref();
// //   bool _isLoading = false;
// //   Map<dynamic, dynamic> displayedResults = {};
// //   Map<dynamic, dynamic> fullResults = {};
// //
// //
// //
// //
// //   void _handleNavigation(String selected) {
// //     final routes = {
// //       "home": "/home",
// //       "history": "/testHistory",
// //       "device": "/myDevice",
// //       "doctor": "/myDoctor",
// //     };
// //
// //     final route = routes[selected];
// //     if (route == null) return;
// //
// //     // Prevent stacking same screen
// //     if (ModalRoute.of(context)?.settings.name == route) return;
// //
// //     Navigator.pushReplacementNamed(context, route);
// //   }
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       extendBodyBehindAppBar: true,
// //       appBar: AppBar(
// //         backgroundColor: Colors.transparent,
// //         elevation: 0,
// //         centerTitle: true,
// //
// //
// //         // 👇 Add this
// //         leading: IconButton(
// //           icon: const Icon(Icons.menu, color: Colors.white),
// //           onPressed: () async {
// //             final selected = await showMenu<String>(
// //               context: context,
// //               position: const RelativeRect.fromLTRB(0, 80, 0, 0),
// //               items: [
// //                 const PopupMenuItem(
// //                   value: "home",
// //                   child: Row(
// //                     children: [
// //                       Icon(Icons.home, color: Colors.black),
// //                       SizedBox(width: 8),
// //                       Text("Home", style: TextStyle(color: Colors.black)),
// //                     ],
// //                   ),
// //                 ),
// //                 const PopupMenuItem(
// //                   value: "history",
// //                   child: Row(
// //                     children: [
// //                       Icon(Icons.history, color: Colors.black),
// //                       SizedBox(width: 8),
// //                       Text("Test History",
// //                           style: TextStyle(color: Colors.black)),
// //                     ],
// //                   ),
// //                 ),
// //                 const PopupMenuItem(
// //                   value: "device",
// //                   child: Row(
// //                     children: [
// //                       Icon(Icons.devices, color: Colors.black),
// //                       SizedBox(width: 8),
// //                       Text("My Device",
// //                           style: TextStyle(color: Colors.black)),
// //                     ],
// //                   ),
// //                 ),
// //                 const PopupMenuItem(
// //                   value: "doctor",
// //                   child: Row(
// //                     children: [
// //                       Icon(Icons.person, color: Colors.black),
// //                       SizedBox(width: 8),
// //                       Text("My Doctor",
// //                           style: TextStyle(color: Colors.black)),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             );
// //
// //             // if (selected == null) return;
// //             if (selected != null) {
// //               _handleNavigation(selected);
// //             }
// //
// //             // if (selected == "home") {
// //             //   Navigator.pushNamed(context, "/home");
// //             // } else if (selected == "history") {
// //             //   Navigator.pushNamed(context, "/testHistory");
// //             // } else if (selected == "device") {
// //             //   Navigator.pushNamed(context, "/myDevice");
// //             // } else if (selected == "doctor") {
// //             //   Navigator.pushNamed(context, "/myDoctor");
// //             // }
// //           },
// //         ),
// //         title: const Text(
// //           "Test History ",
// //           style: TextStyle(color: Colors.white, fontSize: 22),
// //         ),
// //
// //         actions: [
// //           Padding(
// //             padding: const EdgeInsets.only(right: 10),
// //             child: CircleAvatar(
// //               backgroundColor: Colors.white,
// //               child: IconButton(
// //                 icon: const Icon(Icons.expand_circle_down, color: Colors.blue),
// //                 // onPressed: () async {
// //                 //   final snapshot = await dbRef
// //                 //       .child("Result/${widget.userMobile}")
// //                 //       .get();
// //                 //
// //                 //   if (!snapshot.exists || snapshot.value == null) {
// //                 //     ScaffoldMessenger.of(context).showSnackBar(
// //                 //       const SnackBar(content: Text("No data to export")),
// //                 //     );
// //                 //     return;
// //                 //   }
// //                 //
// //                 //   final data =
// //                 //   Map<dynamic, dynamic>.from(snapshot.value as Map);
// //                 //
// //                 //   await _generateAndSharePdf(data);
// //                 // },
// //
// //                 onPressed: () {
// //                   _showExportOptions(context);
// //                 },
// //
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //       body: Stack(
// //         children: [
// //           Container(
// //             decoration: const BoxDecoration(
// //               image: DecorationImage(
// //                 image: AssetImage("assets/images/main.png"),
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //           ),
// //           // Padding(
// //           //     padding: const EdgeInsets.only(top: 70),
// //           //   child: StreamBuilder(
// //           //   stream: dbRef.child("Result/${widget.userMobile}").onValue,
// //           //   builder: (context, snapshot) {
// //           //   if (!snapshot.hasData ||
// //           //   snapshot.data?.snapshot.value == null) {
// //           //   return const Center(
// //           //   child: Text(
// //           //   "No Result Found",
// //           //   style: TextStyle(color: Colors.white),
// //           //   ),
// //           //   );
// //           //   }
// //           //
// //           //   final data =
// //           //   snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
// //           //
// //           //   final dateKeys = data.keys.toList();
// //           //
// //           //   // Optional: sort latest first
// //           //   dateKeys.sort((a, b) => b.compareTo(a));
// //           //
// //           //   return ListView.builder(
// //           //   padding: const EdgeInsets.all(12),
// //           //   itemCount: dateKeys.length,
// //           //   itemBuilder: (context, index) {
// //           //   final dateTime = dateKeys[index];
// //           //   final testData = data[dateTime];
// //           //
// //           //   final rawResult = testData["result"] ?? "N/A";
// //           //
// //           //   String displayResult;
// //           //
// //           //   if (rawResult.toString().toLowerCase() != "absent") {
// //           //   displayResult = "${rawResult.toString()} mg/100ml";
// //           //   } else {
// //           //   displayResult = "Absent";
// //           //   }
// //           //
// //           //   return Card(
// //           //   margin: const EdgeInsets.only(bottom: 12),
// //           //   child: Padding(
// //           //   padding: const EdgeInsets.all(14),
// //           //   child: Column(
// //           //   crossAxisAlignment: CrossAxisAlignment.start,
// //           //   children: [
// //           //   Text(
// //           //   "Proteins Contain Level is: $displayResult",
// //           //   style: const TextStyle(
// //           //   fontSize: 16,
// //           //   fontWeight: FontWeight.bold,
// //           //   ),
// //           //   ),
// //           //   const SizedBox(height: 6),
// //           //   Text(
// //           //   "Test Execution Date: $dateTime",
// //           //   style: const TextStyle(fontSize: 14),
// //           //   ),
// //           //   ],
// //           //   ),
// //           //   ),
// //           //   );
// //           //   },
// //           //   );
// //           //   },
// //           //   ),
// //           //   ),
// //
// //           Padding(
// //             padding: const EdgeInsets.only(top: 90),
// //             child: StreamBuilder<DatabaseEvent>(
// //               stream: dbRef
// //                   .child("Result/${widget.userMobile}")
// //                   .onValue,
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(
// //                     child: CircularProgressIndicator(color: Colors.white),
// //                   );
// //                 }
// //
// //                 if (!snapshot.hasData ||
// //                     snapshot.data?.snapshot.value == null) {
// //                   return const Center(
// //                     child: Text(
// //                       "No Result Found",
// //                       style: TextStyle(color: Colors.white),
// //                     ),
// //                   );
// //                 }
// //
// //                 final data = Map<dynamic, dynamic>.from(
// //                     snapshot.data!.snapshot.value as Map);
// //
// //                 final dateKeys = data.keys.toList()
// //                   ..sort((a, b) => b.toString().compareTo(a.toString()));
// //
// //                 return ListView.builder(
// //                   padding: const EdgeInsets.all(12),
// //                   itemCount: dateKeys.length,
// //                   itemBuilder: (context, index) {
// //                     final dateTime = dateKeys[index];
// //                     final testData =
// //                     Map<dynamic, dynamic>.from(data[dateTime]);
// //
// //                     final rawResult = testData["result"] ?? "N/A";
// //
// //                     String displayResult =
// //                     rawResult.toString().toLowerCase() != "absent"
// //                         ? "${rawResult.toString()} mg/100ml"
// //                         : "Absent";
// //
// //                     return Card(
// //                       elevation: 4,
// //                       margin: const EdgeInsets.only(bottom: 12),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: Padding(
// //                         padding: const EdgeInsets.all(14),
// //                         child: Column(
// //                           crossAxisAlignment:
// //                           CrossAxisAlignment.start,
// //                           children: [
// //                             Text(
// //                               "Proteins Contain Level: $displayResult",
// //                               style: const TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                             const SizedBox(height: 6),
// //                             Text(
// //                               "Test Execution Date: $dateTime",
// //                               style: const TextStyle(fontSize: 14),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     );
// //                   },
// //                 );
// //               },
// //             ),
// //           ),
// //
// //             if (_isLoading)
// //             Container(
// //               color: Colors.black.withOpacity(0.5),
// //               child: const Center(
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     CircularProgressIndicator(color: Colors.white),
// //                     SizedBox(height: 16),
// //                     // Text("Communicating with device…", style: TextStyle(color: Colors.white)),
// //                     Text("Load the Test Result result…",
// //                         style: TextStyle(color: Colors.white)),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Future<void> _generateAndSharePdf(
// //       Map<dynamic, dynamic> data) async {
// //
// //     final pdf = pw.Document();
// //
// //     final dateKeys = data.keys.toList()
// //       ..sort((a, b) => b.toString().compareTo(a.toString()));
// //
// //     pdf.addPage(
// //       pw.MultiPage(
// //         build: (pw.Context context) {
// //           return [
// //             pw.Text(
// //               "Test History Report",
// //               style: pw.TextStyle(
// //                 fontSize: 22,
// //                 fontWeight: pw.FontWeight.bold,
// //               ),
// //             ),
// //             pw.SizedBox(height: 20),
// //
// //             ...dateKeys.map((date) {
// //               final testData = data[date];
// //               final rawResult = testData["result"] ?? "N/A";
// //
// //               String displayResult =
// //               rawResult.toString().toLowerCase() != "absent"
// //                   ? "${rawResult.toString()} mg/100ml"
// //                   : "Absent";
// //
// //               return pw.Container(
// //                 margin: const pw.EdgeInsets.only(bottom: 10),
// //                 padding: const pw.EdgeInsets.all(8),
// //                 decoration: pw.BoxDecoration(
// //                   border: pw.Border.all(),
// //                 ),
// //                 child: pw.Column(
// //                   crossAxisAlignment: pw.CrossAxisAlignment.start,
// //                   children: [
// //                     pw.Text("Protein Level: $displayResult"),
// //                     pw.Text("Test Date: $date"),
// //                   ],
// //                 ),
// //               );
// //             }).toList(),
// //           ];
// //         },
// //       ),
// //     );
// //
// //     final output = await getTemporaryDirectory();
// //     final file = File("${output.path}/test_history.pdf");
// //     await file.writeAsBytes(await pdf.save());
// //
// //     await Share.shareXFiles([XFile(file.path)],
// //         text: "Here is my test history report");
// //   }
// //
// //   void _showExportOptions(BuildContext context) async {
// //     final RenderBox button =
// //     context.findRenderObject() as RenderBox;
// //
// //     final RenderBox overlay =
// //     Overlay.of(context).context.findRenderObject() as RenderBox;
// //
// //     final position = RelativeRect.fromRect(
// //       Rect.fromPoints(
// //         button.localToGlobal(Offset.zero, ancestor: overlay),
// //         button.localToGlobal(button.size.bottomRight(Offset.zero),
// //             ancestor: overlay),
// //       ),
// //       Offset.zero & overlay.size,
// //     );
// //
// //     final selected = await showMenu(
// //       context: context,
// //       position: position,
// //       items: const [
// //         PopupMenuItem(
// //           value: 'share',
// //           child: Text("Share All PDFs"),
// //         ),
// //         PopupMenuItem(
// //           value: 'find',
// //           child: Text("Find Test by Date"),
// //         ),
// //       ],
// //     );
// //
// //     if (selected == 'share') {
// //       _shareAllResults();
// //     } else if (selected == 'find') {
// //       _selectDateAndFindResult(context);
// //     }
// //   }
// //
// //
// //   Future<void> _shareAllResults() async {
// //     final snapshot =
// //     await dbRef.child("Result/${widget.userMobile}").get();
// //
// //     if (!snapshot.exists || snapshot.value == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("No data to export")),
// //       );
// //       return;
// //     }
// //
// //     final data =
// //     Map<dynamic, dynamic>.from(snapshot.value as Map);
// //
// //     await _generateAndSharePdf(data);
// //   }
// //
// //   Future<void> _selectDateAndFindResult(BuildContext context) async {
// //     DateTime? pickedDate = await showDatePicker(
// //       context: context,
// //       initialDate: DateTime.now(),
// //       firstDate: DateTime(2020),
// //       lastDate: DateTime.now(),
// //     );
// //
// //     if (pickedDate == null) return;
// //
// //     await _filterResultByDate(pickedDate);
// //   }
// //
// //   Future<void> _filterResultByDate(DateTime selectedDate) async {
// //     final snapshot =
// //     await dbRef.child("Result/${widget.userMobile}").get();
// //
// //     if (!snapshot.exists || snapshot.value == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("No results found")),
// //       );
// //       return;
// //     }
// //
// //     final data =
// //     Map<dynamic, dynamic>.from(snapshot.value as Map);
// //
// //     // Convert selected date to dd-MM-yy format
// //     String formattedDate =
// //         "${selectedDate.day.toString().padLeft(2, '0')}-"
// //         "${selectedDate.month.toString().padLeft(2, '0')}-"
// //         "${selectedDate.year.toString().substring(2)}";
// //
// //     Map<dynamic, dynamic> filteredData = {};
// //
// //     data.forEach((key, value) {
// //       // Split key at "_" and take only date part
// //       String keyDate = key.toString().split("_")[0];
// //
// //       if (keyDate == formattedDate) {
// //         filteredData[key] = value;
// //       }
// //     });
// //
// //     if (filteredData.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("No test found on selected date")),
// //       );
// //       return;
// //     }
// //
// //     setState(() {
// //       displayedResults = filteredData;
// //     });
// //   }
// //
// //
// //
// //
// //
// //
// //
// // }

class TesthistoryPage extends StatefulWidget {
  final UserModel user;
  final String? patientMobile;

  const TesthistoryPage({
    super.key,
    required this.user,
    this.patientMobile,
  });

  @override
  State<TesthistoryPage> createState() => _TesthistoryPageState();
}

class _TesthistoryPageState extends State<TesthistoryPage> {
  final dbRef = FirebaseDatabase.instance.ref();
  late String targetMobile;

  DateTime? _selectedDate;
  DateTimeRange? _selectedRange;
  DateTime? _selectedMonth;

  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    targetMobile = widget.patientMobile ?? widget.user.mobile;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // ---------------- FILTER ----------------

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedRange = null;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
        _selectedDate = null;
      });
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: "Select Month",
      fieldLabelText: "Month/Year",
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _selectedDate = null;
        _selectedRange = null;
      });
    }
  }
  void _clearFilter() {
    setState(() {
      _selectedDate = null;
      _selectedRange = null;
      _selectedMonth=null;
    });
  }

  void _showPopupMenu() async {
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
      items: [
        const PopupMenuItem(
          value: "filter",
          // child: Text("Filter by Date"),
          child: Row(
            children: [
              Icon(Icons.find_in_page_outlined, color: Colors.orange),
              SizedBox(width: 10),
              Text("Filter by Date"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: "pdf",
          // child: Text("Export as PDF"),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.blue),
              SizedBox(width: 10),
              Text("Export as PDF"),
            ],
          ),
        ),
        // PopupMenuItem(
        //   value: "clear",
        //   // child: Text("Clear Filter"),
        //   child: Row(
        //     children: [
        //       Icon(Icons.reply_all, color: Colors.green),
        //       SizedBox(width: 10),
        //       Text("Clear Filter"),
        //     ],
        //   ),
        // ),
        if (_selectedDate != null ||
            _selectedRange != null ||
            _selectedMonth != null)
          const PopupMenuItem(
            value: "clear",
            child: Row(
              children: [
                Icon(Icons.reply_all, color: Colors.green),
                SizedBox(width: 10),
                Text("Clear Filter"),
              ],
            ),
          ),
      ],
    );

    if (selected == "filter") {
      // _showFilterOptions();
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _isLoading = false);
      _showFilterOptions();

    } else if (selected == "pdf") {
      // _generateTablePdf();
      setState(() => _isLoading = true);
      await _generateTablePdf();
      setState(() => _isLoading = false);
    }
    else if (selected == "clear") {
      // _clearFilter();
      setState(() => _isLoading = true);
      _clearFilter();
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _isLoading = false);
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text("Single Date"),
              onTap: () {
                Navigator.pop(context);
                _pickSingleDate();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: Colors.green),
              title: const Text("Date Range"),
              onTap: () {
                Navigator.pop(context);
                _pickDateRange();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.orange),
              title: const Text("Filter by Month"),
              onTap: () {
                Navigator.pop(context);
                _pickMonth();
              },
            ),


          ],
        ),
      ),
    );
  }
  void _showFilterOptions2() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Single Date"),
              onTap: () {
                Navigator.pop(context);
                _pickSingleDate();
              },
            ),
            ListTile(
              title: const Text("Date Range"),
              onTap: () {
                Navigator.pop(context);
                _pickDateRange();
              },
            ),
            // ListTile(
            //   title: const Text("Clear Filter"),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _clearFilter();
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  // ---------------- PDF ----------------

  // Future<void> _generateTablePdf() async {
  //   final snapshot =
  //   await dbRef.child("Result/$targetMobile").get();
  //
  //   if (!snapshot.exists) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("No data available")),
  //     );
  //     return;
  //   }
  //
  //   final data =
  //   Map<dynamic, dynamic>.from(snapshot.value as Map);
  //
  //   List<Map<String, dynamic>> filteredData = [];
  //
  //   for (var key in data.keys) {
  //     try {
  //       final parts = key.toString().split("_");
  //       final date =
  //       DateFormat("dd-MM-yyyy").parse(parts[0]);
  //
  //       bool include = false;
  //
  //       if (_selectedDate != null) {
  //         include = date.year == _selectedDate!.year &&
  //             date.month == _selectedDate!.month &&
  //             date.day == _selectedDate!.day;
  //       }
  //       else if (_selectedRange != null) {
  //         include = date.isAfter(_selectedRange!.start
  //             .subtract(const Duration(days: 1))) &&
  //             date.isBefore(_selectedRange!.end
  //                 .add(const Duration(days: 1)));
  //       }
  //       else if (_selectedMonth != null) {
  //         include = date.year == _selectedMonth!.year &&
  //             date.month == _selectedMonth!.month;
  //       }
  //
  //       else {
  //         include = true;
  //       }
  //
  //       if (include) {
  //         filteredData.add({
  //           "timestamp": key,
  //           "result": data[key]["result"] ?? "N/A",
  //           "deviceId": data[key]["id"] ?? "-",
  //         });
  //       }
  //     } catch (_) {}
  //   }
  //
  //   if (filteredData.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("No data for selected filter")),
  //     );
  //     return;
  //   }
  //
  //   filteredData.sort(
  //           (a, b) => b["timestamp"].compareTo(a["timestamp"]));
  //
  //   final pdf = pw.Document();
  //   final now =
  //   DateFormat("dd-MM-yyyy HH:mm:ss").format(DateTime.now());
  //
  //   String title = "PATIENT TEST HISTORY";
  //
  //   if (_selectedDate != null) {
  //     title += "\nDate: ${DateFormat("dd/MM/yy").format(_selectedDate!)}";
  //   }
  //   else if (_selectedRange != null) {
  //     title +=
  //     "\nRange: ${DateFormat("dd/MM/yy").format(_selectedRange!.start)} "
  //         "to ${DateFormat("dd/MM/yy").format(_selectedRange!.end)}";
  //   }
  //   else if (_selectedMonth != null) {
  //     title +=
  //     "\nMonth: ${DateFormat("MMMM yy").format(_selectedMonth!)}";
  //   }
  //
  //   pdf.addPage(
  //     pw.MultiPage(
  //       build: (context) => [
  //         pw.Text(title,
  //             style: pw.TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: pw.FontWeight.bold)),
  //         pw.SizedBox(height: 5),
  //         pw.Text("Generated: $now"),
  //         pw.SizedBox(height: 10),
  //
  //         pw.Text("Name: ${widget.user.name}"),
  //         pw.Text("Mobile: $targetMobile"),
  //         pw.Text(
  //             "Age/Gender: ${widget.user.age}Y / ${widget.user.gender}"),
  //         pw.SizedBox(height: 15),
  //
  //         pw.Table.fromTextArray(
  //           headers: [
  //             "S.No",
  //             "Device ID",
  //             "Date",
  //             "Time",
  //             "Result"
  //           ],
  //           headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  //           headerDecoration:
  //           const pw.BoxDecoration(color: PdfColors.grey300),
  //           cellAlignment: pw.Alignment.center,
  //           headerAlignment: pw.Alignment.center,
  //           data: List.generate(filteredData.length,
  //                   (index) {
  //                 final item = filteredData[index];
  //                 final parts =
  //                 item["timestamp"].split("_");
  //
  //                 return [
  //                   "${index + 1}",
  //                   item["deviceId"],
  //                   parts[0],
  //                   parts.length > 1 ? parts[1] : "-",
  //                   item["result"]
  //                       .toString()
  //                       .toLowerCase() !=
  //                       "absent"
  //                       ? "${item["result"]} mg/100ml"
  //                       : "Absent",
  //                 ];
  //               }),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   final Uint8List bytes = await pdf.save();
  //   final dir = await getTemporaryDirectory();
  //   final file =
  //   File("${dir.path}/History_${widget.user.name}.pdf");
  //
  //   await file.writeAsBytes(bytes);
  //   _showShareDialog(file);
  // }

  Future<void> _generateTablePdf() async {
    final snapshot =
    await dbRef.child("Result/$targetMobile").get();

    if (!snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data available")),
      );
      return;
    }

    final data =
    Map<dynamic, dynamic>.from(snapshot.value as Map);

    List<Map<String, dynamic>> filteredData = [];

    for (var key in data.keys) {
      try {
        final parts = key.toString().split("_");
        final date =
        DateFormat("dd-MM-yyyy").parse(parts[0]);

        bool include = false;

        if (_selectedDate != null) {
          include =
              date.year == _selectedDate!.year &&
                  date.month == _selectedDate!.month &&
                  date.day == _selectedDate!.day;
        } else if (_selectedRange != null) {
          include = date.isAfter(_selectedRange!.start
              .subtract(const Duration(days: 1))) &&
              date.isBefore(_selectedRange!.end
                  .add(const Duration(days: 1)));
        } else if (_selectedMonth != null) {
          include =
              date.year == _selectedMonth!.year &&
                  date.month == _selectedMonth!.month;
        } else {
          include = true;
        }

        if (include) {
          filteredData.add({
            "timestamp": key,
            "result": data[key]["result"] ?? "N/A",
            "deviceId": data[key]["id"] ?? "-",
          });
        }
      } catch (_) {}
    }

    if (filteredData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No data for selected filter")),
      );
      return;
    }

    filteredData.sort(
            (a, b) => b["timestamp"].compareTo(a["timestamp"]));

    final pdf = pw.Document();
    final ttf = await PdfGoogleFonts.robotoRegular();
    final logo =
    await imageFromAssetBundle("assets/images/img.png");

    final now = DateFormat("dd-MM-yyyy HH:mm:ss")
        .format(DateTime.now());

    String title = "PATIENT TEST HISTORY";

    if (_selectedDate != null) {
      title +=
      "\nDate: ${DateFormat("dd/MM/yy").format(_selectedDate!)}";
    } else if (_selectedRange != null) {
      title +=
      "\nRange: ${DateFormat("dd/MM/yy").format(_selectedRange!.start)} "
          "to ${DateFormat("dd/MM/yy").format(_selectedRange!.end)}";
    } else if (_selectedMonth != null) {
      title +=
      "\nMonth: ${DateFormat("MMMM yy").format(_selectedMonth!)}";
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),

        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
        ),

        /// HEADER (LIKE RECHARGE PDF)
        header: (context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment:
                pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logo, width: 60, height: 60),

                  pw.Column(
                    crossAxisAlignment:
                    pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        widget.user.name.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text("Mobile: $targetMobile"),

                      pw.Text(
                          "Age/Gender: ${widget.user.age}Y / ${widget.user.gender}"),
                      pw.Text(
                        "Generated: $now",
                        style:
                        const pw.TextStyle(fontSize: 10),
                      ),

                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              pw.Text(
                title,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 15),
            ],
          );
        },
        /// 🔹 FOOTER SECTION
        footer: (context) => pw.Column(
          children: [

            pw.Divider(),

            pw.SizedBox(height: 5),

            pw.Text(
                "Device Sensitivity: 94.2%   Specificity: 94.5%"),

            pw.Text(
                "Powered by: Cutting Edge Medical Device Pvt. Ltd, Indore"),

            pw.Text("www.cemd.in" ,style: pw.TextStyle(
            color: PdfColors.blue,
            ),),

            /// Computer Generated + Page No on same line
            pw.Stack(
              children: [

                /// Center Text
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "Computer Generated PDF",
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),

                /// Right Side Page Number
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "Page No. ${context.pageNumber} / ${context.pagesCount}",
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),

            // pw.SizedBox(height: 8),

            /// Page Number
            // pw.Text(
            //   "Page ${context.pageNumber} / ${context.pagesCount}",
            //   style: const pw.TextStyle(fontSize: 10),
            // ),

            // /// Page number aligned to right
            // pw.Row(
            //   mainAxisAlignment: pw.MainAxisAlignment.end,
            //   children: [
            //     pw.Text(
            //       "Page No. ${context.pageNumber} / ${context.pagesCount}",
            //       style: const pw.TextStyle(fontSize: 10),
            //     ),
            //   ],
            // ),
          ],
        ),

        build: (context) => [

          // pw.Text(
          //   title,
          //   textAlign: pw.TextAlign.center,
          //   style: pw.TextStyle(
          //       fontSize: 18,
          //       fontWeight: pw.FontWeight.bold),
          // ),
          //
          // pw.SizedBox(height: 5),
          //
          // pw.Text("Generated: $now",
          //     textAlign: pw.TextAlign.center),
          //
          // pw.SizedBox(height: 15),
          //
          // pw.Text("Name: ${widget.user.name}"),
          // pw.Text("Mobile: $targetMobile"),
          // pw.Text(
          //     "Age/Gender: ${widget.user.age}Y / ${widget.user.gender}"),
          //
          // pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: [
              "S.No",
              "Device ID",
              "Date",
              "Time",
              "Result"
            ],
            headerStyle:
            pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration:
            const pw.BoxDecoration(
                color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
            headerAlignment: pw.Alignment.center,
            data: List.generate(
                filteredData.length, (index) {
              final item = filteredData[index];
              final parts =
              item["timestamp"].split("_");

              return [
                "${index + 1}",
                item["deviceId"],
                parts[0],
                parts.length > 1 ? parts[1] : "-",
                item["result"]
                    .toString()
                    .toLowerCase() !=
                    "absent"
                    ? "${item["result"]} mg/100ml"
                    : "Absent",
              ];
            }),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file =
    File("${dir.path}/History_${widget.user.name}.pdf");

    await file.writeAsBytes(bytes);

    _showShareDialog(file);
  }
  void _showShareDialog(File file) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Choose Action"),
        content:
        const Text("Would you like to View or Share the Test History PDF?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Printing.layoutPdf(
                onLayout: (_) => file.readAsBytes(),
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

  // ---------------- UI ----------------

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     extendBodyBehindAppBar: true,
  //     appBar: AppBar(
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       centerTitle: true,
  //
  //
  //       // 👇 Add this
  //       leading: IconButton(
  //         icon: const Icon(Icons.menu, color: Colors.white),
  //         onPressed: () async {
  //           final selected = await showMenu<String>(
  //             context: context,
  //             position: const RelativeRect.fromLTRB(0, 80, 0, 0),
  //             items: [
  //               const PopupMenuItem(
  //                 value: "home",
  //                 child: Row(
  //                   children: [
  //                     Icon(Icons.home, color: Colors.black),
  //                     SizedBox(width: 8),
  //                     Text("Home", style: TextStyle(color: Colors.black)),
  //                   ],
  //                 ),
  //               ),
  //               const PopupMenuItem(
  //                 value: "profile",
  //                 child: Row(
  //                   children: [
  //                     Icon(Icons.person, color: Colors.black),
  //                     SizedBox(width: 8),
  //                     Text("My Profile",
  //                         style: TextStyle(color: Colors.black)),
  //                   ],
  //                 ),
  //               ),
  //               const PopupMenuItem(
  //                 value: "device",
  //                 child: Row(
  //                   children: [
  //                     Icon(Icons.devices, color: Colors.black),
  //                     SizedBox(width: 8),
  //                     Text("My Device",
  //                         style: TextStyle(color: Colors.black)),
  //                   ],
  //                 ),
  //               ),
  //               const PopupMenuItem(
  //                 value: "doctor",
  //                 child: Row(
  //                   children: [
  //                     Icon(Icons.people, color: Colors.black),
  //                     SizedBox(width: 8),
  //                     Text("My Doctor",
  //                         style: TextStyle(color: Colors.black)),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           );
  //
  //           // // if (selected == null) return;
  //           // if (selected != null) {
  //           //   _handleNavigation(selected);
  //           // }
  //
  //           if (selected == "home") {
  //             Navigator.pushNamed(context, "/home");
  //           }
  //           // else if (selected == "history") {
  //           //   // Navigator.pushNamed(context, "/testHistory");
  //           //   Navigator.push(
  //           //     context,
  //           //     MaterialPageRoute(
  //           //       builder: (_) => TesthistoryPage(
  //           //         userMobile: widget.userMobile,
  //           //         name: widget.name,
  //           //         age: widget.age,
  //           //         gender: widget.gender,
  //           //         address: widget.address,
  //           //         disease: widget.disease,
  //           //       ),
  //           //     ),
  //           //   );
  //           // }
  //           else if (selected == "device") {
  //             // Navigator.pushNamed(context, "/myDevice");
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (_) => MyDevicesPage2(
  //                   user: widget.user,
  //                 ),
  //               ),
  //             );
  //           }
  //           else if (selected == "profile") {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (_) => MyProfileScreen(
  //                   user: widget.user,
  //                 ),
  //               ),
  //             );
  //           }
  //
  //
  //           else if (selected == "doctor") {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (_) => MyDoctorPage(
  //                   user: widget.user,
  //                 ),
  //               ),
  //             );
  //           }
  //
  //           //     else if (selected == "doctor") {
  //           //       Navigator.pushNamed(context, "/myDoctor");
  //           //       // Navigator.push(
  //           //       //   context,
  //           //       //   MaterialPageRoute(
  //           //       //     builder: (_) => MyDoctorPage(
  //           //       //       mobile: widget.userMobile,
  //           //       //       name: widget.name,
  //           //       //       age: widget.age,
  //           //       //       email: widget.email,
  //           //       //       address: widget.address,
  //           //       //       gender: widget.gender,
  //           //       //       imageBase64: widget.imageBase64,
  //           //       //       disease: widget.disease,
  //           //       //       type: widget.type,
  //           //       //       specialization: widget.specialization,
  //           //       //       clinicName: clinicName,
  //           //       //
  //           //       //       // allDoctorsType: null,   // only used for admin
  //           //       //       // 👇 This is the part you wanted
  //           //       //       allDoctorsType: type.toLowerCase() == "admin" ? "aallDoct" : null,
  //           //       //     ),
  //           //       //   ),
  //           //       // );
  //           //     }
  //         },
  //       ),
  //       title: const Text(
  //         "Test History",
  //         style: TextStyle(color: Colors.white),
  //       ),
  //       actions: [
  //         IconButton(
  //           icon: const Icon(Icons.more_vert,
  //               color: Colors.white),
  //           onPressed: _showPopupMenu,
  //         ),
  //       ],
  //     ),
  //     body: Container(
  //       decoration: const BoxDecoration(
  //         image: DecorationImage(
  //           image: AssetImage("assets/images/main.png"),
  //           fit: BoxFit.cover,
  //         ),
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.only(top: 90),
  //         child: StreamBuilder<DatabaseEvent>(
  //           stream:
  //           dbRef.child("Result/$targetMobile").onValue,
  //           builder: (context, snapshot) {
  //             if (!snapshot.hasData ||
  //                 snapshot.data?.snapshot.value ==
  //                     null) {
  //               return const Center(
  //                 child: Text(
  //                   "No Result Found",
  //                   style:
  //                   TextStyle(color: Colors.white),
  //                 ),
  //               );
  //             }
  //
  //             final data =
  //             Map<dynamic, dynamic>.from(
  //                 snapshot.data!.snapshot.value
  //                 as Map);
  //
  //             List<String> filteredKeys = [];
  //
  //             for (var key in data.keys) {
  //               try {
  //                 final parts =
  //                 key.toString().split("_");
  //                 final date = DateFormat(
  //                     "dd-MM-yyyy")
  //                     .parse(parts[0]);
  //
  //                 bool include = false;
  //
  //                 if (_selectedDate != null) {
  //                   include =
  //                       date.year ==
  //                           _selectedDate!.year &&
  //                           date.month ==
  //                               _selectedDate!.month &&
  //                           date.day ==
  //                               _selectedDate!.day;
  //                 } else if (_selectedRange !=
  //                     null) {
  //                   include = date.isAfter(
  //                       _selectedRange!.start
  //                           .subtract(
  //                           const Duration(
  //                               days: 1))) &&
  //                       date.isBefore(
  //                           _selectedRange!.end
  //                               .add(const Duration(
  //                               days: 1)));
  //                 } else {
  //                   include = true;
  //                 }
  //
  //                 if (include) {
  //                   filteredKeys.add(key);
  //                 }
  //               } catch (_) {}
  //             }
  //
  //             filteredKeys.sort((a, b) =>
  //                 b.toString().compareTo(a.toString()));
  //
  //             if (filteredKeys.isEmpty) {
  //               return const Center(
  //                 child: Text(
  //                   "No Result Found for \n Selected Date",
  //                   style:
  //                   TextStyle(color: Colors.white),
  //                 ),
  //               );
  //             }
  //
  //             return ListView.builder(
  //               padding:
  //               const EdgeInsets.all(12),
  //               itemCount:
  //               filteredKeys.length,
  //               itemBuilder:
  //                   (context, index) {
  //                 final key =
  //                 filteredKeys[index];
  //                 final testData =
  //                 Map<dynamic, dynamic>.from(
  //                     data[key]);
  //
  //                 final rawResult =
  //                     testData["result"] ??
  //                         "N/A";
  //
  //                 String displayResult =
  //                 rawResult
  //                     .toString()
  //                     .toLowerCase() !=
  //                     "absent"
  //                     ? "${rawResult.toString()} mg/100ml"
  //                     : "Absent";
  //
  //                 return Card(
  //                   margin:
  //                   const EdgeInsets.only(
  //                       bottom: 12),
  //                   shape:
  //                   RoundedRectangleBorder(
  //                     borderRadius:
  //                     BorderRadius.circular(
  //                         12),
  //                   ),
  //                   child: Padding(
  //                     padding:
  //                     const EdgeInsets.all(
  //                         14),
  //                     child: Row(
  //                       mainAxisAlignment:
  //                       MainAxisAlignment
  //                           .spaceBetween,
  //                       children: [
  //                         const Column(
  //                           crossAxisAlignment:
  //                           CrossAxisAlignment
  //                               .start,
  //                           children: [
  //                             Text(
  //                               "Proteins Contain Level",
  //                               style: TextStyle(
  //                                   fontSize:
  //                                   16,
  //                                   fontWeight:
  //                                   FontWeight
  //                                       .w500),
  //                             ),
  //                             SizedBox(
  //                                 height: 6),
  //                             Text(
  //                               "Test Execution Date & Time",
  //                               style: TextStyle(
  //                                   fontSize:
  //                                   14,
  //                                   color: Colors
  //                                       .grey),
  //                             ),
  //                           ],
  //                         ),
  //                         Column(
  //                           crossAxisAlignment:
  //                           CrossAxisAlignment
  //                               .end,
  //                           children: [
  //                             Text(
  //                               displayResult,
  //                               style:
  //                               const TextStyle(
  //                                 fontSize:
  //                                 16,
  //                                 fontWeight:
  //                                 FontWeight
  //                                     .bold,
  //                                 color: Colors
  //                                     .blue,
  //                               ),
  //                             ),
  //                             const SizedBox(
  //                                 height: 6),
  //                             Text(key),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 );
  //               },
  //             );
  //           },
  //         ),
  //       ),
  //     ),
  //
  //   );
  //
  // }
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
                        value: "profile",
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.black),
                            SizedBox(width: 8),
                            Text("My Profile",
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
                            Icon(Icons.people, color: Colors.black),
                            SizedBox(width: 8),
                            Text("My Doctor",
                                style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  );

                  // // if (selected == null) return;
                  // if (selected != null) {
                  //   _handleNavigation(selected);
                  // }

                  if (selected == "home") {
                    Navigator.pushNamed(context, "/home");
                  }
                  // else if (selected == "history") {
                  //   // Navigator.pushNamed(context, "/testHistory");
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (_) => TesthistoryPage(
                  //         userMobile: widget.userMobile,
                  //         name: widget.name,
                  //         age: widget.age,
                  //         gender: widget.gender,
                  //         address: widget.address,
                  //         disease: widget.disease,
                  //       ),
                  //     ),
                  //   );
                  // }
                  else if (selected == "device") {
                    // Navigator.pushNamed(context, "/myDevice");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyDevicesPage2(
                          user: widget.user,
                        ),
                      ),
                    );
                  }
                  else if (selected == "profile") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyProfileScreen(
                          user: widget.user,
                        ),
                      ),
                    );
                  }


                  else if (selected == "doctor") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyDoctorPage(
                          user: widget.user,
                        ),
                      ),
                    );
                  }

                  //     else if (selected == "doctor") {
                  //       Navigator.pushNamed(context, "/myDoctor");
                  //       // Navigator.push(
                  //       //   context,
                  //       //   MaterialPageRoute(
                  //       //     builder: (_) => MyDoctorPage(
                  //       //       mobile: widget.userMobile,
                  //       //       name: widget.name,
                  //       //       age: widget.age,
                  //       //       email: widget.email,
                  //       //       address: widget.address,
                  //       //       gender: widget.gender,
                  //       //       imageBase64: widget.imageBase64,
                  //       //       disease: widget.disease,
                  //       //       type: widget.type,
                  //       //       specialization: widget.specialization,
                  //       //       clinicName: clinicName,
                  //       //
                  //       //       // allDoctorsType: null,   // only used for admin
                  //       //       // 👇 This is the part you wanted
                  //       //       allDoctorsType: type.toLowerCase() == "admin" ? "aallDoct" : null,
                  //       //     ),
                  //       //   ),
                  //       // );
                  //     }
                },
              ),
        title: const Text(
          "Test History",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showPopupMenu,
          ),
        ],
      ),

      body: Stack(
        children: [

          /// 🔹 Background + Main Content
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/main.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 90),
              child: StreamBuilder<DatabaseEvent>(
                stream: dbRef.child("Result/$targetMobile").onValue,
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

                  final data = Map<dynamic, dynamic>.from(
                      snapshot.data!.snapshot.value as Map);

                  List<String> filteredKeys = [];

                  for (var key in data.keys) {
                    try {
                      final parts = key.toString().split("_");
                      final date =
                      DateFormat("dd-MM-yyyy").parse(parts[0]);

                      bool include = false;

                      /// Single Date
                      if (_selectedDate != null) {
                        include =
                            date.year == _selectedDate!.year &&
                                date.month == _selectedDate!.month &&
                                date.day == _selectedDate!.day;
                      }

                      /// Date Range
                      else if (_selectedRange != null) {
                        include = date.isAfter(
                            _selectedRange!.start
                                .subtract(const Duration(days: 1))) &&
                            date.isBefore(
                                _selectedRange!.end
                                    .add(const Duration(days: 1)));
                      }

                      /// Month Filter
                      else if (_selectedMonth != null) {
                        include =
                            date.year == _selectedMonth!.year &&
                                date.month == _selectedMonth!.month;
                      }

                      /// No Filter
                      else {
                        include = true;
                      }

                      if (include) {
                        filteredKeys.add(key);
                      }
                    } catch (_) {}
                  }

                  /// Sort latest first
                  filteredKeys.sort(
                          (a, b) => b.toString().compareTo(a.toString()));

                  if (filteredKeys.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Result Found for \n Selected Filter",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredKeys.length,
                    itemBuilder: (context, index) {

                      final key = filteredKeys[index];
                      final testData =
                      Map<dynamic, dynamic>.from(data[key]);

                      final rawResult = testData["result"] ?? "N/A";

                      String displayResult =
                      rawResult.toString().toLowerCase() != "absent"
                          ? "${rawResult.toString()} mg/100ml"
                          : "Absent";

                      return Card(
                        margin:
                        const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding:
                          const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [

                              /// Left side
                              const Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Proteins Contain Level",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                        FontWeight.w500),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "Test Execution Date & Time",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey),
                                  ),
                                ],
                              ),

                              /// Right side
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    displayResult,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(key),
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
          ),

          /// 🔹 Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Loading ....",
                      style:
                      TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}