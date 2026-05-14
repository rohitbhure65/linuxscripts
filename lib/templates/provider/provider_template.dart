import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Provider template - ${FEATURE_NAME} notifier
class ${FEATURE_NAME}Notifier extends ChangeNotifier {
  ${FEATURE_NAME}Notifier() {
    _load();
  }

  ${FEATURE_NAME}Status _status = ${FEATURE_NAME}Status.initial;
  ${FEATURE_NAME}Model? _data;
  String? _error;

  ${FEATURE_NAME}Status get status => _status;
  ${FEATURE_NAME}Model? get data => _data;
  String? get error => _error;
  bool get isLoading => _status == ${FEATURE_NAME}Status.loading;

  Future<void> _load() async {
    _status = ${FEATURE_NAME}Status.loading;
    notifyListeners();

    try {
      // TODO: Load data
      _data = ${FEATURE_NAME}Model();
      _status = ${FEATURE_NAME}Status.loaded;
    } catch (e) {
      _error = e.toString();
      _status = ${FEATURE_NAME}Status.failure;
    }

    notifyListeners();
  }

  Future<void> save(${FEATURE_NAME}Model data) async {
    _status = ${FEATURE_NAME}Status.saving;
    notifyListeners();

    try {
      // TODO: Save data
      _data = data;
      _status = ${FEATURE_NAME}Status.saved;
    } catch (e) {
      _error = e.toString();
      _status = ${FEATURE_NAME}Status.failure;
    }

    notifyListeners();
  }

  void refresh() => _load();
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