import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:privy_181125/screens/myDevice_BLE.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'myprofile.dart';
import 'mydoctor.dart';
// import 'myDevice.dart';
import 'bleScan.dart';
import 'myDevicesPage.dart';
import "testHistory.dart";

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  final Map<String, dynamic>? savedUserData;

  const HomeScreen({super.key, this.savedUserData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String name = "";
  String age = "";
  String mobile = "";
  String email = "";
  String address = "";
  String gender = "";
  String imageBase64 = "";
  String disease = "";
  String clinicName = "";
  String specialization = "";
  String type = "";
  String count = "0";

  bool _loadedPrefs = false;
  late DatabaseReference testReqRef;

  @override
  void initState() {
    super.initState();
    print("🔍 imageBase64 received: $imageBase64");

    if (imageBase64.isEmpty) {
      print("⚠ No image received. Using default photo.");
    }
    _loadLocalPrefs();
  }

  Future<void> _loadLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    mobile = prefs.getString("mobile") ?? "";
    name = prefs.getString("name") ?? "";
    age = prefs.getString("age") ?? "";
    email = prefs.getString("email") ?? "";
    address = prefs.getString("address") ?? "";
    gender = prefs.getString("gender") ?? "";
    imageBase64 = prefs.getString("imageBase64") ?? "";
    type = prefs.getString("type") ?? "";
    count = prefs.getString("count") ?? "0";

    if (type == "doctor") {
      specialization = prefs.getString("specialization") ?? "";
      clinicName = prefs.getString("clinicName") ?? "";
      disease = "NA";
    } else {
      disease = prefs.getString("diseaseType") ?? "";
      specialization = "NA";
      clinicName = "NA";
    }

    if (widget.savedUserData != null) {
      final u = widget.savedUserData!;
      name = u['name'] ?? name;
      age = u['age'] ?? age;
      mobile = u['mobile'] ?? mobile;
      email = u['email'] ?? email;
      address = u['address'] ?? address;
      gender = u['gender'] ?? gender;
      imageBase64 = u['imageBase64'] ?? imageBase64;
      type = u['type'] ?? type;
      count = u['count'] ?? count;
      specialization = u['specialization'] ?? specialization;
      clinicName = u['clinicName'] ?? clinicName;
      disease = u['diseaseType'] ?? disease;
    }

    setState(() => _loadedPrefs = true);
    _startAutoCheck();
  }

  void _startAutoCheck() {
    if (mobile.isEmpty) return;
    testReqRef = FirebaseDatabase.instance.ref("TestRequests").child(mobile);

    testReqRef.onValue.listen((event) {
      if (event.snapshot.value == null) return;

      final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>);

      final status = data["st"] ?? "w";
      final oldCount = data["OC"] ?? "0";
      final totalCount = data["TC"] ?? "0";
      final totalAmount = data["TA"] ?? "0";

      if (status == "a") {
        _handleAutoApproval(
            oldCount.toString(), totalCount.toString(), totalAmount.toString());
      }
    });
  }

  Future<void> _handleAutoApproval(
      String oldCount, String totalCount, String totalAmount) async {
         final doctorRef = FirebaseDatabase.instance
        .ref("users/doctor")
        .child(mobile)
        .child("count");

    await doctorRef.set(totalCount);

    final prefs = await SharedPreferences.getInstance();
    prefs.setString("count", totalCount);
    count = totalCount;

    final historyRef = FirebaseDatabase.instance.ref("ApH").child(mobile);
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await historyRef.child(id).set({
      "OC": oldCount,
      "TC": totalCount,
      "TA": totalAmount,
      "st": "a",
    });

    await testReqRef.remove();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Remaining Test Count"),
        content: Text(count),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"))
        ],
      ),
    );
  }

  ImageProvider<Object> _decodeBase64() {
    try {
      if (imageBase64.isEmpty) {
        print("⚠ Base64 string EMPTY. Showing default image.");
        return const AssetImage("assets/images/default_user.png");
      }

      print("📥 Attempting to decode Base64...");

      // Cleanup broken base64
      String cleanBase64 = imageBase64
          .replaceAll("\n", "")
          .replaceAll("\r", "")
          .replaceAll(" ", "");

      print("🔧 Cleaned Base64 length: ${cleanBase64.length}");

      final bytes = base64Decode(cleanBase64);
      print("✅ Decoded successfully. Bytes: ${bytes.length}");

      return MemoryImage(bytes);

    } catch (e) {
      print("❌ Error decoding Base64: $e");
      return const AssetImage("assets/images/default_user.png");
    }
  }



  @override
  Widget build(BuildContext context) {
    if (!_loadedPrefs) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/main.png", fit: BoxFit.cover),
          ),

          // ------------ TOP HEADER ------------
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // CircleAvatar(
                //   radius: 40,
                //   backgroundImage: _decodeBase64(),
                // ),

                ClipOval(
                  child: Image(
                    image: _decodeBase64(),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),

                Expanded(
                  child: Column(
                    children: [
                      Text(
                        type == "doctor" ? "Dr. $name" : name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Mob: $mobile",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      )
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  iconSize: 30,
                  onPressed: _logout,
                )
              ],
            ),
          ),

          // ------------ MENU BUTTONS ------------
          Padding(
            padding: const EdgeInsets.only(top: 150),
            child: Column(
              children: [
                _menuButton("Test History", Icons.history, _onTestHistory),
                const SizedBox(height: 12),
                _menuButton("My Device   ", Icons.devices, _onMyDevice),
                const SizedBox(height: 12),
                _menuButton(
                  // type == "doctor" ? "My Patient  " : "My Doctor   ",
                  type == "admin"
                      ? "All Doctors"
                      : type == "doctor"
                      ? "My Patient"
                      : "My Doctor ",

                  Icons.people,
                  _onMyDoctor,
                ),
                const SizedBox(height: 12),
                _menuButton("My Profile   ", Icons.person, _onMyProfile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------ GLASS BUTTON ------------
  Widget _menuButton(String text, IconData icon, VoidCallback onTap) {
    const double maxWidth = 260;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------ MENU ACTIONS ------------
  void _onTestHistory() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Open TestHistory")));
    Navigator.push(
      context,
           MaterialPageRoute(builder: (_) => TesthistoryPage(
               userMobile: mobile,
             name: name,
             age: age,
             gender: gender,
             disease: disease,
             address: address,
           )),


    );
  }

  void _onMyDevice() {
    print("OPEN MyDevice WITH MOBILE → $mobile");
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Open MyDevice  $mobile ")));
    Navigator.push(
      context,
      // MaterialPageRoute(builder: (_) => BleScan()),
      // MaterialPageRoute(builder: (_) => MyDevicesPage(userMobile: mobile)),
      MaterialPageRoute(builder: (_) => MyDevicesPage2(userMobile: mobile)),

      // MaterialPageRoute(builder: (_) => BLEPage()),


    );

  }

  void _onMyDoctor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyDoctorPage(
          mobile: mobile,
          name: name,
          age: age,
          email: email,
          address: address,
          gender: gender,
          imageBase64: imageBase64,
          disease: disease,
          type: type,
          specialization: specialization,
          clinicName: clinicName,

          // allDoctorsType: null,   // only used for admin
            // 👇 This is the part you wanted
        allDoctorsType: type.toLowerCase() == "admin" ? "aallDoct" : null,
        ),
      ),
    );
  }



  void _onMyProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyProfileScreen()),
    ).then((_) async {
      await _loadLocalPrefs();   // reload values
      if (mounted) setState(() {}); // refresh UI
    });
  }
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }
}
