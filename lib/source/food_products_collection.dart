part of 'mongo_collection.dart';

final _foodProductsCollectionName = "foodProducts";

// rateFields:
final _rateUserField = "user";
final _rateRateField = "rate";
final _rateCommentField = "comment";
// FoodProductsFields:
final _foodProductNameField = "name";
final _foodProductRateField = "rate";
final _foodProductTagsField = "tags";
// Exception Messages:
final _foodProductsCollectionWrongJsonInLinking =
    "Json has not been checked in checkTemplate";
final _foodProductsCollectionUnknownUserInLinking = "Unknown user in linking";
final _foodProductsCollectionUnknownTagInLinking = "Unknown tag in linking";
final _foodProductsRateDoNotExist = "Rate does not exist";
final _foodProductsProductDoesNotExist = "Product does not exist";
final _foodProductsTagDoesNotExist = "Tag does not exist";

class FoodProductsCollection extends MongoCollection {
  final TagsCollection _tagsCollection;
  final UserCollection _userCollection;
  final ObjectId _myId;

  FoodProductsCollection(Db db, TagsCollection tagsCollection,
      UserCollection userCollection, ObjectId myId)
      : _tagsCollection = tagsCollection,
        _userCollection = userCollection,
        _myId = myId,
        super(db, _foodProductsCollectionName);

  bool _checkRates(List<dynamic> list) {
    for (final map in list) {
      if (map is! Map) {
        return false;
      }
      bool userCheck = false, rateCheck = false;
      for (final pair in map.entries) {
        if (pair.key == _rateUserField) {
          if (pair.value is ObjectId) {
            userCheck = true;
          } else {
            return false;
          }
        } else if (pair.key == _rateRateField) {
          if (pair.value is int) {
            rateCheck = true;
          } else {
            return false;
          }
        } else if (pair.key == _rateCommentField) {
          if (pair.value is String) {
            rateCheck = true;
          } else {
            return false;
          }
        } else {
          return false;
        }
      }
      if (!(userCheck && rateCheck)) return false;
    }
    return true;
  }

  bool _checkTags(List<dynamic> list) {
    for (final object in list) {
      if (object is! ObjectId) return false;
    }
    return true;
  }

