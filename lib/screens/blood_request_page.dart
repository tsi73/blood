import 'package:mcp_project/model/donor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loading.dart';
class ShowRequest extends StatefulWidget {
  @override
  _ShowRequestState createState() => _ShowRequestState();
}

class _ShowRequestState extends State<ShowRequest> {
  late Donor currentUser; // Ensure you have a Donor class defined
  final bloodRequestRef = FirebaseFirestore.instance.collection('request');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
        ),
        title: Text("Blood Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bloodRequestRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<ShowRequests> allRequests = snapshot.data!.docs.map((doc) {
            return ShowRequests.fromDocument(doc);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: allRequests,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ShowRequests extends StatelessWidget {
  final String? name;
  final String? id;
  final String? location;
  final String? phoneNumber;
  final String? bloodGroup;
  final DateTime? requiredDate;
  final int? bloodAmount;

  // Constructor
  ShowRequests({
    this.name,
    this.id,
    this.location,
    this.phoneNumber,
    this.bloodGroup,
    this.requiredDate,
    this.bloodAmount,
  });

  // Factory constructor to create ShowRequests from Firestore DocumentSnapshot
  factory ShowRequests.fromDocument(DocumentSnapshot doc) {
    return ShowRequests(
      name: doc['name'],
      id: doc['id'],
      location: doc['location'],
      bloodGroup: doc['bloodGroup'],
      phoneNumber: doc['phoneNumber'],
      requiredDate: (doc['bloodNeededDate'] as Timestamp).toDate(), // Convert Timestamp to DateTime
      bloodAmount: doc['bloodAmount'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2.0,
        shadowColor: Colors.black,
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Row(
            children: [
              Container(
                height: 100,
                width: 130,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          location ?? "Location",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/img/drop.png"),
                            fit: BoxFit.fitHeight,
                          ),
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 7, right: 3),
                            child: Text(
                              bloodGroup ?? "Blood Group",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        height: 24,
                        child: Text(
                          name ?? "Name",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        height: 24,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Units: "),
                            Text(bloodAmount?.toString() ?? "0"),
                          ],
                        ),
                      ),
                      Container(
                        height: 24,
                        child: Text(phoneNumber ?? "Phone Number"),
                      ),
                      Expanded(
                        child: Container(
                          child: Text(
                            requiredDate != null
                                ? requiredDate!.toLocal().toString().split(' ')[0]
                                : "Date",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                splashColor: Colors.white,
                onTap: () {
                  Share.share(
                    "Hey, this is $name.\nI'm sharing a $bloodGroup blood request with $bloodAmount unit(s) in $location.\nThe mobile number of the needy person is $phoneNumber.\nMake sure you do not have any type of disease.",
                    subject: 'Nice Service',
                  );
                },
                child: Container(
                  width: 60,
                  color: Colors.red,
                  child: Center(
                    child: Icon(
                      Icons.share_sharp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Blood Requests")),
      body: ListView(
        children: [
          ShowRequests(
            name: "John Doe",
            id: "12345",
            location: "City Center",
            phoneNumber: "555-1234",
            bloodGroup: "O+",
            requiredDate: DateTime.now(),
            bloodAmount: 2,
          ),
          // Add more ShowRequests instances as needed
        ],
      ),
    );
  }
}