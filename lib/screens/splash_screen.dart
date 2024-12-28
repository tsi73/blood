import 'dart:async';
import 'package:mcp_project/model/donor.dart';
import 'package:mcp_project/screens/login_screen.dart';
import 'package:mcp_project/screens/selection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {


  handleSignIn(GoogleSignInAccount account) {
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
Future<void> createUserInFireStore() async {
  final GoogleSignInAccount? user = googleSignIn.currentUser;

  if (user == null) {
    // Start the sign-in process if the user is not signed in
    final GoogleSignInAccount? newUser = await googleSignIn.signIn();
    
    if (newUser == null) {
      // Handle the case when the user cancels the sign-in
      return;
    }
  }

  DocumentSnapshot doc = await donorRef.doc(user!.id).get();

  if (!doc.exists) {
    // Create new user document in users collection
    await donorRef.doc(user.id).set({
      "id": user.id,
      "displayName": user.displayName ?? "", // Use null-coalescing operator
      "photoUrl": user.photoUrl ?? "",       // Use null-coalescing operator
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
//  final StorageReference storageRef = FirebaseStorage.instance.ref();
  final donorRef = FirebaseFirestore.instance.collection('donor');
//
  late Donor currentUser;
  bool wannaSearch = false;

  final GoogleSignIn googleSignIn = GoogleSignIn();
  @override
  void initState() {

    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account)async {
      await handleSignIn(account!);
    }, onError: (err) {
      print('Error signing in: $err');
    });

    // Re-authenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) async{
      await handleSignIn(account!);
    }).catchError((err) {
      print('Error signing in: $err');
    });
    Timer(
        Duration(seconds: 3), () => Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => isAuth?sc():LoginScreen())));


    super.initState();

  }

  bool isAuth=false;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:MainAxisAlignment.center,
          children: [
            Image.asset('assets/img/logo.png', width: 200.0,),
            SizedBox(height: 20,),
            CircularProgressIndicator(backgroundColor: Colors.red,)
          ],
        ),

      ),
    );
  }
}
