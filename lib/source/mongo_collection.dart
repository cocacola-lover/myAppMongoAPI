library my_app_collection;

import 'package:mongo_dart/mongo_dart.dart'
    show Db, DbCollection, ObjectId, where, modify, ModifierBuilder;
//import 'force_cast.dart';

//part 'mongo_collection_hub.dart';
part 'tags_collection.dart';
part 'tags_groups_collection.dart';
part 'user_collection.dart';
part 'food_products_collection.dart';

final _notConnectedMessage = "Collection is not connected";
final _generalCollectionCorrupted = "Collection has been corrupted";
final _idFieldName = "_id";
final _additionFailedMessage = "Addition Failed";
final _deleteFailedMessage = "Delete Failed";
//final _updateFailedMessage = "Update Failed";
final _wrongJsonMessage = "Wrong Json contructed";

class AppException implements Exception {
  final String exceptionMessage;
  AppException(this.exceptionMessage);

  @override
  String toString() {
    return exceptionMessage;
  }
}

class MongoCollection {
  final DbCollection _collection;
  final Db _db;

  // creating

  MongoCollection(Db db, String collectionName)
      : _db = db,
        _collection = db.collection(collectionName);

  bool isConnected() => _db.isConnected;
  void _corruptedException() => throw AppException(_generalCollectionCorrupted);
  bool checkTemplate(Map<String, dynamic> map) => true;
  Future<bool> checkNotClone(Map<String, dynamic> map) async => true;
  Future<Map<String, dynamic>> _extraAction(Map<String, dynamic> map) async =>
      map;

  // managing
  Future<List<Map<String, dynamic>>> findAll() async {
    if (!isConnected()) throw AppException(_notConnectedMessage);
    List<Map<String, dynamic>> returnedList = await _collection.find().toList();

    for (int i = 0; i < returnedList.length; i++) {
      if (!checkTemplate(returnedList[i])) _corruptedException();
      returnedList[i] = await _extraAction(returnedList[i]);
    }
    return returnedList;
  }

  Future<Map<String, dynamic>?> findById(ObjectId id) async {
    return await _findByField(_idFieldName, id);
  }

  Future<Map<String, dynamic>?> _findByField(
      String fieldName, dynamic fieldValue) async {
    if (!isConnected()) throw AppException(_notConnectedMessage);
    Map<String, dynamic>? returnedJson =
        await _collection.findOne(where.eq(fieldName, fieldValue));
    if (returnedJson == null) return null;

    if (!checkTemplate(returnedJson)) _corruptedException();
    return await _extraAction(returnedJson);
  }

  Future<dynamic> _findFieldByField(
      String fieldName, dynamic fieldValue, String searchName) async {
    if (!isConnected()) throw AppException(_notConnectedMessage);
    Map<String, dynamic>? returnedJson = await _collection
        .findOne(where.eq(fieldName, fieldValue).fields([searchName]));
    if (returnedJson == null) return null;

    if (returnedJson[searchName] == null) _corruptedException();
    return returnedJson[searchName];
  }

  Future<int> count() async {
    if (!isConnected()) throw AppException(_notConnectedMessage);
    return await _collection.count();
  }

  Future<bool> existsId(ObjectId id) async {
    return await _existsByField(_idFieldName, id);
  }

  Future<bool> _existsByField(String fieldName, dynamic fieldValue) async {
    if (!isConnected()) throw AppException(_notConnectedMessage);

    if (await _collection.findOne(where.eq(fieldName, fieldValue)) == null) {
      return false;
    }
    return true;
  }

  Future<bool> _deleteByField(String fieldName, dynamic fieldValue) async {
    if (!(await _existsByField(fieldName, fieldValue))) return false;

    var result = await _collection.deleteOne({fieldName: fieldValue});
    if (result.ok != 1) throw AppException(_deleteFailedMessage);
    return true;
  }

  Future<bool> deleteByID(ObjectId id) async {
    return await _deleteByField(_idFieldName, id);
  }

  Future<bool> addJson(Map<String, dynamic> json) async {
    if (!isConnected()) throw AppException(_notConnectedMessage);
    if (!checkTemplate(json)) throw AppException(_wrongJsonMessage);
    if (!(await checkNotClone(json))) return false;

    var result = await _collection.insertOne(json);
    if (result.isFailure) throw AppException(_additionFailedMessage);
    return true;
  }

  Future<bool> _updateFieldWhere(
      String eqName, dynamic eqField, String chName, dynamic chField) async {
    var result = await _collection.updateOne(
        where.eq(eqName, eqField), modify.set(chName, chField));
    if (result.isFailure) return false;
    return true;
  }
}
