import 'dart:convert';
import 'dart:io';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/widgets/drop_down_widget.dart';
import 'package:baazar/widgets/hand_shake_icon_icons.dart';
import 'package:baazar/widgets/m_y_baazar_icons.dart';

import 'package:geocoder/geocoder.dart';
//import 'package:google_maps_webservice/places.dart';
//import 'package:baazar/models/user_location.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:baazar/widgets/button_widget.dart';
import 'package:baazar/widgets/dialog_widget.dart';
//import 'package:baazar/widgets/drop_down_widget.dart';
import 'package:baazar/widgets/text_input_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
//import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_maps_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProdReqUpdate extends StatefulWidget {
  static final String routeName = "/update";

  @override
  _ProdReqUpdateState createState() => _ProdReqUpdateState();
}

class _ProdReqUpdateState extends State<ProdReqUpdate> {
  bool isSeller;
  List<Category> catgeoryList;
  dynamic _selectedObject;
  var finalLocation;
  var _selectedAddress;
  final _breedController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _remainingQtyController = TextEditingController();
  DateTime _selectedDate;
  File qualityCertificate;
  Category selectedCategory;
  String dropDownValue;
  int _userId;
  LatLng _selectedCoord;
  File _image;
  final picker = ImagePicker();
  String errorBreed;
  String errorPrice;
  String errorQuantity;
  String errorCategory;
  String _photoText = "Change Photo";
  bool _isPhotoError = false;
  String errorRemainingQuantity;
  bool _initialLoad = true;

