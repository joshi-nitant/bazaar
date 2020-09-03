import 'package:baazar/models/product.dart';
import 'package:baazar/models/user.dart';
import 'package:flutter/material.dart';

class ProductBid {
  int prodBidId;
  int userId;
  bool isAccepted;
  double deliveryAmount;
  int bidDays;
  int quantity;
  double price;
  Product prodId;
  User buyer;
  int deliveryDays;
  double packagingCharges;

  ProductBid({
    @required this.prodBidId,
    @required this.prodId,
    @required this.quantity,
    @required this.price,
    @required this.isAccepted,
    @required this.userId,
    this.bidDays,
    this.buyer,
    this.deliveryDays,
    this.packagingCharges,
  });
}
