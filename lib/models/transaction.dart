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

  Transaction({
    this.transactionId,
    this.buyerId,
    this.sellerId,
    this.reqbidId,
    this.productBidId,
    this.isProdBidId,
    this.endDate,
    this.totalAmount,
  });
}
