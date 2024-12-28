import 'package:cloud_firestore/cloud_firestore.dart';

class Donor {
  final String id;
  final String? displayName;
  final String? photoUrl;
  final String? location;
  final String? phoneNumber;
  final String? bloodGroup;
  final String? gender;
  final DateTime? dateOfBirth;

  Donor({
    required this.id,
    this.displayName,
    this.photoUrl,
    this.location,
    this.bloodGroup,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
  });

  factory Donor.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Ensure doc data is not null

    return Donor(
      id: data?['id'] ?? '',
      displayName: data?['displayName'],
      photoUrl: data?['photoUrl'],
      location: data?['location'],
      bloodGroup: data?['bloodGroup'],
      phoneNumber: data?['phoneNumber'],
      gender: data?['gender'],
      dateOfBirth: data?['dateOfBirth'] != null ? (data?['dateOfBirth'] as Timestamp).toDate() : null,
    );
  }
}

class Campaign {
  final String id;
  final String displayName;
  final String photoUrl;
  final String location;
  final String phoneNumber;
  final String bloodGroup;
  final String date;

  Campaign({
    required this.id,
    required this.displayName,
    required this.photoUrl,
    required this.location,
    required this.bloodGroup,
    required this.phoneNumber,
    required this.date,
  });

  factory Campaign.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Ensure doc data is not null

    return Campaign(
      id: data?['id'] ?? '',
      displayName: data?['name'] ?? '',
      photoUrl: data?['image'] ?? '',
      location: data?['location'] ?? '',
      bloodGroup: data?['bloodGroup'] ?? '',
      phoneNumber: data?['phoneNumber'] ?? '',
      date: data?['bloodNeededDate'] ?? '',
    );
  }
}
