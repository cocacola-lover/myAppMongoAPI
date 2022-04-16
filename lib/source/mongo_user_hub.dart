import 'package:my_app_mongo_api/source/mongo_collection.dart';
import 'package:mongo_dart/mongo_dart.dart';

class UserHubApp {
  final Db _db;
  late final UserCollection _users;

  UserCollection get users => _users;

  // ignore: non_constant_identifier_names
  UserHubApp({required String URL}) : _db = Db(URL) {
    _users = UserCollection(_db);
  }

  Future open() async => await _db.open();
  void close() => _db.close();
  bool isConnected() => _db.isConnected;

  static Future<UserHubApp> create(
      // ignore: non_constant_identifier_names
      {required String URL}) async {
    var db = UserHubApp(URL: URL);
    await db.open();
    return db;
  }
}
