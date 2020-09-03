import 'package:baazar/models/prod_bid.dart';
import 'package:baazar/models/requirement_bid.dart';

class Transaction {
  int transactionId;
  int buyerId;
  int sellerId;
  RequirementBid reqbidId;
  ProductBid productBidId;
  bool isProdBidId;
  DateTime startDate;
  DateTime endDate;
  bool isCompleted;
  String razorpayPaymentId;
  String razorpayOrderId;
  String razorpaySignature;
  String deliveryAddress;
  int totalAmount;
  DateTime completionDate;
  DateTime deliveryDate;
  int deliveryStauts;
  int transactionAmount;
  int packagingAmount;
  int deliveryAmount;
  int productCharge;

  static int DELIVERY_PREPARING_TO_DELIVER = 1;
  static int DELIVERY_ON_THE_WAY = 2;
  static int DELIVERD = 3;

  Transaction({
    this.transactionId,
    this.buyerId,
    this.sellerId,
    this.reqbidId,
    this.productBidId,
    this.isProdBidId,
    this.endDate,
    this.totalAmount,
    this.completionDate,
    this.deliveryStauts,
    this.deliveryDate,
    this.deliveryAddress,
    this.productCharge,
    this.deliveryAmount,
    this.packagingAmount,
    this.transactionAmount,
  });
}
