import 'User.dart';

class ContactModel {
  ContactType type = ContactType.UNKNOWN;
  User user = User();

  ContactModel({this.type, this.user});
}

enum ContactType { FRIEND, PENDING, BLOCKED, UNKNOWN, ACCEPT }
