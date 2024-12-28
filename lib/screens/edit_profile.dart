import 'package:mcp_project/model/donor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mcp_project/screens/thank_you.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EditProfile extends StatefulWidget {
  final Donor currentUser;
  final Scaffold authScreen;

  EditProfile(this.currentUser, this.authScreen);

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  bool isUpdating = false;

  TextEditingController displayNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController bloodGroupController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    displayNameController.text = widget.currentUser.displayName ?? '';
    addressController.text = widget.currentUser.location ?? '';
    bloodGroupController.text = widget.currentUser.bloodGroup ?? '';
    phoneNumberController.text = widget.currentUser.phoneNumber ?? '';
    genderController.text = widget.currentUser.gender ?? '';
    
    // Cast dateOfBirth to String if necessary
    dobController.text = (widget.currentUser.dateOfBirth as String?) ?? '';
  }

  Future<void> getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String completeAddress =
            '${placemark.subLocality}, ${placemark.locality}';
        addressController.text = completeAddress;
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  List<String> setSearchParam(String locationSearch) {
    List<String> locationSearchList = [];
    String temp = "";
    for (int i = 0; i < locationSearch.length; i++) {
      temp += locationSearch[i];
      locationSearchList.add(temp);
    }
    return locationSearchList;
  }

  Future<void> updateDonorDetail() async {
    await FirebaseFirestore.instance.collection('donor').doc(widget.currentUser.id).update({
      "location": addressController.text,
      "locationSearch": setSearchParam(addressController.text),
      "bloodGroup": bloodGroupController.text,
      "phoneNumber": phoneNumberController.text,
      "gender": genderController.text,
      "dateOfBirth": dobController.text,
    });
  }

  void handleDonorUpdate() async {
    setState(() {
      isUpdating = true;
    });

    await updateDonorDetail();

    setState(() {
      isUpdating = false;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ThankYou(widget.authScreen)),
      );
    });
  }

  Future<void> pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 60),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        dobController.text = '${date.year}-${date.month}-${date.day}';
      });
    }
  }

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
        title: Text("Be a Donor"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: isUpdating
              ? Center(child: CircularProgressIndicator())
              : ListView(
                  children: <Widget>[
                    Center(
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(widget.currentUser.photoUrl!),
                        radius: 50.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'What is your sweet name?';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Display Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        controller: displayNameController,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Receiver needs your location!';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          fillColor: Colors.grey,
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
                        onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length != 10) {
                            return 'Common! Number cannot be empty or less than 10 digits';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Phone Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        controller: phoneNumberController,
                        onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: DropdownButtonFormField<String>(
                            validator: (value) => value == null
                                ? 'Please provide Blood Group' : null,
                            onChanged: (val) {
                              bloodGroupController.text = val!;
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
                        ),
                        SizedBox(width: 5.0),
                        Flexible(
                          child: DropdownButtonFormField<String>(
                            validator: (value) => value == null
                                ? 'Please provide Gender' : null,
                            onChanged: (val) {
                              genderController.text = val!;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            hint: Text("Choose your Sex"),
                            items: [
                              DropdownMenuItem(child: Text("Male"), value: "Male"),
                              DropdownMenuItem(child: Text("Female"), value: "Female"),
                              DropdownMenuItem(child: Text("Other"), value: "Other"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tell us your Happiest Day!!';
                          }
                          return null;
                        },
                        onTap: pickDate,
                        decoration: InputDecoration(
                          hintText: "Date of Birth",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          fillColor: Colors.pinkAccent,
                        ),
                        controller: dobController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MaterialButton(
                        child: Text(
                          "I am Ready to Donate",
                          style: TextStyle(color: Colors.white, fontSize: 20.0),
                        ),
                        color: Theme.of(context).primaryColor,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            handleDonorUpdate();
                          }
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}