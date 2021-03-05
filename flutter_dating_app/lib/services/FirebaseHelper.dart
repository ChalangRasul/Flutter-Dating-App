import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/main.dart';
import 'package:dating/model/BlockUserModel.dart';
import 'package:dating/model/ChannelParticipation.dart';
import 'package:dating/model/ChatModel.dart';
import 'package:dating/model/ChatVideoContainer.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/HomeConversationModel.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/Swipe.dart';
import 'package:dating/model/SwipeCounterModel.dart';
import 'package:dating/model/User.dart';
import 'package:dating/model/User.dart' as location;
import 'package:dating/services/helper.dart';
import 'package:dating/ui/matchScreen/MatchScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class FireStoreUtils {
  static FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  Reference storage = FirebaseStorage.instance.ref();
  List<Swipe> matchedUsersList = [];
  StreamController<List<HomeConversationModel>> conversationsStream;
  List<HomeConversationModel> homeConversations = [];
  List<BlockUserModel> blockedList = [];
  List<User> matches = [];
  StreamController tinderCardsStreamController;

  Future<User> getCurrentUser(String uid) async {
    DocumentSnapshot userDocument =
        await firestore.collection(USERS).doc(uid).get();
    if (userDocument != null && userDocument.exists) {
      return User.fromJson(userDocument.data());
    } else {
      return null;
    }
  }

