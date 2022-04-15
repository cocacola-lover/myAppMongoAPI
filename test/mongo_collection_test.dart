import 'package:dart_application_1/my_app_api.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

// ignore: non_constant_identifier_names
final URL =
    "mongodb+srv://Admin:2xxRHKviEsp6AKq@cluster0.gdgrc.mongodb.net/app_files?retryWrites=true&w=majority";

final testCollection = "tags";
final testId = ObjectId.fromHexString("6230b3e9fe579386f0eb15ef");
final testName = "test_name";
void main() {
  group("MongoCollection", () {
    test("Testing methods", () async {
      var db = await Db.create(URL);
      await db.open();

      var coll = MongoCollection(db, testCollection);
      var list = await coll.findAll();

      var json = await coll.findById(testId);
      expect(json == null, false);
      expect(await coll.deleteByID(testId), true);

      if (json != null) expect(await coll.addJson(json), true);

      expect(list.length == (await coll.findAll()).length, true);

      db.close();
    });
    test("Test ExistsId", () async {
      var db = await Db.create(URL);
      await db.open();

      var coll = MongoCollection(db, testCollection);
      expect(await coll.existsId(testId), true);
      db.close();
    });
  });

  group("TagsGroups Collection", () {
    test("CheckTemplate", () async {
      var db = await Db.create(URL);
      await db.open();

      var coll = TagsGroupsCollection(db);
      try {
        await coll.findAll();
      } on AppException {
        expect(true, false);
      } finally {
        expect(true, true);
      }

      db.close();
    });

    test("Test methods", () async {
      var db = await Db.create(URL);
      await db.open();

      var coll = TagsGroupsCollection(db);
      if (await coll.existsName(testName)) coll.deleteByName(testName);

      var size = (await coll.findAll()).length;
      await coll.addGroupName(testName);
      expect((await coll.findAll()).length, size + 1);

      await coll.deleteByName(testName);
      expect((await coll.findAll()).length, size);

      db.close();
    });
  });
}
