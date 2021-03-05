import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' as fire;
import 'package:dating/constants.dart';
import 'package:dating/main.dart';
import 'package:dating/model/User.dart' as location;
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/home/HomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:location/location.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

File _image;

class SignUpScreen extends StatefulWidget {
  @override
  State createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  TextEditingController _passwordController = new TextEditingController();
  TextEditingController _firstNameController = new TextEditingController();
  TextEditingController _lastNameController = new TextEditingController();
  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  GlobalKey<FormState> _key = new GlobalKey();
  String firstName,
      lastName,
      email,
      mobile,
      password,
      confirmPassword,
      _phoneNumber,
      _verificationID;
  LocationData signUpLocation;
  AutovalidateMode _validate = AutovalidateMode.disabled;
  bool signInWithPhoneNumber = false, _isPhoneValid = false, _codeSent = false;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      retrieveLostData();
    }

    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        brightness: isDarkMode(context) ? Brightness.dark : Brightness.light,
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        child: new Container(
          margin: new EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
          child: new Form(
            key: _key,
            autovalidateMode: _validate,
            child: formUI(),
          ),
        ),
      ),
    );
  }

  Future<void> retrieveLostData() async {
    final LostData response = await _imagePicker.getLostData();
    if (response == null) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _image = File(response.file.path);
      });
    }
  }

  _onCameraClick() {
    final action = CupertinoActionSheet(
      message: Text(
        "Add profile picture",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Choose from gallery"),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile image =
                await _imagePicker.getImage(source: ImageSource.gallery);
            if (image != null)
              setState(() {
                _image = File(image.path);
              });
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Take a picture"),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile image =
            await _imagePicker.getImage(source: ImageSource.camera);
            if (image != null)
              setState(() {
                _image = File(image.path);
              });
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  Widget formUI() {
    return new Column(
      children: <Widget>[
        new Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Create new account',
              style: TextStyle(
                  color: Color(COLOR_PRIMARY),
                  fontWeight: FontWeight.bold,
                  fontSize: 25.0),
            )),
        Padding(
          padding:
              const EdgeInsets.only(left: 8.0, top: 32, right: 8, bottom: 8),
          child: Visibility(
            visible: !_codeSent,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                CircleAvatar(
                  radius: 65,
                  backgroundColor: Colors.grey.shade400,
                  child: ClipOval(
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: _image == null
                          ? Image.asset(
                              'assets/images/placeholder.jpg',
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              _image,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  left: 80,
                  right: 0,
                  child: FloatingActionButton(
                      backgroundColor: Color(COLOR_ACCENT),
                      child: Icon(
                        Icons.camera_alt,
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                      ),
                      mini: true,
                      onPressed: _onCameraClick),
                )
              ],
            ),
          ),
        ),
        Visibility(
          visible: !_codeSent,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
              child: TextFormField(
                cursorColor: Color(COLOR_PRIMARY),
                textAlignVertical: TextAlignVertical.center,
                validator: validateName,
                controller: _firstNameController,
                onSaved: (String val) {
                  firstName = val;
                },
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                decoration: InputDecoration(
                  contentPadding:
                      new EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  fillColor: Colors.white,
                  hintText: 'First Name',
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide:
                          BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).errorColor),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).errorColor),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[200]),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: !_codeSent,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
              child: TextFormField(
                validator: validateName,
                textAlignVertical: TextAlignVertical.center,
                cursorColor: Color(COLOR_PRIMARY),
                onSaved: (String val) {
                  lastName = val;
                },
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                decoration: InputDecoration(
                  contentPadding:
                  new EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  fillColor: Colors.white,
                  hintText: 'Last Name',
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide:
                      BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
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
                  ),
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: signInWithPhoneNumber && !_codeSent,
          child: Padding(
            padding: EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Colors.grey[200])),
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
              ),
            ),
          ),
        ),
        Visibility(
          visible: signInWithPhoneNumber && _codeSent,
          child: Padding(
            padding: EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
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
            ),
          ),
        ),
        Visibility(
          visible: !signInWithPhoneNumber,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
              child: TextFormField(
                keyboardType: TextInputType.emailAddress,
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.next,
                cursorColor: Color(COLOR_PRIMARY),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                validator: validateEmail,
                onSaved: (String val) {
                  email = val;
                },
                decoration: InputDecoration(
                  contentPadding:
                  new EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  fillColor: Colors.white,
                  hintText: 'Email Address',
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide:
                      BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
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
                  ),
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: !signInWithPhoneNumber,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
              child: TextFormField(
                obscureText: true,
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                controller: _passwordController,
                validator: validatePassword,
                onSaved: (String val) {
                  password = val;
                },
                style: TextStyle(fontSize: 18.0),
                cursorColor: Color(COLOR_PRIMARY),
                decoration: InputDecoration(
                  contentPadding:
                  new EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  fillColor: Colors.white,
                  hintText: 'Password',
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide:
                      BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
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
                  ),
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: !signInWithPhoneNumber,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
              child: TextFormField(
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  _sendToServer();
                },
                obscureText: true,
                validator: (val) =>
                    validateConfirmPassword(_passwordController.text, val),
                onSaved: (String val) {
                  confirmPassword = val;
                },
                style: TextStyle(fontSize: 18.0),
                cursorColor: Color(COLOR_PRIMARY),
                decoration: InputDecoration(
                  contentPadding:
                  new EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  fillColor: Colors.white,
                  hintText: 'Confirm Password',
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide:
                      BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
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
                  ),
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: !signInWithPhoneNumber || !_codeSent,
          child: Padding(
            padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: RaisedButton(
                color: Color(COLOR_PRIMARY),
                child: Text(
                  signInWithPhoneNumber ? 'Send code' : 'Sign Up',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                textColor: isDarkMode(context) ? Colors.black : Colors.white,
                splashColor: Color(COLOR_PRIMARY),
                onPressed: () => _signUp(),
                padding: EdgeInsets.only(top: 12, bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  side: BorderSide(
                    color: Color(COLOR_PRIMARY),
                  ),
                ),
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
        InkWell(
          onTap: () {
            setState(() {
              signInWithPhoneNumber = !signInWithPhoneNumber;
            });
          },
          child: Text(
            signInWithPhoneNumber
                ? 'Sign up with E-mail'
                : 'Sign up with phone number',
            style: TextStyle(
                color: Colors.lightBlue,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1),
          ),
        )
      ],
    );
  }

  _sendToServer() async {
    if (_key.currentState.validate()) {
      _key.currentState.save();
      showProgress(context, 'Creating new account, Please wait...', false);
      var profilePicUrl = '';
      try {
        auth.UserCredential result = await auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(
            email: email.trim(), password: password.trim());
        if (_image != null) {
          updateProgress('Uploading image, Please wait...');
          profilePicUrl = await FireStoreUtils()
              .uploadUserImageToFireStorage(_image, result.user.uid);
        }
        User user = User(
            email: email.trim(),
            firstName: firstName,
            school: '',
            lastOnlineTimestamp: fire.Timestamp.now(),
            bio: '',
            age: '',
            phoneNumber: '',
            userID: result.user.uid,
            active: true,
            lastName: lastName,
            photos: [],
            showMe: true,
            location: location.Location(
                latitude: signUpLocation.latitude,
                longitude: signUpLocation.longitude),
            signUpLocation: location.Location(
                latitude: signUpLocation.latitude,
                longitude: signUpLocation.longitude),
            settings: Settings(
              pushNewMessages: true,
              pushNewMatchesEnabled: true,
              pushSuperLikesEnabled: true,
              pushTopPicksEnabled: true,
              genderPreference: 'Female',
              gender: 'Male',
              distanceRadius: '10',
              showMe: true,
            ),
            fcmToken: await FirebaseMessaging().getToken(),
            profilePictureURL: profilePicUrl);
        await FireStoreUtils.firestore
            .collection(USERS)
            .doc(result.user.uid)
            .set(user.toJson())
            .catchError((onError) {
          print(onError);
        });
        hideProgress();
        MyAppState.currentUser = user;
        pushAndRemoveUntil(context, HomeScreen(user: user), false);
      } on auth.FirebaseAuthException catch (error) {
        hideProgress();
        String message = 'Couldn\'t sign up';
        switch (error.code) {
          case 'email-already-in-use':
            message = 'Email already in use, Please pick another email!';
            break;
          case 'invalid-email':
            message = 'Enter valid e-mail';
            break;
          case 'operation-not-allowed':
            message = 'Email/password accounts are not enabled';
            break;
          case 'weak-password':
            message = 'Password must be more than 5 characters';
            break;
          case 'too-many-requests':
            message = 'Too many requests, Please try again later.';
            break;
        }
        showAlertDialog(context, 'Failed', message);
        print(error.toString());
      } catch (e) {
        hideProgress();
        showAlertDialog(context, 'Failed', 'Couldn\'t sign up');
      }
    } else {
      setState(() {
        _validate = AutovalidateMode.onUserInteraction;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _image = null;
    super.dispose();
  }

  _signUp() async {
    signUpLocation = await getCurrentLocation();
    if (signUpLocation != null) {
      signInWithPhoneNumber
          ? _submitPhoneNumber(_phoneNumber)
          : _sendToServer();
    } else {
      _scaffoldState.currentState.showSnackBar(SnackBar(
        content: Text('Location is required to match you with people from '
            'your area.'),
        duration: Duration(seconds: 6),
      ));
    }
  }

  _submitPhoneNumber(String phoneNumber) {
    if (_isPhoneValid) {
      //send code
      setState(() {
        _codeSent = true;
      });
      auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
      _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: Duration(minutes: 2),
          verificationCompleted: (auth.AuthCredential phoneAuthCredential) {},
          verificationFailed: (auth.FirebaseAuthException error) {
            print('${error.message}');
          },
          codeSent: (String verificationId, [int forceResendingToken]) {
            _verificationID = verificationId;
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _scaffoldState.currentState.showSnackBar(SnackBar(
                content: Text('Code '
                    'verification timeout, request new code.')));
            setState(() {
              _codeSent = false;
            });
          });
    }
  }

  void _submitCode(String code) async {
    showProgress(context, 'Signing up...', false);
    try {
      auth.AuthCredential credential = auth.PhoneAuthProvider.credential(
          verificationId: _verificationID, smsCode: code);
      await auth.FirebaseAuth.instance
          .signInWithCredential(credential)
          .then((auth.UserCredential authResult) async {
        User user = await FireStoreUtils().getCurrentUser(authResult.user.uid);
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
        case 'user-disabled':
          message = 'This user has been disabled.';
          break;
        default:
          message = 'An error has occurred, please try again.';
          break;
      }
      _scaffoldState.currentState
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      hideProgress();
      _scaffoldState.currentState.showSnackBar(
          SnackBar(content: Text('An error has occurred, please try again.')));
    }
  }

  void _createUserFromPhoneLogin(String userID) async {
    var profilePicUrl = '';
    if (_image != null) {
      updateProgress('Uploading image, Please wait...');
      profilePicUrl = await FireStoreUtils()
          .uploadUserImageToFireStorage(_image, userID);
    }
    User user = User(
        firstName: _firstNameController.text ?? 'Anonymous',
        lastName: _lastNameController.text ?? 'User',
        email: '',
        profilePictureURL: profilePicUrl,
        active: true,
        fcmToken: await FireStoreUtils.firebaseMessaging.getToken(),
        photos: [],
        age: '',
        bio: '',
        lastOnlineTimestamp: fire.Timestamp.now(),
        phoneNumber: _phoneNumber,
        school: '',
        settings: Settings(
            distanceRadius: '',
            gender: 'Male',
            genderPreference: 'All',
            pushNewMatchesEnabled: true,
            pushNewMessages: true,
            pushSuperLikesEnabled: true,
            pushTopPicksEnabled: true,
            showMe: true),
        showMe: true,
        signUpLocation: location.Location(
            latitude: signUpLocation.latitude,
            longitude: signUpLocation.longitude),
        location: location.Location(
            latitude: signUpLocation.latitude,
            longitude: signUpLocation.longitude),
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
}