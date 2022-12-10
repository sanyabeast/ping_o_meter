import 'package:localstore/localstore.dart';

bool persistenceInited = false;

class PersistentModule {
  Localstore get db {
    return Localstore.instance;
  }

  notifyChanged({bool save = false}) {
    if (save) {
      saveState();
    }
    onChanged();
  }

  onChanged() {}
  loadState() async {}
  saveState() {}
  saveData(Map<String, dynamic> data) =>
      db.collection("settings").doc(runtimeType.toString()).set(data);
  Future<Map<String, dynamic>?> loadSavedData() async {
    return await db.collection("settings").doc(runtimeType.toString()).get();
  }
}
