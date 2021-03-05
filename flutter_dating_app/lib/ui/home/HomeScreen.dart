import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/main.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/HomeConversationModel.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/SwipeScreen/SwipeScreen.dart';
import 'package:dating/ui/conversationsScreen/ConversationsScreen.dart';
import 'package:dating/ui/profile/ProfileScreen.dart';
import 'package:dating/ui/videoCall/VideoCallScreen.dart';
import 'package:dating/ui/videoCallsGroupChat/VideoCallsGroupScreen.dart';
import 'package:dating/ui/voiceCall/VoiceCallScreen.dart';
import 'package:dating/ui/voiceCallsGroupChat/VoiceCallsGroupScreen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum DrawerSelection { Conversations, Contacts, Search, Profile }

class HomeScreen extends StatefulWidget {
  final User user;
  static bool onGoingCall = false;

  HomeScreen({Key key, @required this.user}) : super(key: key);

  @override
  _HomeState createState() {
    return _HomeState(user);
  }
}

class _HomeState extends State<HomeScreen> {
  final User user;
  String _appBarTitle = 'Swipe';

  _HomeState(this.user);

  Widget _currentWidget;

  @override
  void initState() {
    super.initState();
    _currentWidget = SwipeScreen(
      user: user,
    );
    if (CALLS_ENABLED) _listenForCalls();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: user,
      child: Consumer<User>(
        builder: (context, user, _) {
          return Scaffold(
            appBar: AppBar(
              title: GestureDetector(
                onTap: () {
                  setState(() {
                    _appBarTitle = 'Swipe';
                    _currentWidget = SwipeScreen(
                      user: user,
                    );
                  });
                },
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: _appBarTitle == 'Swipe' ? 40 : 24,
                  height: _appBarTitle == 'Swipe' ? 40 : 24,
                  color: _appBarTitle == 'Swipe'
                      ? Color(COLOR_PRIMARY)
                      : Colors.grey,
                ),
              ),
              leading: IconButton(
                  icon: Icon(
                    Icons.person,
                    color: _appBarTitle == 'Profile'
                        ? Color(COLOR_PRIMARY)
                        : Colors.grey,
                  ),
                  iconSize: _appBarTitle == 'Profile' ? 35 : 24,
                  onPressed: () {
                    setState(() {
                      _appBarTitle = 'Profile';
                      _currentWidget = ProfileScreen(user: user);
                    });
                  }),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.message),
                  onPressed: () {
                    setState(() {
                      _appBarTitle = 'Conversations';
                      _currentWidget = ConversationsScreen(user: user);
                    });
                  },
                  color: _appBarTitle == 'Conversations'
                      ? Color(COLOR_PRIMARY)
                      : Colors.grey,
                  iconSize: _appBarTitle == 'Conversations' ? 35 : 24,
                )
              ],
              backgroundColor: Colors.transparent,
              brightness:
                  isDarkMode(context) ? Brightness.dark : Brightness.light,
              centerTitle: true,
              elevation: 0,
            ),
            body: _currentWidget,
          );
        },
      ),
    );
  }

  void _listenForCalls() {
    Stream<QuerySnapshot> callStream = FireStoreUtils.firestore
        .collection(USERS)
        .doc(user.userID)
        .collection(CALL_DATA)
        .snapshots();
    // ignore: cancel_subscriptions
    final callSubscription = callStream.listen((event) async {
      if (event.docs.isNotEmpty) {
        DocumentSnapshot callDocument = event.docs.first;
        if (callDocument.id != user.userID) {
          DocumentSnapshot userSnapShot = await FireStoreUtils.firestore
              .collection(USERS)
              .doc(event.docs.first.id)
              .get();
          User caller = User.fromJson(userSnapShot.data());
          print('${caller.fullName()} called you');
          print('${callDocument.data()['type'] ?? 'null'}');
          String type = callDocument.data()['type'] ?? '';
          bool isGroupCall = callDocument.data()['isGroupCall'] ?? false;
          String callType = callDocument.data()['callType'] ?? '';
          Map<String, dynamic> connections =
              callDocument.data()['connections'] ?? Map<String, dynamic>();
          List<dynamic> groupCallMembers =
              callDocument.data()['members'] ?? <dynamic>[];
          if (type == 'offer') {
            if (callType == VIDEO) {
              if (isGroupCall) {
                if (!HomeScreen.onGoingCall &&
                    connections.keys.contains(getConnectionID(caller.userID)) &&
                    connections[getConnectionID(caller.userID)]['description']
                            ['type'] ==
                        'offer') {
                  HomeScreen.onGoingCall = true;
                  List<User> members = [];
                  groupCallMembers.forEach((element) {
                    members.add(User.fromJson(element));
                  });
                  push(
                    context,
                    VideoCallsGroupScreen(
                        homeConversationModel: HomeConversationModel(
                            isGroupChat: true,
                            conversationModel: ConversationModel.fromJson(
                                callDocument.data()['conversationModel']),
                            members: members),
                        isCaller: false,
                        caller: caller,
                        sessionDescription:
                            connections[getConnectionID(caller.userID)]
                                ['description']['sdp'],
                        sessionType: connections[getConnectionID(caller.userID)]
                            ['description']['type']),
                  );
                }
              } else {
                push(
                  context,
                  VideoCallScreen(
                      homeConversationModel: HomeConversationModel(
                          isGroupChat: false,
                          conversationModel: null,
                          members: [caller]),
                      isCaller: false,
                      sessionDescription: callDocument.data()['data']
                      ['description']['sdp'],
                      sessionType: callDocument.data()['data']['description']
                      ['type']),
                );
              }
            } else if (callType == VOICE) {
              if (isGroupCall) {
                if (!HomeScreen.onGoingCall &&
                    connections.keys.contains(getConnectionID(caller.userID)) &&
                    connections[getConnectionID(caller.userID)]['description']
                            ['type'] ==
                        'offer') {
                  HomeScreen.onGoingCall = true;
                  List<User> members = [];
                  groupCallMembers.forEach((element) {
                    members.add(User.fromJson(element));
                  });
                  push(
                    context,
                    VoiceCallsGroupScreen(
                        homeConversationModel: HomeConversationModel(
                            isGroupChat: true,
                            conversationModel: ConversationModel.fromJson(
                                callDocument.data()['conversationModel']),
                            members: members),
                        isCaller: false,
                        caller: caller,
                        sessionDescription:
                            connections[getConnectionID(caller.userID)]
                                ['description']['sdp'],
                        sessionType: connections[getConnectionID(caller.userID)]
                            ['description']['type']),
                  );
                }
              } else {
                push(
                  context,
                  VoiceCallScreen(
                      homeConversationModel: HomeConversationModel(
                          isGroupChat: false,
                          conversationModel: null,
                          members: [caller]),
                      isCaller: false,
                      sessionDescription: callDocument.data()['data']
                      ['description']['sdp'],
                      sessionType: callDocument.data()['data']['description']
                      ['type']),
                );
              }
            }
          }
        } else {
          print('you called someone');
        }
      }
    });
    auth.FirebaseAuth.instance.authStateChanges().listen((event) {
      if (event == null) {
        callSubscription.cancel();
      }
    });
  }

  String getConnectionID(String friendID) {
    String connectionID;
    String selfID = MyAppState.currentUser.userID;
    if (friendID.compareTo(selfID) < 0) {
      connectionID = friendID + selfID;
    } else {
      connectionID = selfID + friendID;
    }
    return connectionID;
  }
}
