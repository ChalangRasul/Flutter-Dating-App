import 'package:dating/constants.dart' as Constants;
import 'package:dating/constants.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui//signUp/SignUpScreen.dart';
import 'package:dating/ui/login/LoginScreen.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 70.0, bottom: 20.0),
                child: Image.asset(
                  'assets/images/phitnestNegative.png',
                  width: 150.0,
                  height: 150.0,
                  color: Color(Constants.COLOR_PRIMARY),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 32, top: 32, right: 32, bottom: 8),
              child: Text(
                'Find your soul mate',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(Constants.COLOR_PRIMARY),
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Match and chat with people you like from your area',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: RaisedButton(
                  color: Color(Constants.COLOR_PRIMARY),
                  child: Text(
                    'Log In',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  textColor: Colors.white,
                  splashColor: Color(Constants.COLOR_PRIMARY),
                  onPressed: () {
                    push(context, new LoginScreen());
                  },
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      side: BorderSide(color: Color(Constants.COLOR_PRIMARY))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  right: 40.0, left: 40.0, top: 20, bottom: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: FlatButton(
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(COLOR_PRIMARY)),
                  ),
                  onPressed: () {
                    push(context, new SignUpScreen());
                  },
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      side: BorderSide(color: Colors.black54)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
