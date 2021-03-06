import 'package:my_app_mongo_api/source/mongo_collection.dart'
    show UserCollection;
import 'package:mongo_dart/mongo_dart.dart'
    show Db, MongoDartError, ConnectionException;
import 'app_exception.dart';
import 'dart:io' show SocketException;

class UserHubApp {
  final Db _db;
  late final UserCollection _users;

  UserCollection get users => _users;

  // ignore: non_constant_identifier_names
  UserHubApp({required Db db}) : _db = db {
    _users = UserCollection(_db);
  }

  Future open() async {
    try {
      await _db.open();
    } on MongoDartError catch (e) {
      throw AppException(e.message);
    } on ConnectionException catch (e) {
      throw AppException(e.message);
    } on SocketException catch (e) {
      throw AppException(e.message);
    }
  }

  Future close() async => await _db.close();
  bool isConnected() => _db.isConnected;

  static Future<UserHubApp> create(
      // ignore: non_constant_identifier_names
      {required String URL}) async {
    Db db;
    try {
      db = await Db.create(URL);
    } on MongoDartError catch (e) {
      throw AppException(e.message);
    } on ConnectionException catch (e) {
      throw AppException(e.message);
    } on SocketException catch (e) {
      throw AppException(e.message);
    }
    var hub = UserHubApp(db: db);
    return hub;
  }
}
