// ignore_for_file: camel_case_types

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mcp_project/model/donor.dart';
import 'package:mcp_project/screens/campaign_details.dart';
import 'package:mcp_project/screens/blood_requests.dart';
import 'package:mcp_project/screens/drawer.dart';
import 'package:mcp_project/screens/edit_profile.dart';
import 'package:mcp_project/screens/loading.dart';
import 'package:mcp_project/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class Selection extends StatefulWidget {
  @override
  State<Selection> createState() => _SelectionState();
}

class _SelectionState extends State<Selection> {
  final GoogleSignIn googleSignIn = GoogleSignIn(); // Google Sign-In instance
  final CollectionReference donorRef =
      FirebaseFirestore.instance.collection('donor'); // Firestore reference
  Donor? currentUser;
  bool isAuth = false;
  TextEditingController userBloodQuery = TextEditingController();
  TextEditingController userLocationQuery = TextEditingController();
  List<DocumentSnapshot> donors = [];
  bool wannaSearch = false;

  @override
  void initState() {
    super.initState();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });

    // Re-authenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });

    showDonors();
  }

  void loginWithGoogle() {
    googleSignIn.signIn();
  }

  void logout() {
    googleSignIn.signOut();
  }

  Future<void> getUserLocation() async {
    try {
      // Check and request location permissions
      var status = await Permission.location.status;
      if (!status.isGranted) {
        await Permission.location.request();
      }

      // If permission is granted, get the location
      if (await Permission.location.isGranted) {
        LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 10,
        );

        Position position = await Geolocator.getCurrentPosition(
            locationSettings: locationSettings);
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks[0];
          String completeAddress = placemark.locality ?? 'Unknown location';
          userLocationQuery.text = completeAddress;
        }
      } else {
        print("Location permission denied.");
      }
    } catch (e) {
      print("Error occurred: $e");
    }
  }

  void handleSignIn(GoogleSignInAccount? account) {
    if (account != null) {
      createUserInFireStore();
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
      donors = snapshot.docs;
    });
  }

  Future<void> createUserInFireStore() async {
    final GoogleSignInAccount? user = googleSignIn.currentUser;

    if (user != null) {
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
          'gender': "",
          'dateOfBirth': "",
        });

        // Retrieve the newly created document
        doc = await donorRef.doc(user.id).get();
      }

      currentUser = Donor.fromDocument(
          doc); // Ensure this method is defined in your Donor model
    }
  }

  StreamBuilder showSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: donorRef
          .where('locationSearch', arrayContains: userLocationQuery.text)
          .where('bloodGroup', isEqualTo: userBloodQuery.text)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(); // Use a loading indicator while fetching data
        }

        List<ShowDonors> allDonors = [];
        snapshot.data!.docs.forEach((doc) {
          allDonors.add(ShowDonors.fromDocument(
              doc)); // Ensure ShowDonors.fromDocument is defined
        });

        return Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: <Widget>[
              allDonors.isEmpty
                  ? Text("No Donors Found")
                  : Column(
                      children: allDonors,
                    ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    userBloodQuery.dispose();
    userLocationQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            "assets/img/1.png",
            height: 200,
            fit: BoxFit.fill,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/img/drop2.png",
                  height: 120,
                ),
                Text("Save Lives",
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 35.0,
                        fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 100,
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 60,
                          width: 140,
                          decoration: BoxDecoration(
                            // color: Colors.white,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(40),
                            // boxShadow: [
                            //   BoxShadow(
                            //       color: Colors.red.shade100,
                            //       spreadRadius: 0.4,
                            //       blurRadius: 5)]
                          ),
                          child: InkWell(
                              splashColor: Colors.red,
                              borderRadius: BorderRadius.circular(40),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => isAuth
                                            ? RequestBlood(currentUser!)
                                            : LoginScreen()));
                              },
                              child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                      child: Text(
                                    "Request For Blood",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.red,
                                    ),
                                  )))),
                        ),
                        SizedBox(width: 25),
                        Container(
                          height: 60,
                          width: 140,
                          decoration: BoxDecoration(
                            // color: Colors.white,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(40),
                            // boxShadow: [
                            //   BoxShadow(
                            //       color: Colors.red.shade100,
                            //       spreadRadius: 0.4,
                            //       blurRadius: 5)]
                          ),
                          child: InkWell(
                              splashColor: Colors.red,
                              borderRadius: BorderRadius.circular(40),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => isAuth
                                            ? EditProfile(
                                                currentUser!, authScreen())
                                            : LoginScreen()));
                              },
                              child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                      child: Text(
                                    "Donate Blood",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.red,
                                    ),
                                  )))),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      height: 60,
                      width: 140,
                      decoration: BoxDecoration(
                        // color: Colors.white,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(40),
                        // boxShadow: [
                        //   BoxShadow(
                        //       color: Colors.red.shade100,
                        //       spreadRadius: 0.4,
                        //       blurRadius: 5)]
                      ),
                      child: InkWell(
                          splashColor: Colors.red,
                          borderRadius: BorderRadius.circular(40),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        isAuth ? sc() : LoginScreen()));
                          },
                          child: Container(
                              color: Colors.transparent,
                              child: Center(
                                  child: Text(
                                "Find Donors",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.red,
                                ),
                              )))),
                    ),
                  ],
                )
              ],
            ),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                "assets/img/2.png",
                height: 150,
                fit: BoxFit.fill,
              )),
        ],
      ),
    );
  }

  Scaffold unAuthScreen() {
    return Scaffold(
        body: !isAuth
            ? Container(
                width: MediaQuery.of(context).size.width,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 35.0,
                    right: 20.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                          padding: EdgeInsets.only(top: 10.0, bottom: 60.0),
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 50.0),
                          )),
                      Container(
                          padding: EdgeInsets.only(top: 20.0, bottom: 40.0),
                          child: Image.asset(
                            'assets/img/logo.png',
                            height: MediaQuery.of(context).size.height * 0.2,
                          )),
                      Container(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            children: <Widget>[
                              Container(
                                color: Colors.white,
                                height: 30.0,
                                child: Image.asset(
                                  'assets/img/g_logo.png',
                                ),
                              ),
                              Container(
                                height: 50.0,
                                width: MediaQuery.of(context).size.width * .7,
                                child: MaterialButton(
                                  onPressed: loginWithGoogle,
                                  color: Colors.white,
                                  child: Text(
                                    "Continue with Google",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontFamily: "Gotham",
                                        fontSize: 20.0),
                                  ),
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                ),
              )
            : Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.red,
                ),
              ));
  }

  Scaffold authScreen() {
    return Scaffold(
        drawer: MainDrawer(googleSignIn, currentUser!),
        backgroundColor: Colors.red,
        body: NestedScrollView(
          // scrollDirection: Axis.vertical,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              forceElevated: innerBoxIsScrolled,
              pinned: true,
              // floating: false,
              // pinned: true,
              excludeHeaderSemantics: true,
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  "Save Lives",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),

              // leading: InkWell(onTap: (),
              //     child: Icon(Icons.menu,size: 30,color: Colors.white,)),
              // // actions: [Ico],
              expandedHeight: 100.0,
            ),
          ],
          body: Container(
            height: 1500,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40))),
            child: ListView(
              physics: NeverScrollableScrollPhysics(),
              children: <Widget>[
                Stack(children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Center(
                                child: Text(
                              "Find a Donor",
                              style: TextStyle(
                                  fontSize: 30.0,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w400),
                            )),
                          ),
                          Container(
                              padding: EdgeInsets.only(
                                  left: 30.0,
                                  right: 30.0,
                                  top: 10.0,
                                  bottom: 10.0),
                              child: TextField(
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    FocusScope.of(context).nextFocus(),
                                controller: userLocationQuery,
                                decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                      icon: Icon(Icons.my_location),
                                      onPressed: getUserLocation),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  hintText: "Location",
                                ),
                              )),
                          SizedBox(
                            height: 10.0,
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                left: 30.0,
                                right: 30.0,
                                top: 10.0,
                                bottom: 10.0),
                            child: DropdownButtonFormField(
                              decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          wannaSearch = false;
                                          userLocationQuery.clear();
                                          userBloodQuery.clear();
                                          FocusScope.of(context).unfocus();
                                        });
                                      }),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  )),
                              hint: Text("Select Blood Group"),
                              items: [
                                DropdownMenuItem(
                                  value: "A+",
                                  child: Text("A+"),
                                ),
                                DropdownMenuItem(
                                  value: "A-",
                                  child: Text("A-"),
                                ),
                                DropdownMenuItem(
                                  value: "B+",
                                  child: Text("B+"),
                                ),
                                DropdownMenuItem(
                                  value: "B-",
                                  child: Text("B-"),
                                ),
                                DropdownMenuItem(
                                  value: "AB+",
                                  child: Text("AB+"),
                                ),
                                DropdownMenuItem(
                                  value: "AB-",
                                  child: Text("AB-"),
                                ),
                                DropdownMenuItem(
                                  value: "O+",
                                  child: Text("O+"),
                                ),
                                DropdownMenuItem(
                                  value: "O-",
                                  child: Text("O-"),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  userBloodQuery.text = val!;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 20.0, bottom: 10.0),
                              child: MaterialButton(
                                onPressed: () {
                                  setState(() {
                                    wannaSearch = true;
                                    FocusScope.of(context).unfocus();
                                  });
                                },
                                color: Colors.red,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(color: Colors.red)),
                                child: Text(
                                  "Search",
                                  style: TextStyle(
                                      fontFamily: "Gotham",
                                      fontSize: 20.0,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ]),
                SizedBox(height: 20.0),
                Text(
                  "  Recent Donors",
                  style: TextStyle(
                    fontFamily: "Gotham",
                    fontSize: 22.0,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 10.0),
                wannaSearch
                    ? showSearchResults() // Assuming showSearchResults() is defined elsewhere
                    : StreamBuilder<List<ShowDonors>>(
                        stream: donorRef
                            .where("bloodGroup", isGreaterThan: "")
                            .snapshots()
                            .map((snapshot) => snapshot.docs
                                .map((doc) => ShowDonors.fromDocument(doc))
                                .toList()), // Safely map documents
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return circularLoading(); // Loading indicator while waiting for data
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text(
                                    "Error: ${snapshot.error}")); // Handle errors
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                                child: Text(
                                    "No Donors Found")); // Handle empty data
                          }

                          List<ShowDonors> allDonors =
                              snapshot.data!; // Safely access data

                          return Container(
                            child: Column(
                              children: allDonors, // Display all donors
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ));
  }
}

