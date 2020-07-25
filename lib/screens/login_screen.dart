import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/widgets/login_widget.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Future<void> _showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
          title: Text('Sorry!!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Login Unsuccessfull'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.0)),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
          child: SingleChildScrollView(
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    backgroundImage: AssetImage('assests/images/logo.png'),
                    radius: 55.0,
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  LoginCard(
                      icon: Icons.person_pin,
                      titype: TextInputType.text,
                      htext: 'Name',
                      mdata: data),
                  LoginCard(
                      icon: Icons.lock,
                      titype: TextInputType.visiblePassword,
                      htext: 'Password',
                      mdata: data),
                  SizedBox(
                    height: 20.0,
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
                        _showMyDialog(context);
                      },
                      child: Text(
                        AppLocalizations.of(context).translate("Login"),
                        style: TextStyle(
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