static Future<User> updateCurrentUser(User user) async {
    return await firestore
        .collection(USERS)
        .doc(user.userID)
        .set(user.toJson())
        .then((document) {
      return user;
    });
  }

  Future<String> uploadUserImageToFireStorage(File image, String userID) async {
    Reference upload = storage.child("images/$userID.png");
    UploadTask uploadTask = upload.putFile(image);
    var downloadUrl = await (await uploadTask.whenComplete(() {})).ref
        .getDownloadURL();
    return downloadUrl.toString();
  }

  Future<Url> uploadChatImageToFireStorage(File image,
      BuildContext context) async {
    showProgress(context, 'Uploading image...', false);
    var uniqueID = Uuid().v4();
    Reference upload = storage.child("images/$uniqueID.png");
    UploadTask uploadTask = upload.putFile(image);
    uploadTask.snapshotEvents.listen((event) {
      updateProgress(
          'Uploading image ${(event.bytesTransferred.toDouble() / 1000)
              .toStringAsFixed(2)} /'
              '${(event.totalBytes.toDouble() / 1000)
              .toStringAsFixed(2)} '
              'KB');
    });
    uploadTask.whenComplete(() {}).catchError((onError) {
      print((onError as PlatformException).message);
    });
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    hideProgress();
    return Url(mime: metaData.contentType, url: downloadUrl.toString());
  }

  Future<ChatVideoContainer> uploadChatVideoToFireStorage(File video,
      BuildContext context) async {
    showProgress(context, 'Uploading video...', false);
    var uniqueID = Uuid().v4();
    Reference upload = storage.child("videos/$uniqueID.mp4");
    SettableMetadata metadata = SettableMetadata(contentType: 'video');
    UploadTask uploadTask = upload.putFile(video, metadata);
    uploadTask.snapshotEvents.listen((event) {
      updateProgress(
          'Uploading video ${(event.bytesTransferred.toDouble() / 1000)
              .toStringAsFixed(2)} /'
              '${(event.totalBytes.toDouble() / 1000)
              .toStringAsFixed(2)} '
              'KB');
    });
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    final uint8list = await VideoThumbnail.thumbnailFile(
        video: downloadUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG);
    final file = File(uint8list);
    String thumbnailDownloadUrl = await uploadVideoThumbnailToFireStorage(file);
    hideProgress();
    return ChatVideoContainer(
        videoUrl: Url(url: downloadUrl.toString(), mime: metaData.contentType),
        thumbnailUrl: thumbnailDownloadUrl);
  }

  Future<String> uploadVideoThumbnailToFireStorage(File file) async {
    var uniqueID = Uuid().v4();
    Reference upload = storage.child("thumbnails/$uniqueID.png");
    UploadTask uploadTask = upload.putFile(file);
    var downloadUrl = await (await uploadTask.whenComplete(() {})).ref
        .getDownloadURL();
    return downloadUrl.toString();
  }

  Future<List<Swipe>> getMatches(String userID) async {
    List matchList = List<Swipe>();
    await firestore
        .collection(SWIPES)
        .where('user1', isEqualTo: userID)
        .where('hasBeenSeen', isEqualTo: true)
        .get()
        .then((querysnapShot) {
      querysnapShot.docs.forEach((doc) {
        Swipe match = Swipe.fromJson(doc.data());
        if (match.id.isEmpty) {
          match.id = doc.id;
        }
        matchList.add(match);
      });
    });
    return matchList.toSet().toList();
  }

  Future<bool> removeMatch(String id) async {
    bool isSuccessful;
    await firestore.collection(SWIPES).doc(id).delete().then((onValue) {
      isSuccessful = true;
    }, onError: (e) {
      print('${e.toString()}');
      isSuccessful = false;
    });
    return isSuccessful;
  }

  Future<List<User>> getMatchedUserObject(String userID) async {
    List<String> friendIDs = [];
    matchedUsersList.clear();
    matchedUsersList = await getMatches(userID);
    matchedUsersList.forEach((matchedUser) {
      friendIDs.add(matchedUser.user2);
    });
    matches.clear();
    for (String id in friendIDs) {
      await firestore.collection(USERS).doc(id).get().then((user) {
        matches.add(User.fromJson(user.data()));
      });
    }
    return matches;
  }

  Stream<List<HomeConversationModel>> getConversations(String userID) async* {
    conversationsStream = StreamController<List<HomeConversationModel>>();
    HomeConversationModel newHomeConversation;

    firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('user', isEqualTo: userID)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        conversationsStream.sink.add(homeConversations);
      } else {
        homeConversations.clear();
        Future.forEach(querySnapshot.docs, (DocumentSnapshot document) {
          if (document != null && document.exists) {
            ChannelParticipation participation =
            ChannelParticipation.fromJson(document.data());
            firestore
                .collection(CHANNELS)
                .doc(participation.channel)
                .snapshots()
                .listen((channel) async {
              if (channel != null && channel.exists) {
                bool isGroupChat = !channel.id.contains(userID);
                List<User> users = [];
                if (isGroupChat) {
                  getGroupMembers(channel.id).listen((listOfUsers) {
                    if (listOfUsers.isNotEmpty) {
                      users = listOfUsers;
                      newHomeConversation = HomeConversationModel(
                          conversationModel:
                          ConversationModel.fromJson(channel.data()),
                          isGroupChat: isGroupChat,
                          members: users);

                      if (newHomeConversation.conversationModel.id.isEmpty)
                        newHomeConversation.conversationModel.id =
                            channel.id;

                      homeConversations
                          .removeWhere((conversationModelToDelete) {
                        return newHomeConversation.conversationModel.id ==
                            conversationModelToDelete.conversationModel.id;
                      });
                      homeConversations.add(newHomeConversation);
                      homeConversations.sort((a, b) => a
                          .conversationModel.lastMessageDate
                          .compareTo(b.conversationModel.lastMessageDate));
                      conversationsStream.sink
                          .add(homeConversations.reversed.toList());
                    }
                  });
                } else {
                  getUserByID(channel.id.replaceAll(userID, ''))
                      .listen((user) {
                    users.clear();
                    users.add(user);
                    newHomeConversation = HomeConversationModel(
                        conversationModel:
                        ConversationModel.fromJson(channel.data()),
                        isGroupChat: isGroupChat,
                        members: users);

                    if (newHomeConversation.conversationModel.id.isEmpty)
                      newHomeConversation.conversationModel.id =
                          channel.id;

                    homeConversations.removeWhere((conversationModelToDelete) {
                      return newHomeConversation.conversationModel.id ==
                          conversationModelToDelete.conversationModel.id;
                    });

                    homeConversations.add(newHomeConversation);
                    homeConversations.sort((a, b) => a
                        .conversationModel.lastMessageDate
                        .compareTo(b.conversationModel.lastMessageDate));
                    conversationsStream.sink
                        .add(homeConversations.reversed.toList());
                  });
                }
              }
            });
          }
        });
      }
    });
    yield* conversationsStream.stream;
  }

  Stream<List<User>> getGroupMembers(String channelID) async* {
    StreamController<List<User>> membersStreamController = StreamController();
    getGroupMembersIDs(channelID).listen((memberIDs) {
      if (memberIDs.isNotEmpty) {
        List<User> groupMembers = [];
        for (String id in memberIDs) {
          getUserByID(id).listen((user) {
            groupMembers.add(user);
            membersStreamController.sink.add(groupMembers);
          });
        }
      } else {
        membersStreamController.sink.add([]);
      }
    });
    yield* membersStreamController.stream;
  }

  Stream<List<String>> getGroupMembersIDs(String channelID) async* {
    StreamController<List<String>> membersIDsStreamController =
    StreamController();
    firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: channelID)
        .snapshots()
        .listen((participations) {
      List<String> uids = [];
      for (DocumentSnapshot document in participations.docs) {
        uids.add(document.data()['user'] ?? '');
      }
      if (uids.contains(MyAppState.currentUser.userID)) {
        membersIDsStreamController.sink.add(uids);
      } else {
        membersIDsStreamController.sink.add([]);
      }
    });
    yield* membersIDsStreamController.stream;
  }

  Stream<User> getUserByID(String id) async* {
    StreamController<User> userStreamController = StreamController();
    firestore.collection(USERS).doc(id).snapshots().listen((user) {
      userStreamController.sink.add(User.fromJson(user.data()));
    });
    yield* userStreamController.stream;
  }

  Future<ConversationModel> getChannelByIdOrNull(String channelID) async {
    ConversationModel conversationModel;
    await firestore.collection(CHANNELS).doc(channelID).get().then(
            (channel) {
          if (channel != null && channel.exists) {
            conversationModel = ConversationModel.fromJson(channel.data());
          }
        }, onError: (e) {
      print((e as PlatformException).message);
    });
    return conversationModel;
  }

  Stream<ChatModel> getChatMessages(
      HomeConversationModel homeConversationModel) async* {
    StreamController<ChatModel> chatModelStreamController = StreamController();
    ChatModel chatModel = ChatModel();
    List<MessageData> listOfMessages = [];
    List<User> listOfMembers = homeConversationModel.members;
    if (homeConversationModel.isGroupChat) {
      homeConversationModel.members.forEach((groupMember) {
        if (groupMember.userID != MyAppState.currentUser.userID) {
          getUserByID(groupMember.userID).listen((updatedUser) {
            for (int i = 0; i < listOfMembers.length; i++) {
              if (listOfMembers[i].userID == updatedUser.userID) {
                listOfMembers[i] = updatedUser;
              }
            }
            chatModel.message = listOfMessages;
            chatModel.members = listOfMembers;
            chatModelStreamController.sink.add(chatModel);
          });
        }
      });
    } else {
      User friend = homeConversationModel.members.first;
      getUserByID(friend.userID).listen((user) {
        listOfMembers.clear();
        listOfMembers.add(user);
        chatModel.message = listOfMessages;
        chatModel.members = listOfMembers;
        chatModelStreamController.sink.add(chatModel);
      });
    }
    if (homeConversationModel.conversationModel != null) {
      firestore
          .collection(CHANNELS)
          .doc(homeConversationModel.conversationModel.id)
          .collection(THREAD)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((onData) {
        listOfMessages.clear();
        onData.docs.forEach((document) {
          listOfMessages.add(MessageData.fromJson(document.data()));
        });
        chatModel.message = listOfMessages;
        chatModel.members = listOfMembers;
        chatModelStreamController.sink.add(chatModel);
      });
    }
    yield* chatModelStreamController.stream;
  }

  Future<void> sendMessage(List<User> members, bool isGroup,
      MessageData message, ConversationModel conversationModel) async {
    var ref = firestore
        .collection(CHANNELS)
        .doc(conversationModel.id)
        .collection(THREAD)
        .doc();
    message.messageID = ref.id;
    ref.set(message.toJson());
    await Future.forEach(members, (User element) async {
      if (element.settings.pushNewMessages) {
        await sendNotification(
            element.fcmToken,
            isGroup
                ? conversationModel.name
                : MyAppState.currentUser.fullName(),
            message.content);
      }
    });
  }

  Future<bool> createConversation(ConversationModel conversation) async {
    bool isSuccessful;
    await firestore
        .collection(CHANNELS)
        .doc(conversation.id)
        .set(conversation.toJson())
        .then((onValue) async {
      ChannelParticipation myChannelParticipation = ChannelParticipation(
          user: MyAppState.currentUser.userID, channel: conversation.id);
      ChannelParticipation myFriendParticipation = ChannelParticipation(
          user: conversation.id.replaceAll(MyAppState.currentUser.userID, ''),
          channel: conversation.id);
      await createChannelParticipation(myChannelParticipation);
      await createChannelParticipation(myFriendParticipation);
      isSuccessful = true;
    }, onError: (e) {
      print((e as PlatformException).message);
      isSuccessful = false;
    });
    return isSuccessful;
  }

  Future<void> updateChannel(ConversationModel conversationModel) async {
    await firestore
        .collection(CHANNELS)
        .doc(conversationModel.id)
        .update(conversationModel.toJson());
  }

  Future<void> createChannelParticipation(
      ChannelParticipation channelParticipation) async {
    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .add(channelParticipation.toJson());
  }

  Future<HomeConversationModel> createGroupChat(List<User> selectedUsers,
      String groupName) async {
    HomeConversationModel groupConversationModel;
    DocumentReference channelDoc = firestore.collection(CHANNELS).doc();
    ConversationModel conversationModel = ConversationModel();
    conversationModel.id = channelDoc.id;
    conversationModel.creatorId = MyAppState.currentUser.userID;
    conversationModel.name = groupName;
    conversationModel.lastMessage =
    "${MyAppState.currentUser.fullName()} created this group";
    conversationModel.lastMessageDate = Timestamp.now();
    await channelDoc.set(conversationModel.toJson()).then((onValue) async {
      selectedUsers.add(MyAppState.currentUser);
      for (User user in selectedUsers) {
        ChannelParticipation channelParticipation = ChannelParticipation(
            channel: conversationModel.id, user: user.userID);
        await createChannelParticipation(channelParticipation);
      }
      groupConversationModel = HomeConversationModel(
          isGroupChat: true,
          members: selectedUsers,
          conversationModel: conversationModel);
    });
    return groupConversationModel;
  }

  Future<bool> leaveGroup(ConversationModel conversationModel) async {
    bool isSuccessful = false;
    conversationModel.lastMessage = "${MyAppState.currentUser.fullName()} left";
    conversationModel.lastMessageDate = Timestamp.now();
    await updateChannel(conversationModel).then((_) async {
      await firestore
          .collection(CHANNEL_PARTICIPATION)
          .where('channel', isEqualTo: conversationModel.id)
          .where('user', isEqualTo: MyAppState.currentUser.userID)
          .get()
          .then((onValue) async {
        await firestore
            .collection(CHANNEL_PARTICIPATION)
            .doc(onValue.docs.first.id)
            .delete()
            .then((onValue) {
          isSuccessful = true;
        });
      });
    });
    return isSuccessful;
  }

  Future<bool> blockUser(User blockedUser, String type) async {
    bool isSuccessful = false;
    BlockUserModel blockUserModel = BlockUserModel(
        type: type,
        source: MyAppState.currentUser.userID,
        dest: blockedUser.userID,
        createdAt: Timestamp.now());
    await firestore
        .collection(REPORTS)
        .add(blockUserModel.toJson())
        .then((onValue) {
      isSuccessful = true;
    });
    return isSuccessful;
  }

  Stream<bool> getBlocks() async* {
    StreamController<bool> refreshStreamController = StreamController();
    firestore
        .collection(REPORTS)
        .where('source', isEqualTo: MyAppState.currentUser.userID)
        .snapshots()
        .listen((onData) {
      List<BlockUserModel> list = [];
      for (DocumentSnapshot block in onData.docs) {
        list.add(BlockUserModel.fromJson(block.data()));
      }
      blockedList = list;

      if (homeConversations.isNotEmpty || matches.isNotEmpty) {
        refreshStreamController.sink.add(true);
      }
    });
    yield* refreshStreamController.stream;
  }

  bool validateIfUserBlocked(String userID) {
    for (BlockUserModel blockedUser in blockedList) {
      if (userID == blockedUser.dest) {
        return true;
      }
    }
    return false;
  }

  Stream<List<User>> getTinderUsers() async* {
    tinderCardsStreamController = StreamController<List<User>>();
    List<User> tinderUsers = [];
    LocationData locationData = await getCurrentLocation();
    if (locationData != null) {
      MyAppState.currentUser.location = location.Location(
          latitude: locationData.latitude, longitude: locationData.longitude);
      await firestore
          .collection(USERS)
          .where('showMe', isEqualTo: true)
          .get()
          .then((value) async {
        value.docs.forEach((DocumentSnapshot tinderUser) async {
          try {
            if (tinderUser.id != MyAppState.currentUser.userID) {
              User user = User.fromJson(tinderUser.data());
              double distance =
              getDistance(user.location, MyAppState.currentUser.location);
              if (await _isValidUserForTinderSwipe(user, distance)) {
                user.milesAway = '$distance Miles Aways';
                tinderUsers.insert(0, user);
                tinderCardsStreamController.add(tinderUsers);
              }
              if (tinderUsers.isEmpty) {
                tinderCardsStreamController.add(tinderUsers);
              }
            }
          } catch (e) {
            print(
                'FireStoreUtils.getTinderUsers failed to parse user object $e');
          }
        });
      }, onError: (e) {
        print('${(e as PlatformException).message}');
      });
    }
    yield* tinderCardsStreamController.stream;
  }

  Future<bool> _isValidUserForTinderSwipe(User tinderUser,
      double distance) async {
    //make sure that we haven't swiped right this user before
    QuerySnapshot result1 = await firestore
        .collection(SWIPES)
        .where('user1', isEqualTo: MyAppState.currentUser.userID)
        .where('user2', isEqualTo: tinderUser.userID)
        .get()
        .catchError((onError) {
      print('${(onError as PlatformException).message}');
    });
    return result1.docs.isEmpty &&
        isPreferredGender(tinderUser.settings.gender) &&
        isInPreferredDistance(distance);
  }

  matchChecker(BuildContext context) async {
    String myID = MyAppState.currentUser.userID;
    QuerySnapshot result = await firestore
        .collection(SWIPES)
        .where('user2', isEqualTo: myID)
        .where('type', isEqualTo: 'like')
        .get();
    if (result.docs.isNotEmpty) {
      await Future.forEach(result.docs, (DocumentSnapshot document) async {
        try {
          Swipe match = Swipe.fromJson(document.data());
          QuerySnapshot unSeenMatches = await firestore
              .collection(SWIPES)
              .where('user1', isEqualTo: myID)
              .where('type', isEqualTo: 'like')
              .where('user2', isEqualTo: match.user1)
              .where('hasBeenSeen', isEqualTo: false)
              .get();
          if (unSeenMatches.docs.isNotEmpty) {
            unSeenMatches.docs.forEach((DocumentSnapshot unSeenMatch) async {
              DocumentSnapshot matchedUserDocSnapshot =
              await firestore.collection(USERS).doc(match.user1).get();
              User matchedUser = User.fromJson(matchedUserDocSnapshot.data());
              push(
                  context,
                  MatchScreen(
                    matchedUser: matchedUser,
                  ));
              updateHasBeenSeen(unSeenMatch.data());
            });
          }
        } catch (e) {
          print('FireStoreUtils.matchChecker failed to parse object '
              '$e');
        }
      });
    }
  }

  onSwipeLeft(User dislikedUser) async {
    DocumentReference documentReference =
    firestore.collection(SWIPES).doc();
    Swipe leftSwipe = Swipe(
        id: documentReference.id,
        type: 'dislike',
        user1: MyAppState.currentUser.userID,
        user2: dislikedUser.userID,
        created_at: Timestamp.now(),
        createdAt: Timestamp.now(),
        hasBeenSeen: false);
    await documentReference.set(leftSwipe.toJson());
  }

  Future<User> onSwipeRight(User user) async {
    // check if this user sent a match request before ? if yes, it's a match,
    // if not, send him match request
    QuerySnapshot querySnapshot = await firestore
        .collection(SWIPES)
        .where('user1', isEqualTo: user.userID)
        .where('user2', isEqualTo: MyAppState.currentUser.userID)
        .where('type', isEqualTo: 'like')
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      //this user sent me a match request, let's talk
      DocumentReference document = firestore.collection(SWIPES).doc();
      var swipe = Swipe(
          id: document.id,
          type: 'like',
          hasBeenSeen: true,
          created_at: Timestamp.now(),
          createdAt: Timestamp.now(),
          user1: MyAppState.currentUser.userID,
          user2: user.userID);
      await document.set(swipe.toJson());
      if (user.settings.pushNewMatchesEnabled) {
        await sendNotification(
            user.fcmToken,
            'New match',
            'You have got a new '
                'match: ${MyAppState.currentUser.fullName()}.');
      }

      return user;
    } else {
      //this user didn't send me a match request, let's send match request
      // and keep swippeing
      await sendSwipeRequest(user, MyAppState.currentUser.userID);
      return null;
    }
  }

  Future<bool> sendSwipeRequest(User user, String myID) async {
    bool isSuccessful;
    DocumentReference documentReference =
    firestore.collection(SWIPES).doc();
    Swipe swipe = Swipe(
        id: documentReference.id,
        user1: myID,
        user2: user.userID,
        hasBeenSeen: false,
        createdAt: Timestamp.now(),
        created_at: Timestamp.now(),
        type: 'like');
    await documentReference.set(swipe.toJson()).then((onValue) {
      isSuccessful = true;
    }, onError: (e) {
      isSuccessful = false;
    });
    return isSuccessful;
  }

  updateHasBeenSeen(Map<String, dynamic> target) async {
    target['hasBeenSeen'] = true;
    await firestore
        .collection(SWIPES)
        .doc(target['id'] ?? '')
        .update(target);
  }

  Future<void> deleteImage(String imageFileUrl) async {
    var fileUrl = Uri.decodeFull(Path.basename(imageFileUrl))
        .replaceAll(new RegExp(r'(\?alt).*'), '');

    final Reference firebaseStorageRef =
    FirebaseStorage.instance.ref().child(fileUrl);
    await firebaseStorageRef.delete();
  }

  undo(User tinderUser) async {
    await firestore
        .collection(SWIPES)
        .where('user1', isEqualTo: MyAppState.currentUser.userID)
        .where('user2', isEqualTo: tinderUser.userID)
        .get()
        .then((value) async {
      if (value.docs.isNotEmpty) {
        await firestore
            .collection(SWIPES)
            .doc(value.docs.first.id)
            .delete();
      }
    });
  }

  closeTinderStream() {
    tinderCardsStreamController.close();
  }

  void updateCardStream(List<User> data) {
    tinderCardsStreamController.add(data);
  }

  Future<bool> incrementSwipe() async {
    DocumentReference documentReference = firestore.collection(SWIPE_COUNT)
        .doc(MyAppState.currentUser.userID);
    DocumentSnapshot validationDocumentSnapshot = await documentReference.get();
    if (validationDocumentSnapshot != null &&
        validationDocumentSnapshot.exists) {
      if ((validationDocumentSnapshot['count'] ?? 1) < 10) {
        await firestore.doc(documentReference.path).update
          ({'count': validationDocumentSnapshot['count'] + 1});
        return true;
      } else {
        return _shouldResetCounter(validationDocumentSnapshot);
      }
    } else {
      await firestore.doc(documentReference.path).set(SwipeCounter(
          authorID: MyAppState.currentUser.userID,
          createdAt: Timestamp.now(),
          count: 1)
          .toJson());
      return true;
    }
  }

  Future<Url> uploadAudioFile(File file, BuildContext context) async {
    showProgress(context, 'Uploading Audio...', false);
    var uniqueID = Uuid().v4();
    Reference upload = storage.child("audio/$uniqueID.mp3");
    SettableMetadata metadata = SettableMetadata(contentType: 'audio');
    UploadTask uploadTask = upload.putFile(file, metadata);
    uploadTask.snapshotEvents.listen((event) {
      updateProgress(
          'Uploading Audio ${(event.bytesTransferred.toDouble() / 1000)
              .toStringAsFixed(2)} /'
              '${(event.totalBytes.toDouble() / 1000).toStringAsFixed(2)} '
              'KB');
    });
    uploadTask.whenComplete(() {}).catchError((onError) {
      print((onError as PlatformException).message);
    });
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    hideProgress();
    return Url(mime: metaData.contentType, url: downloadUrl.toString());
  }

  Future<bool> _shouldResetCounter(DocumentSnapshot documentSnapshot) async {
    SwipeCounter counter = SwipeCounter.fromJson(documentSnapshot.data());
    DateTime now = new DateTime.now();
    DateTime from = DateTime.fromMillisecondsSinceEpoch(
        counter.createdAt.millisecondsSinceEpoch);
    Duration diff = now.difference(from);
    if (diff.inDays > 0) {
      counter.count = 1;
      counter.createdAt = Timestamp.now();
      await firestore.collection(SWIPE_COUNT).doc(counter.authorID)
          .update(counter.toJson());
      return true;
    } else {
      return false;
    }
  }

}

sendNotification(String token, String title, String body) async {
  await http.post(
    'https://fcm.googleapis.com/fcm/send',
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'key=$SERVER_KEY',
    },
    body: jsonEncode(
      <String, dynamic>{
        'notification': <String, dynamic>{'body': body, 'title': title},
        'priority': 'high',
        'data': <String, dynamic>{
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'id': '1',
          'status': 'done'
        },
        'to': token
      },
    ),
  );
}
