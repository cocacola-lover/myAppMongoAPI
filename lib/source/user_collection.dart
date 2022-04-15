part of 'mongo_collection.dart';

final _userCollectionName = "users";
final _usersNameField = "name";
final _usersPasswordField = "password";
final _usersCollectionCorrupted = "Users collection has been corrupted";

class UserCollection extends MongoCollection {
  UserCollection(Db db) : super(db, _userCollectionName);

  @override
  void _corruptedException() => throw AppException(_usersCollectionCorrupted);

  @override
  bool checkTemplate(Map<String, dynamic> map) {
    bool nameCheck = false, passwordCheck = false;

    for (final pair in map.entries) {
      // _id field Check
      if (pair.key == _idFieldName) {
        continue;
      } else if (pair.key == _usersNameField) {
        // name field Check
        try {
          pair.value as String;
        } on TypeError {
          return false;
        }
        nameCheck = true;
        continue;
      } else if (pair.key == _usersPasswordField) {
        // password field Check
        try {
          pair.value as String;
        } on TypeError {
          return false;
        }
        passwordCheck = true;
        continue;
      }
      return false;
    }
    return (passwordCheck && nameCheck);
  }

  Future<bool> existsName(String name) async =>
      await _existsByField(_usersNameField, name);

  Future<bool> deleteByName(String name) async =>
      await _deleteByField(_usersNameField, name);

  @override
  Future<bool> checkNotClone(Map<String, dynamic> map) async {
    if (!checkTemplate(map)) throw AppException(_wrongJsonMessage);

    if (await existsName(map[_usersNameField])) return false;
    return true;
  }

  Future<bool> addUser(String name, String password) async =>
      addJson({_usersNameField: name, _usersPasswordField: password});

  Future<bool> changeName(String pastname, String newName) async =>
      _updateFieldWhere(_usersNameField, pastname, _usersNameField, newName);

  Future<String?> findNameById(ObjectId id) async {
    Map<String, dynamic>? map = await findById(id);
    if (map == null) return null;
    return map[_usersNameField];
  }

  Future<String?> findNameByIdModern(ObjectId id) async {
    return await _findFieldByField(_idFieldName, id, _usersNameField)
        as String?;
  }

  Future<String?> findPasswordByName(String name) async {
    return await _findFieldByField(_usersNameField, name, _usersPasswordField)
        as String?;
  }
}
