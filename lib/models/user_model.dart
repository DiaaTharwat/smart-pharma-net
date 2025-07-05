// ignore_for_file: override_on_non_overriding_member, undefined_shown_name, unused_import

import 'package:smart_pharma_net/models/base_model.dart' show BaseModel;

class UserModel extends BaseModel {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? nationalId;
  final String? gender;
  final String? username;

  UserModel({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.nationalId,
    this.gender,
    this.username,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      phone: json['phone'],
      nationalId: json['nationalID'],
      gender: json['gender'],
      username: json['username'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'nationalID': nationalId,
      'gender': gender,
      'username': username,
    };
  }
}

class BaseModel {
}