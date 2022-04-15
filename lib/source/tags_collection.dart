part of 'mongo_collection.dart';

final _tagsCollectionCorrupted = "Tags collection has been corrupted";
final _tagsCollectionWrongJsonInLinking =
    "Json has not been checked in checkTemplate";
final _tagsCollectionName = "tags";
final _tagNameField = "tag";
final _tagGroupIdField = "groupId";
final _tagsCollectionUnknownId = "Unknown groupName id";
final _tagsCollectionUnknownName = "Unknown groupName";

class TagsCollection extends MongoCollection {
  final TagsGroupsCollection groupsCollection;

  TagsCollection(Db db)
      : groupsCollection = TagsGroupsCollection(db),
        super(db, _tagsCollectionName);

  @override
  bool checkTemplate(Map<String, dynamic> map) {
    bool nameCheck = false, groupNameCheck = false;

    for (final pair in map.entries) {
      // _id field Check
      if (pair.key == _idFieldName) {
        continue;
      } else if (pair.key == _tagGroupIdField) {
        // groupId field Check
        try {
          pair.value as ObjectId;
        } on TypeError {
          return false;
        }
        groupNameCheck = true;
        continue;
      } else if (pair.key == _tagNameField) {
        // name field Check
        try {
          pair.value as String;
        } on TypeError {
          return false;
        }
        nameCheck = true;
        continue;
      }
      return false;
    }
    return (groupNameCheck && nameCheck);
  }

  @override
  Future<bool> checkNotClone(Map<String, dynamic> map) async {
    if (!checkTemplate(map)) throw AppException(_wrongJsonMessage);

    if (await existsName(map[_tagNameField])) return false;
    return true;
  }

  @override
  Future<Map<String, dynamic>> _extraAction(Map<String, dynamic> map) async {
    return await linkToGroup(map);
  }

  @override
  void _corruptedException() => throw AppException(_tagsCollectionCorrupted);

  Future<bool> existsName(String name) async =>
      await _existsByField(_tagNameField, name);

  Future<bool> deleteByName(String name) async =>
      await _deleteByField(_tagNameField, name);

  Future<bool> addNameToGroup(String name, String groupName) async {
    ObjectId? groupId = await groupsCollection.findIdByGroupName(groupName);
    if (groupId == null) throw AppException(_tagsCollectionUnknownName);

    return await addJson({_tagNameField: name, _tagGroupIdField: groupId});
  }

  Future<ObjectId?> findIdbyName(String name) async {
    if (!(await existsName(name))) return null;

    Map<String, dynamic>? json = await _findByField(_tagNameField, name);
    if (json == null) return null;
    return json[_idFieldName];
  }

  Future<Map<String, dynamic>> linkToGroup(Map<String, dynamic> map) async {
    final ObjectId? id = map[_tagGroupIdField];
    if (id == null) throw AppException(_tagsCollectionWrongJsonInLinking);

    final String? groupName = await groupsCollection.findGroupNameById(id);
    if (groupName == null) throw AppException(_tagsCollectionUnknownId);
    map[_tagsGroupsNameField] = groupName;
    //A little cleaning to the output:
    map.remove(_tagGroupIdField);
    //map.remove(_idFieldName);

    return map;
  }
}



/*
class TagsCollection extends MongoCollection {
//Constructors:

  TagsCollection({required String user, required String password})
      : super(
            user: user, password: password, collectionName: tagsCollectionName);

  static Future<TagsCollection> create(
      {required String user, required String password}) async {
    var ans = TagsCollection(user: user, password: password);
    await ans.open();
    return ans;
  }

  Future<bool> isTagHere(String name) async {
    if (await findObjectId(name) != null) return true;
    return false;
  }

  Future<ObjectId?> findObjectId(String name) async {
    if (!isConnected()) throw AppException(notConnectedMessage);
    Map<String, dynamic>? call = await _collection.findOne(where
        .eq(tagCollectionTagKey, name)
        .excludeFields([tagCollectionTagKey]));
    if (call == null) return null;

    ObjectId i;
    try {
      i = forceCast<ObjectId>(call[idFieldName]);
    } on MyCastError {
      throw AppException(tagsCollectionCorrupted);
    }
    return i;
  }

  Future<List<String>> findAllTags() async {
    if (!isConnected()) throw AppException(notConnectedMessage);

    List<Map<String, dynamic>> preAns = await _collection
        .find(where.excludeFields([idFieldName]))
        .toList(); // Получаем из базы данных Json-ы

    var ans = <String>[];
    for (var item in preAns) {
      // Фильтруем просто в tag
      String i;
      try {
        i = forceCast<String>(item[tagCollectionTagKey]);
      } on MyCastError {
        throw AppException(tagsCollectionCorrupted);
      }
      ans.add(i);
    }
    return ans;
  }

  Future<bool> addTag(String name) async {
    if (await isTagHere(name)) return true;

    var result = await _collection.insertOne({tagCollectionTagKey: name});
    if (result.ok == 1) return true;
    return false;
  }

  Future<bool> deleteTag(String name) async {
    if (!(await isTagHere(name))) return true;

    var result = await _collection.deleteOne({tagCollectionTagKey: name});
    if (result.ok == 1) return true;
    return false;
  }

  Future<String?> findTagById(ObjectId id) async {
    if (!isConnected()) throw AppException(notConnectedMessage);
    Map<String, dynamic>? call = await _collection
        .findOne(where.eq(idFieldName, id).excludeFields([idFieldName]));
    if (call == null) return null;

    String i;
    try {
      i = forceCast<String>(call[tagCollectionTagKey]);
    } on MyCastError {
      throw AppException(tagsCollectionCorrupted);
    }
    return i;
  }
}*/
