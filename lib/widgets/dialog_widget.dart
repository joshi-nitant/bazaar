import 'package:flutter/material.dart';

class CustomDialog extends StatefulWidget {
  String title;
  String message;
  IconData mainIcon;
  IconData subIcon;

  static Future<void> openDialog(
      {BuildContext context,
      String title,
      String message,
      IconData mainIcon,
      IconData subIcon}) async {
    showDialog(
        context: context,
        builder: (context) {
          Future.delayed(Duration(seconds: 2), () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop(true);
          });
          return CustomDialog(
            title: title,
            message: message,
            mainIcon: mainIcon,
            subIcon: subIcon,
          );
        });
  }

  CustomDialog({
    this.title,
    this.message,
    this.mainIcon,
    this.subIcon,
  });
  @override
  _CustomDialogState createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  @override
  Widget build(BuildContext context) {
    Color primarycolor = Theme.of(context).primaryColor;
    final data = MediaQuery.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Container(
            width: data.size.width * 0.9,
            height: data.size.height * 0.35,
            margin: EdgeInsets.only(top: 40.0),
            decoration: new BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  MainAxisAlignment.center, // To make the card compact
              children: <Widget>[
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w700,
                    color: primarycolor,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, color: primarycolor),
                ),
                SizedBox(height: 24.0),
              ],
            ),
          ),
          Positioned(
            left: data.size.width * 0.30,
            child: ClipOval(
              child: Material(
                color: primarycolor, // button color
                child: InkWell(
                  // inkwell color
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Icon(
                      widget.mainIcon,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: data.size.width * 0.33,
            top: data.size.height * 0.30,
            child: ClipOval(
              child: Material(
                color: primarycolor, // button color
                child: InkWell(
                  // inkwell color
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(
                      widget.subIcon,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// Future<void> showMyDialog(BuildContext context, String title, String message,
//     String buttonMessage) async {
//   return showDialog<void>(
//     context: context,
//     barrierDismissible: false, // user must tap button!
//     builder: (BuildContext context) {
//       return AlertDialog(
//         shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
//         title: Text(
//           title,
//           style: Theme.of(context).textTheme.bodyText1.apply(
//                 color: Theme.of(context).primaryColor,
//               ),
//         ),
//         content: SingleChildScrollView(
//           child: ListBody(
//             children: <Widget>[
//               Text(
//                 message,
//                 style: Theme.of(context).textTheme.bodyText2,
//               ),
//             ],
//           ),
//         ),
//         actions: <Widget>[
//           GestureDetector(
//             onTap: () {
//               Navigator.of(context).pop();
//             },
//             child: Container(
//               height: 50,
//               width: 100,
//               child: Card(
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(32.0)),
//                 child: FlatButton(
//                   child: Text(buttonMessage,
//                       style: Theme.of(context).textTheme.bodyText2.apply(
//                             color: Colors.white,
//                           )),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(32.0)),
//                   color: Theme.of(context).primaryColor,
//                   onPressed: () {
//                     FocusScope.of(context).unfocus();
//                     Navigator.of(context).pop();
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     },
//   );
// }
