import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' as fire;
import 'package:dating/constants.dart';
import 'package:dating/main.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/home/HomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

final _fireStoreUtils = FireStoreUtils();

class LoginScreen extends StatefulWidget {
  @override
  State createState() {
    return _LoginScreen();
  }
}

class _LoginScreen extends State<LoginScreen> {
  TextEditingController _emailController = new TextEditingController();
  TextEditingController _passwordController = new TextEditingController();
  bool signInWithPhoneNumber = false, _isPhoneValid = false, _codeSent = false;
  String _phoneNumber, _verificationID;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  GlobalKey<FormState> _key = GlobalKey();
  AutovalidateMode _validate = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        brightness: isDarkMode(context) ? Brightness.dark : Brightness.light,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.white : Colors.black),
        elevation: 0.0,
      ),
      body: Form(
        key: _key,
        autovalidateMode: _validate,
        child: ListView(
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 32.0, right: 16.0, left: 16.0),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                      color: Color(COLOR_PRIMARY),
                      fontSize: 25.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Visibility(
              visible: !signInWithPhoneNumber,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: double.infinity),
                child: Padding(
                  padding:
                  const EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                  child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      controller: _emailController,
                      style: TextStyle(fontSize: 18.0),
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: Color(COLOR_PRIMARY),
                      decoration: InputDecoration(
                        contentPadding:
                        new EdgeInsets.only(left: 16, right: 16),
                        hintText: 'E-mail Address',
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(
                                color: Color(COLOR_PRIMARY), width: 2.0)),
                        errorBorder: OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Theme
                              .of(context)
                              .errorColor),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Theme
                              .of(context)
                              .errorColor),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[200]),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                      )),
                ),
              ),
            ),
            Visibility(
              visible: !signInWithPhoneNumber,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: double.infinity),
                child: Padding(
                  padding:
                  const EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                  child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      controller: _passwordController,
                      obscureText: true,
                      onSubmitted: (password) =>
                          _login(_emailController.text, password),
                      textInputAction: TextInputAction.done,
                      style: TextStyle(fontSize: 18.0),
                      cursorColor: Color(COLOR_PRIMARY),
                      decoration: InputDecoration(
                        contentPadding:
                        new EdgeInsets.only(left: 16, right: 16),
                        hintText: 'Password',
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(
                                color: Color(COLOR_PRIMARY), width: 2.0)),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme
                              .of(context)
                              .errorColor),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme
                              .of(context)
                              .errorColor),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[200]),
                          borderRadius: BorderRadius.circular(25.0),
                        ),)),
                ),
              ),
            ),
            Visibility(
              visible: signInWithPhoneNumber && !_codeSent,
              child: Padding(
                padding: EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      shape: BoxShape.rectangle,
                      border:
                      Border.all(color: Colors.grey[200])),
                  child: InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) =>
                    _phoneNumber = number.phoneNumber,
                    onInputValidated: (bool value) => _isPhoneValid = value,
                    ignoreBlank: true,
                    autoValidateMode: AutovalidateMode.onUserInteraction,
                    inputDecoration: InputDecoration(
                      hintText: 'Phone number',
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    inputBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    initialValue: PhoneNumber(isoCode: 'US'),
                    selectorConfig: SelectorConfig(
                        selectorType: PhoneInputSelectorType.DIALOG),
                  ),),
              ),),
            Visibility(
              visible: signInWithPhoneNumber && _codeSent,
              child: Padding(
                padding:
                EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                child: PinCodeTextField(
                  appContext: context,
                  length: 6,
                  keyboardType: TextInputType.phone,
                  backgroundColor: Colors.transparent,
                  pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(5),
                      fieldHeight: 40,
                      fieldWidth: 40,
                      activeColor: Color(COLOR_PRIMARY),
                      activeFillColor: Colors.grey[100],
                      selectedFillColor: Colors.transparent,
                      selectedColor: Color(COLOR_PRIMARY),
                      inactiveColor: Colors.grey[600],
                      inactiveFillColor: Colors.transparent),
                  enableActiveFill: true,
                  onCompleted: (v) {
                    _submitCode(v);
                  },
                  onChanged: (value) {
                    print(value);
                  },
                ),),),
            Visibility(
              visible: !signInWithPhoneNumber || !_codeSent,
              child: Padding(
                padding:
                const EdgeInsets.only(right: 40.0, left: 40.0, top: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: RaisedButton(
                    color: Color(COLOR_PRIMARY),
                    child: Text(
                      signInWithPhoneNumber ? 'Send code' : 'Log In',
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    textColor:
                    isDarkMode(context) ? Colors.black : Colors.white,
                    splashColor: Color(COLOR_PRIMARY),
                    onPressed: () =>
                    signInWithPhoneNumber
                        ? _submitPhoneNumber(_phoneNumber)
                        : _login(
                        _emailController.text, _passwordController.text),
                    padding: EdgeInsets.only(top: 12, bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        side: BorderSide(color: Color(COLOR_PRIMARY))),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'OR',
                  style: TextStyle(
                      color: isDarkMode(context) ? Colors.white : Colors.black),
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.only(right: 40.0, left: 40.0, bottom: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: RaisedButton.icon(
                  label: Text(
                    'Facebook Login',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                        isDarkMode(context) ? Colors.black : Colors.white),
                  ),
                  icon: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.asset(
                      'assets/images/facebook_logo.png',
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                      height: 30,
                      width: 30,
                    ),
                  ),
                  color: Color(FACEBOOK_BUTTON_COLOR),
                  textColor: Colors.white,
                  splashColor: Color(FACEBOOK_BUTTON_COLOR),
                  onPressed: () async {
                    final facebookLogin = FacebookLogin();
                    final result = await facebookLogin.logIn(['email']);
                    switch (result.status) {
                      case FacebookLoginStatus.loggedIn:
                        showProgress(
                            context, 'Logging in, please wait...', false);
                        await auth.FirebaseAuth.instance
                            .signInWithCredential(
                            auth.FacebookAuthProvider.credential(
                                result.accessToken.token))
                            .then((auth.UserCredential authResult) async {
                          User user = await _fireStoreUtils
                              .getCurrentUser(authResult.user.uid);
                          if (user == null) {
                            _createUserFromFacebookLogin(
                                result, authResult.user.uid);
                          } else {
                            _syncUserDataWithFacebookData(result, user);
                          }
                        });
                        break;
                      case FacebookLoginStatus.cancelledByUser:
                        break;
                      case FacebookLoginStatus.error:
                        showAlertDialog(
                            context, 'Error', 'Couldn\'t login via facebook.');
                        break;
                    }
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      side: BorderSide(color: Color(FACEBOOK_BUTTON_COLOR))),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  signInWithPhoneNumber = !signInWithPhoneNumber;
                });
              },
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    signInWithPhoneNumber
                        ? 'Login with E-mail'
                        : 'Login with phone number',
                    style: TextStyle(
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _login(String email, String password) async {
    if (_key.currentState.validate()) {
      _key.currentState.save();
      showProgress(context, 'Logging in, please wait...', false);
      User user =
          await loginWithUserNameAndPassword(email.trim(), password.trim());
      if (user != null)
        pushAndRemoveUntil(context, HomeScreen(user: user), false);
    } else {
      setState(() {
        _validate = AutovalidateMode.onUserInteraction;
      });
    }
  }

  loginWithUserNameAndPassword(String email, String password) async {
    try {
      auth.UserCredential result = await auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      fire.DocumentSnapshot documentSnapshot = await FireStoreUtils.firestore
          .collection(USERS)
          .doc(result.user.uid)
          .get();
      User user;
      if (documentSnapshot != null && documentSnapshot.exists) {
        user = User.fromJson(documentSnapshot.data());
        user.active = true;
        user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken();
        await FireStoreUtils.updateCurrentUser(user);
        hideProgress();
        MyAppState.currentUser = user;
      }
      return user;
    } on auth.FirebaseAuthException catch (exception) {
      hideProgress();
      switch ((exception).code) {
        case "invalid-email":
          showAlertDialog(context, 'Couldn\'t Authenticate',
              'Email address is malformed.');
          break;
        case "wrong-password":
          showAlertDialog(
              context, 'Couldn\'t Authenticate', 'Wrong password.');
          break;
        case "user-not-found":
          showAlertDialog(context, 'Couldn\'t Authenticate',
              'No user corresponding to the given email address.');
          break;
        case "user-disabled":
          showAlertDialog(
              context, 'Couldn\'t Authenticate',
              'This user has been disabled.');
          break;
        case 'too-many-requests':
          showAlertDialog(
              context,
              'Couldn\'t Authenticate',
              'Too many requests, Please try again later.');
          break;
      }
      print(exception.toString());
      return null;
    } catch (e) {
      hideProgress();
      showAlertDialog(context, 'Couldn\'t Authenticate',
          'Login failed. Please try again.');
      print(e.toString());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _createUserFromFacebookLogin(
      FacebookLoginResult result, String userID) async {
    final token = result.accessToken.token;
    final graphResponse = await http.get('https://graph.facebook.com/v2'
        '.12/me?fields=name,first_name,last_name,email,picture.type(large)&access_token=$token');
    final profile = json.decode(graphResponse.body);
    User user = User(
        firstName: profile['first_name'],
        lastName: profile['last_name'],
        email: profile['email'],
        profilePictureURL: profile['picture']['data']['url'],
        active: true,
        fcmToken: await FireStoreUtils.firebaseMessaging.getToken(),
        photos: [],
        age: '',
        bio: '',
        lastOnlineTimestamp: fire.Timestamp.now(),
        phoneNumber: _phoneNumber,
        school: '',
        settings: Settings(distanceRadius: '',
            gender: 'Male',
            genderPreference: 'All',
            pushNewMatchesEnabled: true,
            pushNewMessages: true,
            pushSuperLikesEnabled: true,
            pushTopPicksEnabled: true,
            showMe: true),
        showMe: true,
        signUpLocation: Location(latitude: 0.1, longitude: 0.1),
        location: Location(latitude: 0.1, longitude: 0.1),
        userID: userID);
    await FireStoreUtils.firestore
        .collection(USERS)
        .doc(userID)
        .set(user.toJson())
        .then((onValue) {
      MyAppState.currentUser = null;
      MyAppState.currentUser = user;
      hideProgress();
      pushAndRemoveUntil(context, HomeScreen(user: user), false);
    });
  }

  void _createUserFromPhoneLogin(String userID) async {
    User user = User(
        firstName: 'Anonymous',
        lastName: 'User',
        email: '',
        profilePictureURL: '',
        active: true,
        fcmToken: await FireStoreUtils.firebaseMessaging.getToken(),
        photos: [],
        age: '',
        bio: '',
        lastOnlineTimestamp: fire.Timestamp.now(),
        phoneNumber: _phoneNumber,
        school: '',
        settings: Settings(distanceRadius: '',
            gender: 'Male',
            genderPreference: 'All',
            pushNewMatchesEnabled: true,
            pushNewMessages: true,
            pushSuperLikesEnabled: true,
            pushTopPicksEnabled: true,
            showMe: true),
        showMe: true,
        signUpLocation: Location(latitude: 0.1, longitude: 0.1),
        location: Location(latitude: 0.1, longitude: 0.1),
        userID: userID);
    await FireStoreUtils.firestore
        .collection(USERS)
        .doc(userID)
        .set(user.toJson())
        .then((onValue) {
      MyAppState.currentUser = null;
      MyAppState.currentUser = user;
      hideProgress();
      pushAndRemoveUntil(context, HomeScreen(user: user), false);
    });
  }

  void _syncUserDataWithFacebookData(FacebookLoginResult result,
      User user) async {
    final token = result.accessToken.token;
    final graphResponse = await http.get('https://graph.facebook.com/v2'
        '.12/me?fields=name,first_name,last_name,email,picture.type(large)&access_token=$token');
    final profile = json.decode(graphResponse.body);
    user.profilePictureURL = profile['picture']['data']['url'];
    user.firstName = profile['first_name'];
    user.lastName = profile['last_name'];
    user.email = profile['email'];
    user.active = true;
    user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken();
    await FireStoreUtils.updateCurrentUser(user);
    MyAppState.currentUser = user;
    hideProgress();
    pushAndRemoveUntil(context, HomeScreen(user: user), false);
  }

  _submitPhoneNumber(String phoneNumber) {
    if (_isPhoneValid) {
      //send code
      setState(() {
        _codeSent = true;
      });
      auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
      _auth.verifyPhoneNumber(phoneNumber: phoneNumber,
          timeout: Duration(minutes: 2),
          verificationCompleted: (auth.AuthCredential phoneAuthCredential) {},
          verificationFailed: (auth.FirebaseAuthException error) {
            print('${error.message}');
          },
          codeSent: (String verificationId, [int forceResendingToken]) {
            _verificationID = verificationId;
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            Scaffold.of(context).showSnackBar(SnackBar(content: Text('Code '
                'verification timeout, request new code.')));
            setState(() {
              _codeSent = false;
            });
          });
    }
  }

  void _submitCode(String code) async {
    showProgress(context, 'Logging in...', false);
    try {
      auth.AuthCredential credential = auth.PhoneAuthProvider.credential(
          verificationId: _verificationID, smsCode: code);
      await auth.FirebaseAuth.instance.signInWithCredential(
          credential).then((auth.UserCredential authResult) async {
        User user = await _fireStoreUtils
            .getCurrentUser(authResult.user.uid);
        if (user == null) {
          _createUserFromPhoneLogin(authResult.user.uid);
        } else {
          MyAppState.currentUser = user;
          hideProgress();
          pushAndRemoveUntil(context, HomeScreen(user: user), false);
        }
      });
    } on auth.FirebaseAuthException catch (exception) {
      hideProgress();
      String message = 'An error has occurred, please try again.';
      switch (exception.code) {
        case 'invalid-verification-code':
          message = 'Invalid code or has been expired.';
          break;
        case "user-disabled":
          message = 'This user has been disabled.';
          break;
        default:
          message = 'An error has occurred, please try again.';
          break;
      }
      _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      hideProgress();
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(content: Text('An error has occurred, please try again.')));
    }
  }
}