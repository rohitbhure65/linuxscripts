import 'package:get/get.dart';

/// GetX template - ${FEATURE_NAME} controller
class ${FEATURE_NAME}Controller extends GetxController {
  // Observable state
  final status = ${FEATURE_NAME}Status.initial.obs;
  final data = Rxn<${FEATURE_NAME}Model>();
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = ${FEATURE_NAME}Status.loading;
    try {
      // TODO: Load data
      status.value = ${FEATURE_NAME}Status.loaded;
    } catch (e) {
      error.value = e.toString();
      status.value = ${FEATURE_NAME}Status.failure;
    }
  }

  Future<void> save(dynamic data) async {
    status.value = ${FEATURE_NAME}Status.saving;
    try {
      // TODO: Save data
      status.value = ${FEATURE_NAME}Status.saved;
    } catch (e) {
      error.value = e.toString();
      status.value = ${FEATURE_NAME}Status.failure;
    }
  }
}

/// Status enum
enum ${FEATURE_NAME}Status {
  initial,
  loading,
  loaded,
  saving,
  saved,
  failure,
}

/// Model
class ${FEATURE_NAME}Model {
  const ${FEATURE_NAME}Model({this.id, this.name});
  final String? id;
  final String? name;
}