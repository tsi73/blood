import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:mcp_project/model/donor.dart';
import 'package:mcp_project/screens/loading.dart';
import 'package:mcp_project/screens/blood_request_page.dart';
import 'package:geocoding/geocoding.dart';

class RequestBlood extends StatefulWidget {
  final Donor currentUser;

  RequestBlood(this.currentUser);

  @override
  _RequestBloodState createState() => _RequestBloodState();
}

class _RequestBloodState extends State<RequestBlood> {
  final bloodRequestRef = FirebaseFirestore.instance.collection('request');

  bool isRequesting = false;
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers for form fields
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController bloodGroupController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController bloodNeedDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Additional initialization if needed
  }

  Future<void> getUserLocation() async {
  try {
    // Request permission to access location
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

    // Use the geocoding package to get placemarks
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks[0];
      String completeAddress =
          '${placemark.locality}, ${placemark.administrativeArea}';
      addressController.text = completeAddress; // Ensure addressController is defined
    }
  } catch (e) {
    print("Error getting location: $e");
  }
}

  Future<void> requestBlood() async {
    try {
      String docId = Uuid().v4(); // Generate a unique ID for the document
      Map<String, dynamic> bloodRequestData = {
        "location": addressController.text,
        "name": nameController.text,
        "bloodGroup": bloodGroupController.text,
        "phoneNumber": phoneNumberController.text,
        "bloodAmount": int.tryParse(amountController.text) ?? 0,
        "bloodNeededDate": DateTime.parse(bloodNeedDateController.text),
      };

      await bloodRequestRef.doc(docId).set(bloodRequestData);
      print("Blood request submitted successfully!");
    } catch (e) {
      print("Error submitting blood request: $e");
    }
  }

  void handleBloodRequest() async {
    setState(() {
      isRequesting = true;
    });

    await requestBlood();

    setState(() {
      isRequesting = false;
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ShowRequest()));
    });
  }

  Future<void> pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (date != null) {
      setState(() {
        bloodNeedDateController.text = "${date.day.toString().padLeft(2, '0')}-"
            "${date.month.toString().padLeft(2, '0')}-"
            "${date.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request Blood"),
      ),
      body: Builder(builder: (context) {
        return isRequesting
            ? circularLoading()
            : Padding(
                padding: const EdgeInsets.all(10.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: <Widget>[
                      _buildNameField(),
                      _buildLocationField(),
                      _buildBloodAmountField(),
                      _buildPhoneNumberField(),
                      _buildBloodGroupDropdown(),
                      _buildDateField(),
                      _buildDisclaimer(),
                      _buildRequestButton(),
                    ],
                  ),
                ),
              );
      }),
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        validator: (value) {
          if (value!.isEmpty) {
            return 'Donor needs your name';
          }
          return null;
        },
        decoration: InputDecoration(
          fillColor: Colors.grey[200],
          suffixIcon: IconButton(
            icon: Icon(Icons.drive_file_rename_outline, color: Colors.red),
            onPressed: getUserLocation,
          ),
          hintText: "Name",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        controller: nameController,
      ),
    );
  }

  Widget _buildLocationField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        validator: (value) {
          if (value!.isEmpty) {
            return 'Donor needs your Location';
          }
          return null;
        },
        decoration: InputDecoration(
          fillColor: Colors.grey[200],
          suffixIcon: IconButton(
            icon: Icon(Icons.location_on, color: Colors.red),
            onPressed: getUserLocation,
          ),
          hintText: "Your Location",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        controller: addressController,
      ),
    );
  }

  Widget _buildBloodAmountField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value!.isEmpty) {
            return 'Blood Amount is Required';
          }
          return null;
        },
        decoration: InputDecoration(
          fillColor: Colors.grey[200],
          hintText: "Blood Amount (in Units)",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        controller: amountController,
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value!.isEmpty || value.length != 10) {
            return 'Provide a 10 Digit Number';
          }
          return null;
        },
        decoration: InputDecoration(
          fillColor: Colors.grey[200],
          hintText: "Phone Number",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        controller: phoneNumberController,
      ),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: DropdownButtonFormField<String>(
        validator: (value) =>
            value == null ? 'Please provide Blood Group' : null,
        onChanged: (val) {
          setState(() {
            bloodGroupController.text = val!;
          });
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        hint: Text("Blood Group"),
        items: [
          DropdownMenuItem(child: Text("A+"), value: "A+"),
          DropdownMenuItem(child: Text("B+"), value: "B+"),
          DropdownMenuItem(child: Text("O+"), value: "O+"),
          DropdownMenuItem(child: Text("AB+"), value: "AB+"),
          DropdownMenuItem(child: Text("A-"), value: "A-"),
          DropdownMenuItem(child: Text("B-"), value: "B-"),
          DropdownMenuItem(child: Text("O-"), value: "O-"),
          DropdownMenuItem(child: Text("AB-"), value: "AB-"),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        onTap: pickDate,
        readOnly: true,
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please Provide Date';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: "When Do you Need?",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          fillColor: Colors.pinkAccent,
        ),
        controller: bloodNeedDateController,
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        "*Make sure you do not have any type of disease:",
        style: TextStyle(
            fontSize: 15, color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRequestButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MaterialButton(
        child: Text(
          "Request Blood",
          style: TextStyle(color: Colors.white, fontSize: 20.0),
        ),
        color: Theme.of(context).primaryColor,
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            handleBloodRequest();
          }
        },
      ),
    );
  }
}
