//part of 'mongo_collection.dart';

//import 'mongo_collection.dart';
import 'package:my_app_mongo_api/source/mongo_collection.dart'
    show UserCollection, TagsCollection, FoodProductsCollection;
import 'package:mongo_dart/mongo_dart.dart'
    show Db, ObjectId, MongoDartError, ConnectionException;
import 'app_exception.dart';

class MongoHubApp {
  final Db _db;
  late final UserCollection _users;
  late final TagsCollection _tags;
  late final FoodProductsCollection _foodProducts;

  UserCollection get users => _users;
  TagsCollection get tags => _tags;
  FoodProductsCollection get foordProducts => _foodProducts;

  // ignore: non_constant_identifier_names
  MongoHubApp({required Db db, required String hexId}) : _db = db {
    _users = UserCollection(_db);
    _tags = TagsCollection(_db);
    _foodProducts =
        FoodProductsCollection(_db, tags, users, ObjectId.fromHexString(hexId));
  }

  Future open() async {
    try {
      await _db.open();
    } on MongoDartError catch (e) {
      throw AppException(e.message);
    }
  }

  void close() => _db.close();
  bool isConnected() => _db.isConnected;

  static Future<MongoHubApp> create(
      // ignore: non_constant_identifier_names
      {required String URL,
      required String hexId}) async {
    Db db;
    try {
      db = await Db.create(URL);
    } on MongoDartError catch (e) {
      throw AppException(e.message);
    } on ConnectionException catch (e) {
      throw AppException(e.message);
    }
    var hub = MongoHubApp(db: db, hexId: hexId);
    return hub;
  }
}
