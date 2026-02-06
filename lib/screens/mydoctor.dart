import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'myprofile.dart';

class MyDoctorPage extends StatefulWidget {
  final String mobile;
  final String name;
  final String age;
  final String email;
  final String address;
  final String gender;
  final String disease;
  final String imageBase64;
  final String type;
  final String? specialization;
  final String? clinicName;
  final String? allDoctorsType; // expected: "aallDoct" or "aallPst"

  const MyDoctorPage({
    super.key,
    required this.mobile,
    required this.name,
    required this.age,
    required this.email,
    required this.address,
    required this.gender,
    required this.disease,
    required this.imageBase64,
    required this.type,
    this.specialization,
    this.clinicName,
    this.allDoctorsType,
  });

  static const routeName = '/myDoctor';
  @override
  State<MyDoctorPage> createState() => _MyDoctorPageState();
}


// class MyDoctorPage extends StatefulWidget {
//   const MyDoctorPage({Key? key}) : super(key: key);
//   static const routeName = '/myDoctor';
//   @override
//   State<MyDoctorPage> createState() => _MyDoctorPageState();
// }
class _MyDoctorPageState extends State<MyDoctorPage> {
  List<Map<String, String>> doctorList = []; // patient -> doctors
  List<Map<String, String>> patientList = []; // doctor -> patients
  List<Map<String, String>> allDoctorList = []; // admin -> all doctors
  List<Map<String, String>> allPatientList = []; // admin -> all patients

  bool _loading = true;
  String _modeDebug = "";

  @override
  void initState() {
    super.initState();
    _loadPageLogic();
  }

  void _logMode(String s) {
    _modeDebug = s;
    // helpful for quick debugging in logs
    // ignore: avoid_print
    print("MyDoctorPage mode -> $s");
  }

  void _loadPageLogic() {
    final type = widget.type.toLowerCase();
    final allFlag = widget.allDoctorsType?.toLowerCase() ?? "";

    // _logMode("type=$type | allFlag=$allFlag");
    _loading = true;

    if (type == "doctor") {
      // _logMode("doctor mode — loading patients for ${widget.mobile}");
      _findPatients(widget.mobile).whenComplete(() => setState(() { _loading = false; }));
    } else if (type == "admin") {
      if (allFlag == "aalldoct") {
        // _logMode("admin mode — loading ALL doctors");
        _findAllDoctors().whenComplete(() => setState(() { _loading = false; }));
      } else if (allFlag == "aallpst") {
        _logMode("admin mode — loading ALL patients");
        _findAllPatients().whenComplete(() => setState(() { _loading = false; }));
      } else {
        // if admin but no flag, default to all doctors
        _logMode("admin mode — no flag provided, defaulting to ALL doctors");
        _findAllDoctors().whenComplete(() => setState(() { _loading = false; }));
      }
    } else {
      // _logMode("patient mode — loading doctors for patient ${widget.mobile}");
      _findDoctorsForPatient(widget.mobile).whenComplete(() => setState(() { _loading = false; }));
    }
  }