  @override
  bool checkTemplate(Map<String, dynamic> map) {
    bool nameCheck = false, rateCheck = false, tagsCheck = false;
    for (final pair in map.entries) {
      if (pair.key == _idFieldName) {
        continue;
      } else if (pair.key == _foodProductNameField) {
        if (pair.value is String) {
          nameCheck = true;
        } else {
          return false;
        }
      } else if (pair.key == _foodProductRateField) {
        if (pair.value is List) {
          if (_checkRates(pair.value)) {
            rateCheck = true;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } else if (pair.key == _foodProductTagsField) {
        if (pair.value is List) {
          if (_checkTags(pair.value)) {
            tagsCheck = true;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } else {
        return false;
      }
    }
    return nameCheck && tagsCheck && rateCheck;
  }

  Future<bool> existsName(String name) async =>
      await _existsByField(_foodProductNameField, name);

  Future<bool> deleteByName(String name) async =>
      await _deleteByField(_foodProductNameField, name);

  @override
  Future<bool> checkNotClone(Map<String, dynamic> map) async {
    if (!checkTemplate(map)) throw AppException(_wrongJsonMessage);

    if (await existsName(map[_foodProductNameField])) return false;
    return true;
  }

  void linkingException() =>
      throw AppException(_foodProductsCollectionWrongJsonInLinking);

  Future<List<dynamic>> linkRates(List<dynamic> list) async {
    for (int i = 0; i < list.length; i++) {
      ObjectId? id = list[i][_rateUserField];
      if (id == null) {
        linkingException();
        return list;
      }

      String? userName = await _userCollection.findNameById(id);
      if (userName == null) {
        throw AppException(_foodProductsCollectionUnknownUserInLinking);
      }
      list[i][_rateUserField] = userName;
    }
    return list;
  }

  Future<List<dynamic>> linkTags(List<dynamic> list) async {
    for (int i = 0; i < list.length; i++) {
      if (list[i] is! ObjectId) {
        linkingException();
        return list;
      }
      ObjectId id = list[i];
      Map<String, dynamic>? tag = await _tagsCollection.findById(id);
      if (tag == null) {
        throw AppException(_foodProductsCollectionUnknownTagInLinking);
      }
      list[i] = tag;
    }
    return list;
  }

  Future<Map<String, dynamic>> linkToGroup(Map<String, dynamic> map) async {
    List<dynamic>? rateList = map[_foodProductRateField];
    if (rateList == null) {
      linkingException();
      return map;
    }
    map[_foodProductRateField] = await linkRates(rateList);

    List<dynamic>? tagsList = map[_foodProductTagsField];
    if (tagsList == null) {
      linkingException();
      return map;
    }
    map[_foodProductTagsField] = await linkTags(tagsList);
    return map;
  }

  @override
  Future<Map<String, dynamic>> _extraAction(Map<String, dynamic> map) async =>
      linkToGroup(map);

  Future<bool> renameProductByName(String oldName, String newName) async {
    if (!await existsName(oldName)) {
      throw AppException(_foodProductsProductDoesNotExist);
    }
    return await _updateFieldWhere(
        _foodProductNameField, oldName, _foodProductNameField, newName);
  }

  Future<bool> _createRate(String productName, int intRate,
      [String comment = ""]) async {
    if (!await existsName(productName)) {
      throw AppException(_foodProductsProductDoesNotExist);
    }

    dynamic rate = <String, dynamic>{};
    rate[_rateUserField] = _myId;
    rate[_rateRateField] = intRate;
    if (comment != "") rate[_rateCommentField] = comment;

    var result = await _collection.updateOne(
        where.eq(_foodProductNameField, productName),
        ModifierBuilder().push(_foodProductRateField, rate));

    if (result.isFailure) return false;
    return true;
  }

  Future<bool> _checkRateExistense(String productName) async {
    if (!await existsName(productName)) {
      throw AppException(_foodProductsProductDoesNotExist);
    }

    return await _collection.findOne(where
            .eq(_foodProductNameField, productName)
            .eq("$_foodProductRateField.$_rateUserField", _myId)) !=
        null;
  }

  Future<bool> setMyRate(String productName, int rate) async {
    if (await _checkRateExistense(productName)) {
      return await _createRate(productName, rate);
    }
    var result = await _collection.updateOne(
      where
          .eq(_foodProductNameField, productName)
          .eq("$_foodProductRateField.$_rateUserField", _myId),
      ModifierBuilder().set('$_foodProductRateField.\$.$_rateRateField', rate),
    );
    if (result.isFailure) return false;
    return true;
  }

  Future<bool> setMyComment(String productName, String comment) async {
    if (!(await _checkRateExistense(productName))) {
      throw AppException(_foodProductsRateDoNotExist);
    }

    var result = await _collection.updateOne(
      where
          .eq(_foodProductNameField, productName)
          .eq("$_foodProductRateField.$_rateUserField", _myId),
      ModifierBuilder()
          .set('$_foodProductRateField.\$.$_rateCommentField', comment),
    );
    if (result.isFailure) return false;
    return true;
  }

  Future<bool> deleteMyComment(String productName) async {
    if (!(await _checkRateExistense(productName))) {
      throw AppException(_foodProductsRateDoNotExist);
    }

    var result = await _collection.updateOne(
      where
          .eq(_foodProductNameField, productName)
          .eq("$_foodProductRateField.$_rateUserField", _myId),
      ModifierBuilder().unset('$_foodProductRateField.\$.$_rateCommentField'),
    );
    if (result.isFailure) return false;
    return true;
  }

  Future<bool> deleteMyRate(String productName) async {
    if (!(await _checkRateExistense(productName))) {
      throw AppException(_foodProductsRateDoNotExist);
    }

    var result = await _collection.updateOne(
      where
          .eq(_foodProductNameField, productName)
          .eq("$_foodProductRateField.$_rateUserField", _myId),
      ModifierBuilder().pull(_foodProductRateField, {_rateUserField: _myId}),
    );
    if (result.isFailure) return false;
    return true;
  }

  Future<bool> addTagById(String productName, ObjectId id) async {
    if (!await existsName(productName)) {
      throw AppException(_foodProductsProductDoesNotExist);
    }

    var result = await _collection.updateOne(
      where.eq(_foodProductNameField, productName),
      ModifierBuilder().push(_foodProductTagsField, id),
    );
    if (result.isFailure) return false;
    return true;
  }

  Future<bool> addTagByName(String productName, String tag) async {
    ObjectId? id = await _tagsCollection.findIdbyName(tag);
    if (id == null) throw AppException(_foodProductsTagDoesNotExist);
    return await addTagById(productName, id);
  }

  Future<bool> deleteTagById(String productName, ObjectId id) async {
    if (!await existsName(productName)) {
      throw AppException(_foodProductsProductDoesNotExist);
    }

    var result = await _collection.updateOne(
      where.eq(_foodProductNameField, productName),
      ModifierBuilder().pull(_foodProductTagsField, id),
    );
    if (result.isFailure) return false;
    return true;
  }

  Future<bool> deleteTagByName(String productName, String tag) async {
    ObjectId? id = await _tagsCollection.findIdbyName(tag);
    if (id == null) throw AppException(_foodProductsTagDoesNotExist);
    return await deleteTagById(productName, id);
  }

  Future<List<Map<String, dynamic>>> findFiltered(
      {required String stringFilter, required List<ObjectId> tags}) async {
    if (!isConnected()) throw AppException(_notConnectedMessage);

    var th =
        where.match(_foodProductNameField, stringFilter, caseInsensitive: true);

    for (final tag in tags) {
      th = th.eq(_foodProductTagsField, tag);
    }

    List<Map<String, dynamic>> returnedList =
        await _collection.find(th).toList();

    for (int i = 0; i < returnedList.length; i++) {
      if (!checkTemplate(returnedList[i])) _corruptedException();
      returnedList[i] = await _extraAction(returnedList[i]);
    }
    return returnedList;
  }
}

class ProductBuilder {
  String name = "";
  final List<dynamic> _rate = [];
  final List<dynamic> _tags = [];

  void setName(String nameN) => name = nameN;
  void addRate(ObjectId user, int rate, [String comment = ""]) {
    Map<String, dynamic> map = <String, dynamic>{};

    map[_rateUserField] = user;
    map[_rateRateField] = rate;
    if (comment != "") map[_rateCommentField] = comment;

    _rate.add(map);
  }

  void addTag(ObjectId tag) {
    _tags.add(tag);
  }

  Map<String, dynamic> returnJson() {
    return {
      _foodProductNameField: name,
      _foodProductRateField: _rate,
      _foodProductTagsField: _tags
    };
  }
}
