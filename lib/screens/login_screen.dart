import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';
import 'loading.dart';
import 'selection.dart';
import 'edit_profile.dart';
import '../model/donor.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final donorRef = FirebaseFirestore.instance.collection('donor');

  Donor? currentUser;
  bool isAuth = false;

  TextEditingController userBloodQuery = TextEditingController();
  TextEditingController userLocationQuery = TextEditingController();

  List<Donor> donors = [];

  @override
  void initState() {
    super.initState();
    googleSignIn.onCurrentUserChanged.listen((account) async {
      await handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });

    googleSignIn.signInSilently().then((account) async {
      await handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });

    showDonors();
  }

  Future<void> loginWithGoogle() async {
    await googleSignIn.signIn();
  }

  Future<void> logout() async {
    await googleSignIn.signOut();
  }

  Future<void> getUserLocation() async {
  try {
    // Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        print("Location permissions are denied");
        return;
      }
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition();

    // Get placemarks from the coordinates
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);

    // Check if placemarks are available
    if (placemarks.isNotEmpty) {
      userLocationQuery.text = placemarks[0].locality ?? '';
    }
  } catch (e) {
    print("Error getting location: $e");
  }
}

  Future<void> handleSignIn(GoogleSignInAccount? account) async {
    if (account != null) {
      await createUserInFireStore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  Future<void> showDonors() async {
    final QuerySnapshot snapshot = await donorRef.get();
    setState(() {
      donors = snapshot.docs.map((doc) => Donor.fromDocument(doc)).toList();
    });
  }

  Future<void> createUserInFireStore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser!;
    DocumentSnapshot doc = await donorRef.doc(user.id).get();

    if (!doc.exists) {
      await donorRef.doc(user.id).set({
        "id": user.id,
        "displayName": user.displayName,
        "photoUrl": user.photoUrl,
        "location": "",
        "locationSearch": "",
        "phoneNumber": "",
        "bloodGroup": "",
        "gender": "",
        "dateOfBirth": "",
      });
      doc = await donorRef.doc(user.id).get();
    }

    currentUser = Donor.fromDocument(doc);
  }

  StreamBuilder<List<ShowDonors>> showSearchResults() {
    return StreamBuilder<List<ShowDonors>>(
      stream: donorRef
          .where('locationSearch', arrayContains: userLocationQuery.text)
          .where('bloodGroup', isEqualTo: userBloodQuery.text)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ShowDonors.fromDocument(doc))
              .toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return circularLoading();
        }

        List<ShowDonors> allDonors = snapshot.data ?? [];
        return Container(
          height: MediaQuery.of(context).size.height,
          child: allDonors.isEmpty
              ? Center(child: Text("No Donors Found"))
              : ListView(children: allDonors),
        );
      },
    );
  }

  Scaffold unAuthScreen() {
    return Scaffold(
      body: !isAuth
          ? Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 35.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Sign In",
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 50.0),
                    ),
                    SizedBox(height: 60.0),
                    Image.asset('assets/img/logo.png',
                        height: MediaQuery.of(context).size.height * 0.2),
                    SizedBox(height: 40.0),
                    MaterialButton(
                      onPressed: loginWithGoogle,
                      color: Colors.white,
                      child: Row(
                        children: <Widget>[
                          Image.asset('assets/img/g_logo.png', height: 30.0),
                          SizedBox(width: 10),
                          Text("Continue with Google",
                              style:
                                  TextStyle(color: Colors.red, fontSize: 20.0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: CircularProgressIndicator(backgroundColor: Colors.red)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return !isAuth ? unAuthScreen() : Scaffold(body: showSearchResults());
  }
}

class ShowDonors extends StatelessWidget {
  final String displayName;
  final String photoUrl;
  final String location;
  final String bloodGroup;
  final String gender;
  final String phoneNumber;

  ShowDonors({
    required this.displayName,
    required this.photoUrl,
    required this.location,
    required this.bloodGroup,
    required this.gender,
    required this.phoneNumber,
  });

  factory ShowDonors.fromDocument(DocumentSnapshot doc) {
    return ShowDonors(
      displayName: doc['displayName'] ?? '',
      location: doc['location'] ?? '',
      bloodGroup: doc['bloodGroup'] ?? '',
      photoUrl: doc['photoUrl'] ?? '',
      phoneNumber: doc['phoneNumber'] ?? '',
      gender: doc['gender'] ?? '',
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        shadowColor: Colors.black,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage(photoUrl),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: TextStyle(fontSize: 20, color: Colors.black)),
                    Text(gender),
                    Text(location),
                    MaterialButton(
                      color: Colors.red,
                      onPressed: () => _launchURL("tel:$phoneNumber"),
                      child: Text("Call Now",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Container(
                height: 70,
                width: 70,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/img/drop2.png"),
                              fit: BoxFit.fill),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: Text(
                          bloodGroup,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
