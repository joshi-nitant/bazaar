import 'package:baazar/models/category.dart';
import 'package:baazar/models/user.dart';
import 'package:flutter/material.dart';

class Product {
  String id;
  String quantity;
  String price_expected;
  String breed;
  String category_id;
  // String latitude;
  // String longitude;
  // String state;
  // String city;
  String image;
  String remainingQty;
  Category category;
  String qualityCertificate;
  String address;
  //String postalCode;
  String userId;
  User seller;
  int distance;

  Product({
    @required this.id,
    @required this.quantity,
    @required this.price_expected,
    @required this.breed,
    @required this.category_id,
    // @required this.state,
    // @required this.city,
    // @required this.latitude,
    // @required this.longitude,
    @required this.remainingQty,
    @required this.image,
    this.category,
    this.qualityCertificate,
    this.address,
    //this.postalCode,
    this.userId,
    this.seller,
    this.distance,
  });

  String get quality_certificate {
    return this.qualityCertificate;
  }
}
