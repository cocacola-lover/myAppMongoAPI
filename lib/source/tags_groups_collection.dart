part of 'mongo_collection.dart';

final _tagsGroupsCollectionName = "tagsGroups";
final _tagsGroupsNameField = "groupName";
final _tagsGroupsCorrupted = "TagsGroups has been corrupted";

class TagsGroupsCollection extends MongoCollection {
  TagsGroupsCollection(Db db) : super(db, _tagsGroupsCollectionName);

  @override
  bool checkTemplate(Map<String, dynamic> map) {
    bool groupNameCheck = false;

    for (final pair in map.entries) {
      if (pair.key == _idFieldName) {
        continue;
      } else if (pair.key == _tagsGroupsNameField) {
        try {
          pair.value as String;
        } on TypeError {
          return false;
        }
        groupNameCheck = true;
        continue;
      }
      return false;
    }
    return (groupNameCheck);
  }

  @override
  void _corruptedException() => throw AppException(_tagsGroupsCorrupted);

  Future<Map<String, dynamic>?> findByGroupName(String name) async =>
      await _findByField(_tagsGroupsNameField, name);

  Future<bool> existsName(String name) async =>
      await _existsByField(_tagsGroupsNameField, name);

  Future<bool> deleteByName(String name) async =>
      await _deleteByField(_tagsGroupsNameField, name);

  @override
  Future<bool> checkNotClone(Map<String, dynamic> map) async {
    if (!checkTemplate(map)) throw AppException(_wrongJsonMessage);

    if (await existsName(map[_tagsGroupsNameField])) return false;
    return true;
  }

  Future<bool> addGroupName(String groupName) async =>
      await addJson({_tagsGroupsNameField: groupName});

  Future<String?> findGroupNameById(ObjectId id) async {
    Map<String, dynamic>? map = await findById(id);
    if (map == null) return null;
    return map[_tagsGroupsNameField];
  }

  Future<ObjectId?> findIdByGroupName(String name) async {
    Map<String, dynamic>? map = await findByGroupName(name);
    if (map == null) return null;
    return map[_idFieldName];
  }
}
