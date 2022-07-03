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

  Future<List<String>> sortGroups() async {
    List<Map<String, dynamic>> groups = await groupsCollection.findAll();
    List<String> ans = [];

    for (var value in groups) {
      ans.add((value[_idFieldName] as ObjectId).$oid);
    }
    ans.sort();
    for (var value in groups) {
      ans[ans.indexOf((value[_idFieldName] as ObjectId).$oid)] =
          value[_tagsGroupsNameField];
    }

    return ans;
  }
}