  static const String kGoogleApiKey = "AIzaSyBuZTVFf0pDt_MgQedl5aNsOxu286k7Wmw";
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _selectedObject.image = _image.path.split('/').last;
        _photoText = "Change Photo";
        _isPhotoError = false;
      });
    }
  }

  void _categoryHandler(String value) {
    print(value);
    setState(() {
      _selectedObject.category.name = value;
      _selectedObject.category =
          catgeoryList.firstWhere((category) => category.name == value);
      selectedCategory = _selectedObject.category;
    });
  }

  _getCategoryList() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String jsonString = sharedPreferences
        .getString(CategoryScreen.CATEGORY_LIST_SHARED_PREFERENCE);
    return jsonString;
  }

  _getUserId() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    int _userId = sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE);
    return _userId;
  }

  _getUserType() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool isSeller =
        sharedPreferences.getBool(CheckUserScreen.USER_TYPE_SHARED_PREFERENCE);
    return isSeller;
  }

  Future<List<Category>> _loadCatAndUserType() async {
    if (_initialLoad) {
      //print("Cateory List Start");
      String jsonString = await _getCategoryList();
      // print(jsonString);
      this.isSeller = await _getUserType();
      // if (isSeller && _selectedObject.image != null) {
      //   _isPhotoError = false;
      // }
      //print(this.isSeller);
      this._userId = await _getUserId();
      var jsonData = json.decode(jsonString);
      List<Category> categoryList = [];
      for (var category in jsonData) {
        categoryList.add(
          Category(
            id: category["cat_id"],
            name: category["category_name"],
            imgPath: category["category_image"],
          ),
        );
      }
      //print("Cateory List End");
      this.catgeoryList = categoryList;
      _initialLoad = false;
    }

    return this.catgeoryList;
  }

  void pickFile() async {
    File file = await FilePicker.getFile();
    if (file != null) {
      setState(() {
        this.qualityCertificate = file;
        _selectedObject.qualityCertificate =
            this.qualityCertificate.path.split('/').last;
      });
    }
  }

  Future<String> uploadData() async {
    print(qualityCertificate);
    print(_image);
    FormData formData = FormData.fromMap(
      {
        "qualityCertificate": isSeller && qualityCertificate != null
            ? await MultipartFile.fromFile(
                this.qualityCertificate.path,
                filename: _selectedObject.qualityCertificate,
              )
            : null,
        "productImage": isSeller && _image != null
            ? await MultipartFile.fromFile(
                _image.path,
                filename: _selectedObject.image,
              )
            : null,
        "id": _selectedObject.id,
        "isSeller": isSeller,
        "price": num.parse(_priceController.text).toStringAsFixed(2),
        "breed": _breedController.text,
        "quantity": _quantityController.text,
        "remainingQty": _remainingQtyController.text,
        // "address": _selectedObject.address,
        // "state": _selectedObject.state,
        // "pincode": _selectedObject.postalCode,
        // "city": _selectedObject.city,
        // "latitude": _selectedObject.latitude,
        // "longitude": _selectedObject.longitude,
        "user_id": _userId,
        "category": _selectedObject.category.id,
      },
    );
    try {
      var dio = Dio();
      Response response =
          await dio.post(Utils.URL + "/updateProdReq.php", data: formData);
      print(response.data);
      return response.data as String;
    } on Exception catch (e) {
      print(e);
      print("exeception");
    }
  }

  void _submitData() async {
    if (_validator() && _userId != null) {
      final ProgressDialog pr = ProgressDialog(context,
          type: ProgressDialogType.Normal, isDismissible: true, showLogs: true);
      pr.style(
        message:
            AppLocalizations.of(context).translate('Updating Please Wait...'),
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
      );
      await pr.show();
      String jsonResponse = await uploadData();
      var data = json.decode(jsonResponse);
      pr.hide();

      if (data['response_code'] == 404) {
        String text = AppLocalizations.of(context).translate("Sorry!!!");
        String dialogMesage =
            AppLocalizations.of(context).translate("Product update unsuccess");
        String buttonMessage = AppLocalizations.of(context).translate("Ok!!");
        await CustomDialog.openDialog(
            context: context,
            title: text,
            message: dialogMesage,
            mainIcon: Icons.check,
            subIcon: Icons.error);
        Navigator.pop(context);
      } else if (data['response_code'] == 100) {
        String text = AppLocalizations.of(context).translate("Congratulations");
        String dialogMesage =
            AppLocalizations.of(context).translate("Product update");
        String buttonMessage = AppLocalizations.of(context).translate("Done");
        Navigator.pop(context);
        await CustomDialog.openDialog(
            context: context,
            title: text,
            message: dialogMesage,
            mainIcon: Icons.check,
            subIcon: HandShakeIcon.handshake);
      }
    }
  }

  List<String> getCategoryNameAsList(List<Category> catgeoryList) {
    List<String> catList = [];
    //print(this.catgeoryList);

    for (Category category in this.catgeoryList) {
      catList.add(AppLocalizations.of(context).translate(category.name));
    }
    return catList;
  }

  bool _validator() {
    if (_validateCategory() &&
        _validatorBreed() &&
        _validatorPhoto() &&
        _validatorQuantity() &&
        _validatorRemainingQuantity() &&
        _validatorPrice()) {
      print("success");
      return true;
    } else {
      print("failed");
      return false;
    }
  }

  bool _validateCategory() {
    if (selectedCategory == null) {
      errorCategory =
          AppLocalizations.of(context).translate("Category not selected");
      return false;
    }
    errorCategory = null;
    print("category success");
    return true;
  }

  bool _validatorBreed() {
    if (_breedController.text.isEmpty) {
      errorBreed =
          AppLocalizations.of(context).translate("Breed must be added");
      return false;
    }
    if (_breedController.text.trim().length > 10) {
      errorBreed = AppLocalizations.of(context)
          .translate("Breed must be have less than 10 characters ");
      return false;
    }
    print("breed success");
    errorBreed = null;
    return true;
  }

  bool _validatorQuantity() {
    if (_quantityController.text.isEmpty) {
      errorQuantity =
          AppLocalizations.of(context).translate("Quantity must be added");
      return false;
    }

    if (_isNumeric(_quantityController.text.trim()) == false) {
      errorQuantity =
          AppLocalizations.of(context).translate("Quantity must be a number");
      return false;
    }

    if (int.tryParse(_quantityController.text.trim()) == null) {
      errorQuantity =
          AppLocalizations.of(context).translate("Remove decimal point");
      return false;
    }
    if (int.parse(_quantityController.text.trim()) <= 0) {
      errorQuantity = AppLocalizations.of(context).translate("Greater than 0");
      return false;
    }
    print("quantity success");
    errorQuantity = null;
    return true;
  }

  bool _validatorRemainingQuantity() {
    if (_remainingQtyController.text.isEmpty) {
      errorRemainingQuantity = AppLocalizations.of(context)
          .translate("Remaining Quantity must be added");
      return false;
    }

    if (_isNumeric(_remainingQtyController.text.trim()) == false) {
      errorRemainingQuantity = AppLocalizations.of(context)
          .translate("Remaining Quantity must be a number");
      return false;
    }

    if (int.tryParse(_remainingQtyController.text.trim()) == null) {
      errorRemainingQuantity =
          AppLocalizations.of(context).translate("Remove decimal point");
      return false;
    }
    if (int.parse(_remainingQtyController.text.trim()) <= 0) {
      errorRemainingQuantity =
          AppLocalizations.of(context).translate("Greater than 0");
      return false;
    }
    if (int.parse(_remainingQtyController.text.trim()) >
        int.tryParse(_quantityController.text.trim())) {
      errorRemainingQuantity = AppLocalizations.of(context)
          .translate("Shoule be less than total quantity");
      return false;
    }
    print("quantity success");
    errorRemainingQuantity = null;
    return true;
  }

  bool _validatorPrice() {
    if (_priceController.text.isEmpty) {
      errorPrice =
          AppLocalizations.of(context).translate("Price must be added");
      return false;
    }
    if (_isNumeric(_priceController.text.trim()) == false) {
      errorPrice =
          AppLocalizations.of(context).translate("Price must be a number");
      return false;
    }
    // if (int.tryParse(_priceController.text.trim()) == null) {
    //   errorPrice = "Remove decimal point";
    //   return false;
    // }
    if (double.parse(_priceController.text.trim()) <= 0) {
      errorPrice = AppLocalizations.of(context).translate("Greater than 0");
      return false;
    }
    print("price success");
    errorPrice = null;
    return true;
  }

  bool _validatorPhoto() {
    if (isSeller == false) {
      _photoText = AppLocalizations.of(context).translate("Change Photo");
      _isPhotoError = false;
      return true;
    }
    if (_image == null && _selectedObject.image == null) {
      _photoText = AppLocalizations.of(context).translate("Photo not added");
      _isPhotoError = true;
      return false;
    }
    _isPhotoError = false;
    _photoText = AppLocalizations.of(context).translate("Change Photo");
    return true;
  }

  bool _isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      var routeArgs =
          ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
      this._selectedObject = routeArgs['selected_object'];
      //this.isSeller = await _getUserType();
      print("selected " + _selectedObject.toString());
      _breedController.text = _selectedObject.breed;
      _quantityController.text = _selectedObject.quantity;
      _priceController.text = _selectedObject.price_expected;
      _remainingQtyController.text = _selectedObject.remainingQty;
      selectedCategory = _selectedObject.category;
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    //print("build");
    final data = MediaQuery.of(context);
    var appBar = AppBar(
      title: Text(AppLocalizations.of(context).translate('Update Product'),
          style: Theme.of(context).textTheme.headline1.apply(
                color: Colors.white,
              )),
      iconTheme: IconThemeData(color: Colors.white),
    );
    var height = (MediaQuery.of(context).size.height -
        appBar.preferredSize.height -
        MediaQuery.of(context).padding.top);
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: appBar,
      body: FutureBuilder(
        future: _loadCatAndUserType(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            if (snapshot.data == null) {
              return Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          }
          this.catgeoryList = snapshot.data;
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: SingleChildScrollView(
              child: Container(
                child: Column(
                  children: <Widget>[
                    CategoryDropDown(
                      dropdownValue: _selectedObject.category.name,
                      hintText: AppLocalizations.of(context)
                          .translate("Drop Down Hint"),
                      titleText:
                          AppLocalizations.of(context).translate("Category"),
                      dropDownItems: getCategoryNameAsList(snapshot.data),
                      categoryHandler: _categoryHandler,
                      errorText: errorCategory,
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextInputCard(
                            icon: Icons.fiber_pin,
                            titype: TextInputType.number,
                            htext: 'Breed',
                            mdata: data,
                            controller: _breedController,
                            width: data.size.width * 0.9,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        if (isSeller)
                          Container(
                            width: width * 0.7,
                            child: ButtonWidget(
                              iconData: Icons.photo,
                              text: _photoText,
                              handlerMethod: getImage,
                              height: 55,
                              width: 150,
                              isError: _isPhotoError,
                            ),
                          ),
                        if (isSeller)
                          CircleAvatar(
                            backgroundImage: _image == null
                                ? NetworkImage(
                                    "${Utils.URL}productImage/${_selectedObject.image}")
                                : FileImage(File(_image.path)),
                            backgroundColor: Colors.white,
                            radius: 40.0,
                          ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: TextInputCard(
                          icon: MYBaazar.balance,
                          titype: TextInputType.number,
                          htext: 'Quantity',
                          mdata: data,
                          controller: _quantityController,
                          width: data.size.width * 0.9,
                          errorText: errorQuantity,
                        )),
                        Expanded(
                            child: TextInputCard(
                          icon: MYBaazar.rupee_indian,
                          titype: TextInputType.number,
                          htext: 'Price',
                          mdata: data,
                          controller: _priceController,
                          width: data.size.width * 0.9,
                          errorText: errorPrice,
                        )),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        TextInputCard(
                          icon: MYBaazar.balance,
                          titype: TextInputType.number,
                          htext: "Remaining Quantity",
                          controller: _remainingQtyController,
                          mdata: data,
                          width: data.size.width * 0.9,
                          errorText: errorRemainingQuantity,
                        ),
                      ],
                    ),
                    if (isSeller)
                      Row(
                        children: <Widget>[
                          Expanded(
                              child: ButtonWidget(
                            iconData: Icons.insert_drive_file,
                            text: 'Add Certificate',
                            handlerMethod: pickFile,
                            height: 55,
                            width: 170,
                            isError: false,
                          )),
                          Expanded(
                            child: _selectedObject.quality_certificate == null
                                ? Text(
                                    "You didn't upload any certifcate",
                                    style: TextStyle(color: Colors.red),
                                  )
                                : Text(_selectedObject.qualityCertificate),
                          )
                        ],
                      ),
                    SizedBox(
                      height: 25.0,
                    ),
                    Container(
                      height: 55,
                      width: 170,
                      child: FlatButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            side: BorderSide(
                                color: Theme.of(context).primaryColor)),
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(8.0),
                        onPressed: () {
                          setState(() {
                            FocusScope.of(context).unfocus();
                            _submitData();
                          });
                        },
                        child: Text("Update",
                            style: Theme.of(context).textTheme.bodyText1.apply(
                                  color: Colors.white,
                                )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
