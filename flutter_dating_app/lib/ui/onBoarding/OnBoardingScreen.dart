import 'package:dating/constants.dart' as Constants;
import 'package:dating/services/helper.dart';
import 'package:dating/ui/auth/AuthScreen.dart';
import 'package:flutter/material.dart';
import 'package:page_view_indicators/circle_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _currentPageNotifier = ValueNotifier<int>(0);

final List<String> _titlesList = [
  'Get a Date',
  'Private Messages',
  'Send Photos',
  'Get Notified'
];

final List<String> _subtitlesList = [
  'Swipe right to get a match with people you like from your area.',
  'Chat privately with people you match.',
  'Have fun with your matches by sending photos and videos to each other.',
  'Receive notifications when you get new messages and matches.'
];

final List<dynamic> _imageList = [
  'assets/images/app_logo.png',
  Icons.chat_bubble_outline,
  Icons.photo_camera,
  Icons.notifications_none
];
final List<Widget> _pages = [];

List<Widget> populatePages(BuildContext context) {
  _pages.clear();
  _titlesList.asMap().forEach((index, value) => _pages.add(getPage(
      _imageList.elementAt(index),
      value,
      _subtitlesList.elementAt(index),
      context,
      _isLastPage(index + 1, _titlesList.length))));
  return _pages;
}

Widget _buildCircleIndicator() {
  return CirclePageIndicator(
    selectedDotColor: Colors.white,
    dotColor: Colors.white30,
    itemCount: _pages.length,
    currentPageNotifier: _currentPageNotifier,
  );
}

Widget getPage(dynamic image, String title, String subTitle,
    BuildContext context, bool isLastPage) {
  return Stack(
    children: <Widget>[
      Center(
        child: Container(
          color: Color(Constants.COLOR_PRIMARY),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: image is String
                        ? Image.asset(
                            image,
                            color: Colors.white,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            image as IconData,
                            color: Colors.white,
                            size: 150,
                          ),
                  ),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      subTitle,
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      Visibility(
        visible: isLastPage,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: OutlineButton(
                onPressed: () {
                  setFinishedOnBoarding();
                  pushReplacement(context, new AuthScreen());
                },
                child: Text(
                  'Continue',
                  style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                borderSide: BorderSide(color: Colors.white),
                shape: StadiumBorder(),
              ),
            )),
      ),
    ],
  );
}

Future<bool> setFinishedOnBoarding() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.setBool(Constants.FINISHED_ON_BOARDING, true);
}

bool _isLastPage(int currentPosition, int pagesNumber) {
  if (currentPosition == pagesNumber) {
    return true;
  } else {
    return false;
  }
}

class OnBoardingScreen extends StatefulWidget {
  @override
  _OnBoardingScreenState createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  @override
  void dispose() {
    _currentPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: <Widget>[
            PageView(
              children: populatePages(context),
              onPageChanged: (int index) {
                _currentPageNotifier.value = index;
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildCircleIndicator(),
              ),
            )
          ],
        ));
  }
}