  // ----------------------------
  // 1) Patient -> Doctors
  // ----------------------------
  Future<void> _findDoctorsForPatient(String patientNumber) async {
    try {
      final ref = FirebaseDatabase.instance.ref("users/doctor");
      final snapshot = await ref.get();

      doctorList.clear();

      for (var doc in snapshot.children) {
        // check existence and truthiness
        if (doc.child("patients/$patientNumber").exists) {
          final val = doc.child("patients/$patientNumber").value;
          final isTrue = (val is bool) ? val : (val?.toString().toLowerCase() == 'true');
          if (isTrue == true) {
            final doctorMobile = doc.key?.toString() ?? "";
            final name = doc.child("name").value?.toString() ?? "";
            final specialization = doc.child("specialization").value?.toString() ?? "N/A";
            final clinicName = doc.child("clinicName").value?.toString() ?? "N/A";

            doctorList.add({
              "name": "Dr. ${name.toUpperCase()}",
              "mobile": doctorMobile,
              "detailLeft": specialization.toUpperCase(),
              "detailRight": clinicName,
            });

            // original Java breaks after first match — keep same behavior
            break;
          }
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print("Error in _findDoctorsForPatient: $e\n$st");
    } finally {
      setState(() {});
    }
  }

  // ----------------------------
  // 2) Doctor -> Patients
  // ----------------------------
  Future<void> _findPatients(String doctorNumber) async {
    try {
      final ref = FirebaseDatabase.instance.ref("users/doctor/$doctorNumber/patients");
      final snapshot = await ref.get();

      patientList.clear();

      if (!snapshot.exists) {
        // nothing linked
        setState(() {});
        return;
      }

      for (var p in snapshot.children) {
        final val = p.value;
        final active = (val is bool) ? val : (val?.toString().toLowerCase() == 'true');
        final mobile = p.key?.toString() ?? "";

        if (active == true && mobile.isNotEmpty) {
          final snap = await FirebaseDatabase.instance.ref("users/patient/$mobile").get();

          final name = snap.child("name").value?.toString() ?? "";
          final disease = snap.child("disease").value?.toString() ?? "N/A";
          final age = snap.child("age").value?.toString() ?? "";
          final address = snap.child("address").value?.toString() ?? "";

          // show age on right if present, otherwise truncated address
          final right = age.isNotEmpty ? age : (address.length > 20 ? "${address.substring(0, 20)}..." : address);

          patientList.add({
            "name": name.toUpperCase(),
            "mobile": mobile,
            "detailLeft": disease.toUpperCase(),
            "detailRight": right,
          });
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print("Error in _findPatients: $e\n$st");
    } finally {
      setState(() {});
    }
  }

  // ----------------------------
  // 3) Admin -> All Doctors
  // ----------------------------
  Future<void> _findAllDoctors() async {
    try {
      final ref = FirebaseDatabase.instance.ref("users/doctor");
      final snapshot = await ref.get();

      allDoctorList.clear();

      for (var d in snapshot.children) {
        final mobile = d.key?.toString() ?? "";
        final name = d.child("name").value?.toString() ?? "";
        final spec = d.child("specialization").value?.toString() ?? "N/A";
        final clinic = d.child("clinicName").value?.toString() ?? "N/A";

        allDoctorList.add({
          "name": "Dr. ${name.toUpperCase()}",
          "mobile": mobile,
          "detailLeft": spec.toUpperCase(),
          "detailRight": clinic,
        });
      }
    } catch (e, st) {
      // ignore: avoid_print
      print("Error in _findAllDoctors: $e\n$st");
    } finally {
      setState(() {});
    }
  }

  // ----------------------------
  // 4) Admin -> All Patients
  // ----------------------------
  Future<void> _findAllPatients() async {
    try {
      final ref = FirebaseDatabase.instance.ref("users/patient");
      final snapshot = await ref.get();

      allPatientList.clear();

      for (var p in snapshot.children) {
        final mobile = p.key?.toString() ?? "";
        final name = p.child("name").value?.toString() ?? "";
        final disease = p.child("disease").value?.toString() ?? "N/A";
        final address = p.child("address").value?.toString() ?? "";

        final trimmed = address.length > 20 ? "${address.substring(0, 20)}..." : address;

        allPatientList.add({
          "name": name.toUpperCase(),
          "mobile": mobile,
          "detailLeft": disease.toUpperCase(),
          "detailRight": trimmed,
        });
      }
    } catch (e, st) {
      // ignore: avoid_print
      print("Error in _findAllPatients: $e\n$st");
    } finally {
      setState(() {});
    }
  }

  // ----------------------------
  // choose which list to show
  // ----------------------------
  List<Map<String, String>> currentList() {
    final type = widget.type.toLowerCase();
    final allFlag = widget.allDoctorsType?.toLowerCase() ?? "";

    if (type == "doctor") return patientList;
    if (type == "admin" && allFlag == "aalldoct") return allDoctorList;
    if (type == "admin" && allFlag == "aallpst") return allPatientList;
    return doctorList;
  }

  // ----------------------------
  // dynamic details for second row
  // ----------------------------
  String _leftDetail(Map<String, String> item) {
    return item["detailLeft"] ?? item["spec"] ?? "";
  }

  String _rightDetail(Map<String, String> item) {
    return item["detailRight"] ?? item["clinic"] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    void _showUserDetails() {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("User Details"),
          content: Text(
            "Name: ${widget.name}\n"
                "Mobile: ${widget.mobile}\n"
                "Type: ${widget.type}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    }



    final type = widget.type.toLowerCase();
    final allFlag = widget.allDoctorsType?.toLowerCase() ?? "";

    final pageTitle = type == "doctor"
        ? "My Patients"
        : type == "admin"
        ? (allFlag == "aalldoct" ? "All Doctors" : "All Patients")
        : "My Doctors";

    final list = currentList();

    return Scaffold(
      backgroundColor: const Color(0xFF6D8EBE),
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Popup Menu (Black text/icons)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onSelected: (value) {
                      if (value == "home") {
                        Navigator.pushNamed(context, "/home");
                      } else if (value == "history") {
                        Navigator.pushNamed(context, "/testHistory");
                      } else if (value == "device") {
                        Navigator.pushNamed(context, "/myDevice");
                      } else if (value == "profile") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyProfileScreen(),
                          ),
                        );

                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: "home",
                          child: Row(
                            children: const [
                              Icon(Icons.home, color: Colors.black),
                              SizedBox(width: 8),
                              Text("Home",
                                  style:
                                  TextStyle(color: Colors.black)),
                            ],
                          )),
                      PopupMenuItem(
                          value: "history",
                          child: Row(
                            children: const [
                              Icon(Icons.history, color: Colors.black),
                              SizedBox(width: 8),
                              Text("Test History",
                                  style:
                                  TextStyle(color: Colors.black)),
                            ],
                          )),
                      PopupMenuItem(
                          value: "device",
                          child: Row(
                            children: const [
                              Icon(Icons.devices, color: Colors.black),
                              SizedBox(width: 8),
                              Text("My Device",
                                  style:
                                  TextStyle(color: Colors.black)),
                            ],
                          )),
                      PopupMenuItem(
                          value: "profile",
                          child: Row(
                            children: const [
                              Icon(Icons.person, color: Colors.black),
                              SizedBox(width: 8),
                              Text("My Profile",
                                  style:
                                  TextStyle(color: Colors.black)),
                            ],
                          )),
                    ],
                  ),
                  // Icon(Icons.add, color: Colors.white),

                  // Add icon shows user details
                  GestureDetector(
                    onTap: _showUserDetails,
                    child: const Icon(Icons.info, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // debug line (optional, remove if not needed)
            if (_modeDebug.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(_modeDebug, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),

            // content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                  ? Center(
                child: Text(
                  // helpful user message
                  type == "doctor"
                      ? "No patients found"
                      : type == "admin"
                      ? (allFlag == "aalldoct" ? "No doctors found" : "No patients found")
                      : "No doctors found",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, index) {
                  final item = list[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // first row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item["name"] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item["mobile"] ?? "",
                                style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // second row dynamic
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(_leftDetail(item), style: const TextStyle(fontSize: 14))),
                              const SizedBox(width: 8),
                              Text(_rightDetail(item), style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("User Details"),
              content: Text("Name: ${widget.name}\nMobile: ${widget.mobile}\nType: ${widget.type}"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
              ],
            ),
          );
        },
      ),
    );
  }
}