// Define the StatefulWidget
class sc extends StatefulWidget {
  @override
  State<sc> createState() => _scState();
}

// Define the State class
class _scState extends State<sc> {
  final GlobalKey<FormFieldState> _key = GlobalKey<FormFieldState>();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final donorRef = FirebaseFirestore.instance.collection('donor');
  late Donor currentUser;
  bool isAuth = false;
  bool wannaSearch = false;

  TextEditingController userBloodQuery = TextEditingController();
  TextEditingController userLocationQuery = TextEditingController();

  List<dynamic> donors = [];
  List<dynamic> campaigns = [];

  @override
  void initState() {
    super.initState();
    _setupGoogleSignIn();
    showCampaigns();
    showDonors();
  }

  void _setupGoogleSignIn() {
    googleSignIn.onCurrentUserChanged.listen((account) async {
      await handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });

    googleSignIn.signInSilently(suppressErrors: false).then((account) async {
      await handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  @override
  void dispose() {
    userBloodQuery.dispose();
    userLocationQuery.dispose();
    super.dispose();
  }

  Future<void> showCampaigns() async {
    try {
      final QuerySnapshot snapshot = await donorRef.get();
      setState(() {
        campaigns = snapshot.docs; // Use docs for Firestore
      });
    } catch (e) {
      print("Error fetching campaigns: $e");
    }
  }

  Future<void> showDonors() async {
    try {
      final QuerySnapshot snapshot =
          await donorRef.where("bloodGroup", isGreaterThan: "").get();
      setState(() {
        donors = snapshot.docs
            .map((doc) => Donor.fromDocument(doc))
            .toList(); // Convert documents to Donor objects
      });
    } catch (e) {
      print("Error fetching donors: $e");
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      await googleSignIn.signIn();
    } catch (e) {
      print("Error signing in with Google: $e");
    }
  }

  void logout() async {
    await googleSignIn.signOut();
    setState(() {
      isAuth = false; // Update authentication state
    });
  }

  Future<void> handleSignIn(GoogleSignInAccount? account) async {
    if (account != null) {
      setState(() {
        isAuth = true; // Update authentication state
      });

      DocumentSnapshot doc = await donorRef.doc(account.id).get();
      if (doc.exists) {
        currentUser = Donor.fromDocument(doc);
      } else {
        await donorRef.doc(account.id).set({
          "id": account.id,
          "displayName": account.displayName,
          "photoUrl": account.photoUrl,
          // Add any additional necessary fields here
        });
        currentUser = Donor.fromDocument(await donorRef.doc(account.id).get());
      }
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Donor Campaigns"),
        actions: [
          IconButton(
            icon: Icon(isAuth ? Icons.logout : Icons.login),
            onPressed: isAuth ? logout : loginWithGoogle,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20.0),
            Text(
              "Recent Donors",
              style: TextStyle(
                fontFamily: "Gotham",
                fontSize: 22.0,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 10.0),
            Expanded(
              child: ListView.builder(
                itemCount: donors.length,
                itemBuilder: (context, index) {
                  // Replace with your donor display logic
                  var donor = donors[index];
                  return ListTile(
                    title: Text(donor.displayName ?? "Unknown"),
                    subtitle: Text(donor.photoUrl ?? "No photo"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Define your Donor class here

final TextEditingController addressController = TextEditingController();

Future<void> getUserLocation() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.best,
  );

  List<Placemark> placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );

  if (placemarks.isNotEmpty) {
    Placemark placemark = placemarks.first;
    String completeAddress = [
      placemark.street,
      placemark.locality,
      placemark.country,
    ].where((element) => element != null && element.isNotEmpty).join(', ');

    addressController.text = completeAddress.trim();
  } else {
    addressController.text = 'Unknown location';
  }
}
final donorRef = FirebaseFirestore.instance
    .collection('donors'); // Ensure this is initialized
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<void> createUserInFireStore(Donor currentUser) async {
  final GoogleSignInAccount? user = googleSignIn.currentUser;

  if (user != null) {
    try {
      DocumentSnapshot doc = await donorRef.doc(user.id).get();

      // Update or create the user document based on whether it exists
      if (!doc.exists) {
        await donorRef.doc(user.id).set({
          "id": user.id,
          "displayName": user.displayName ?? "No Name",
          "photoUrl": user.photoUrl ?? "",
          "location": "",
          "locationSearch": "",
          "phoneNumber": "",
          "bloodGroup": "",
          "gender": "",
          "dateOfBirth": "",
        });
        print("User created: ${user.displayName}");
      } else {
        // Update the user document with any new information if necessary
        await donorRef.doc(user.id).update({
          "displayName": user.displayName ?? doc['displayName'],
          "photoUrl": user.photoUrl ?? doc['photoUrl'],
          // Add any additional fields you want to update
        });
        print("User updated: ${user.displayName}");
      }

      // Fetch the user document again
      doc = await donorRef.doc(user.id).get();
      currentUser = Donor.fromDocument(doc);
    } catch (e) {
      print("Error creating or updating user in Firestore: ${e.toString()}");
    }
  } else {
    print("No user is currently signed in.");
  }
}

StreamBuilder<List<ShowDonors>> showSearchResult({
  required TextEditingController userLocationQuery,
  required TextEditingController userBloodQuery,
}) {
  return StreamBuilder<List<ShowDonors>>(
    stream: donorRef
        .orderBy('location')
        .where('locationSearch',
            arrayContains: userLocationQuery.text) // Filter by location
        .where('bloodGroup',
            isEqualTo: userBloodQuery.text) // Filter by blood group
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShowDonors.fromDocument(doc))
            .toList()), // Convert docs to ShowDonors objects
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return circularLoading(); // Loading indicator
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(
          child: Text("No Donors Found", style: TextStyle(fontSize: 18.0)),
        );
      }

      final donors = snapshot.data!; // List of donors from the stream

      return ListView.builder(
        itemCount: donors.length,
        itemBuilder: (context, index) {
          final donor = donors[index];
          return ListTile(
            title: Text(donor.displayName ?? 'Unknown Donor'),
            subtitle: Text(donor.bloodGroup ?? 'Unknown Blood Group'),
            leading: CircleAvatar(
              backgroundImage:
                  donor.photoUrl != null ? NetworkImage(donor.photoUrl!) : null,
              backgroundColor: Colors.redAccent,
              child: donor.photoUrl == null
                  ? Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          );
        },
      );
    },
  );
}

Scaffold unAuthScreen({
  required bool isAuth,
  required VoidCallback loginWithGoogle,
  required BuildContext context,
}) {
  return Scaffold(
    body: !isAuth
        ? Container(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 35.0,
                right: 20.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(top: 10.0, bottom: 60.0),
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 50.0,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 20.0, bottom: 40.0),
                    child: Image.asset(
                      'assets/img/logo.png',
                      height: MediaQuery.of(context).size.height * 0.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      children: <Widget>[
                        Container(
                          color: Colors.white,
                          height: 30.0,
                          child: Image.asset(
                            'assets/img/g_logo.png',
                          ),
                        ),
                        Container(
                          height: 50.0,
                          width: MediaQuery.of(context).size.width * .7,
                          child: MaterialButton(
                            onPressed: loginWithGoogle,
                            color: Colors.white,
                            child: Text(
                              "Continue with Google",
                              style: TextStyle(
                                color: Colors.red,
                                fontFamily: "Gotham",
                                fontSize: 20.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.red,
            ),
          ),
  );
}

final CollectionReference campRef =
    FirebaseFirestore.instance.collection('campaigns');

Scaffold authScreen({
  required dynamic currentUser,
  required GoogleSignIn googleSignIn,
}) {
  return Scaffold(
    backgroundColor: Colors.red,
    drawer: MainDrawer(googleSignIn, currentUser!), // Pass currentUser
    body: NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          forceElevated: innerBoxIsScrolled,
          pinned: true,
          centerTitle: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Save Lives",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    splashColor: Colors.white,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfile(
                            currentUser!,
                            authScreen(
                              currentUser: currentUser,
                              googleSignIn: googleSignIn,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Text("Be a donor", style: TextStyle(fontSize: 7)),
                        Icon(Icons.add_circle, size: 25, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          expandedHeight: 130.0,
        ),
      ],
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: ListView(
          children: <Widget>[
            Center(
              child: Text(
                "Campaigns",
                style: TextStyle(
                  fontFamily: "Gotham",
                  fontSize: 22.0,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 10.0),
            StreamBuilder<QuerySnapshot>(
              stream: campRef.snapshots(), // Ensure  is properly defined
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Container(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Some error occurred"));
                }
                final documents = snapshot.data?.docs ?? [];

                return CarouselSlider.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index, _) {
                    final document = documents[index];

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CampaignDetails(
                                    name: document['name'],
                                    bloodGroup: document['bloodGroup'],
                                    phoneNumber: document['phoneNumber'],
                                    image: document['image'],
                                    location: document['location'],
                                    bloodNeededDate:
                                        document['bloodNeededDate'],
                                  ),
                                ),
                              );
                            },
                            child: document['image'] == null
                                ? Center(child: Text("Campaign Not Available"))
                                : Image.network(
                                    document['image'],
                                    fit: BoxFit.fill,
                                    width: double.infinity,
                                    height: 200,
                                    loadingBuilder: (BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 250,
                    enlargeCenterPage: true,
                    autoPlay: true,
                  ),
                );
              },
            ),
            Stack(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Center(
                            child: Text(
                              "Find a Donor",
                              style: TextStyle(
                                fontSize: 30.0,
                                color: Colors.red,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> pickDate(
    BuildContext context, Function(String) onDateSelected) async {
  DateTime? date = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(DateTime.now().year + 1),
  );

  if (date != null) {
    String formattedDate = "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";

    onDateSelected(formattedDate);
  }
}

class BloodRequestScreen extends StatefulWidget {
  final dynamic currentUser;
  final dynamic googleSignIn;

  const BloodRequestScreen(
      {Key? key, required this.currentUser, required this.googleSignIn})
      : super(key: key);

  @override
  _BloodRequestScreenState createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen> {
  File? _imageFile;
  final picker = ImagePicker();
  String nameofpic = "";
  bool isRequesting = false;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final bloodRequestRef = FirebaseFirestore.instance.collection('campaign');

  final TextEditingController addressController = TextEditingController();
  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController bloodNeedDateController = TextEditingController();
  final TextEditingController imagecontroller = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> requestBlood() async {
    String requestId = Uuid().v4();
    DocumentReference docRef = bloodRequestRef.doc(requestId);
    DocumentSnapshot doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        "id": requestId,
        "name": namecontroller.text,
        "image": nameofpic.toString(),
        "location": addressController.text,
        "bloodGroup": bloodGroupController.text,
        "phoneNumber": phoneNumberController.text,
        "bloodNeededDate": bloodNeedDateController.text,
      });
    }
  }

  Future<void> uploadImage() async {
    await Permission.photos.request();
    var permissionStatus = await Permission.photos.status;

    if (permissionStatus.isGranted) {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        var file = File(image.path);
        String uniqueFileName =
            DateTime.now().millisecondsSinceEpoch.toString();

        try {
          var snapshot = await _storage
              .ref()
              .child('images/$uniqueFileName')
              .putFile(file);
          var downloadUrl = await snapshot.ref.getDownloadURL();
          if (mounted) {
            setState(() {
              nameofpic = downloadUrl;
            });
          }
        } catch (e) {
          print('Error uploading image: $e');
        }
      }
    }
  }

  Future<void> handleBloodRequest() async {
    if (mounted) {
      setState(() {
        isRequesting = true;
      });
    }

    await requestBlood();

    if (mounted) {
      setState(() {
        isRequesting = false;
      });

      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Successful Creation"),
          content: MaterialButton(
            child: const Text("OK"),
            onPressed: () {
              namecontroller.clear();
              addressController.clear();
              bloodNeedDateController.clear();
              bloodGroupController.clear();
              phoneNumberController.clear();
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    namecontroller.dispose();
    addressController.dispose();
    bloodNeedDateController.dispose();
    bloodGroupController.dispose();
    phoneNumberController.dispose();
    imagecontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return authScreen(
      currentUser: widget.currentUser,
      googleSignIn: widget.googleSignIn,
    );
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
      displayName: doc['displayName'],
      location: doc['location'],
      bloodGroup: doc['bloodGroup'],
      photoUrl: doc['photoUrl'],
      phoneNumber: doc['phoneNumber'],
      gender: doc['gender'],
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url); // Create a Uri object
    if (await canLaunchUrl(uri)) {
      // Check if the URL can be launched
      await launchUrl(uri); // Launch the URL
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
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage("$photoUrl"),
                  ),
                ),
              ),
              Expanded(
                  child: Container(
                decoration: BoxDecoration(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 24,
                      width: double.infinity,
                      child: Text(
                        "$displayName",
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ),
                    Container(
                      height: 24,
                      width: double.infinity,
                      child: Text("$gender"),
                    ),
                    Container(
                      height: 24,
                      width: double.infinity,
                      child: Text("$location"),
                    ),
                    Expanded(
                        child: MaterialButton(
                            elevation: 2,
                            minWidth: 50,
                            color: Colors.red,
                            onPressed: () {
                              _launchURL("tel:$phoneNumber");
                            },
                            child: Text(
                              "Call Now",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ))),
                  ],
                ),
              )),
              Container(
                height: 70,
                width: 70,
                color: Colors.white,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/img/drop2.png"),
                              fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: Text(
                            "$bloodGroup",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ShowCamp extends StatelessWidget {
  final String displayName;
  final String photoUrl;
  final String location;
  final String bloodGroup;
  final String date;
  final String phoneNumber;

  ShowCamp({
    required this.displayName,
    required this.photoUrl,
    required this.location,
    required this.bloodGroup,
    required this.date,
    required this.phoneNumber,
  });

  factory ShowCamp.fromDocument(DocumentSnapshot doc) {
    return ShowCamp(
      displayName: doc['name'],
      location: doc['location'],
      bloodGroup: doc['bloodGroup'],
      photoUrl: doc['image'],
      phoneNumber: doc['phoneNumber'],
      date: doc['bloodNeededDate'],
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url); // Create a Uri object
    if (await canLaunchUrl(uri)) {
      // Use canLaunchUrl
      await launchUrl(uri); // Use launchUrl
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
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage("$photoUrl"),
                  ),
                ),
              ),
              Expanded(
                  child: Container(
                decoration: BoxDecoration(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 24,
                      width: double.infinity,
                      child: Text(
                        "$displayName",
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ),
                    Container(
                      height: 24,
                      width: double.infinity,
                      child: Text("$date"),
                    ),
                    Container(
                      height: 24,
                      width: double.infinity,
                      child: Text("$location"),
                    ),
                    Expanded(
                        child: MaterialButton(
                            elevation: 2,
                            minWidth: 50,
                            color: Colors.red,
                            onPressed: () {
                              _launchURL("tel:$phoneNumber");
                            },
                            child: Text(
                              "Call Now",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ))),
                  ],
                ),
              )),
              Container(
                height: 70,
                width: 70,
                color: Colors.white,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/img/drop2.png"),
                              fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: Text(
                            "$bloodGroup",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
