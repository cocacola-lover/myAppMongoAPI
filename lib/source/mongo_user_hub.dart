import 'package:my_app_mongo_api/source/mongo_collection.dart';
import 'package:mongo_dart/mongo_dart.dart';

class UserHubApp {
  final Db _db;
  late final UserCollection _users;

  UserCollection get users => _users;

  // ignore: non_constant_identifier_names
  UserHubApp({required Db db}) : _db = db {
    _users = UserCollection(_db);
  }

  Future open() async => await _db.open();
  void close() => _db.close();
  bool isConnected() => _db.isConnected;

  static Future<UserHubApp> create(
      // ignore: non_constant_identifier_names
      {required String URL}) async {
    var db = await Db.create(URL);
    var hub = UserHubApp(db: db);
    return hub;
  }
}
