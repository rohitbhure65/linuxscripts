import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod template - ${FEATURE_NAME} provider
class ${FEATURE_NAME}Notifier extends AsyncNotifier<${FEATURE_NAME}Model> {
  @override
  Future<${FEATURE_NAME}Model> build() async {
    // TODO: Load initial data
    return ${FEATURE_NAME}Model();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> save(${FEATURE_NAME}Model data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _save(data));
  }

  Future<${FEATURE_NAME}Model> _fetch() async {
    // TODO: Implement fetch
    return ${FEATURE_NAME}Model();
  }

  Future<${FEATURE_NAME}Model> _save(${FEATURE_NAME}Model data) async {
    // TODO: Implement save
    return data;
  }
}

/// Provider
final ${FEATURE_NAME}Provider = AsyncNotifierProvider<${FEATURE_NAME}Notifier, ${FEATURE_NAME}Model>(
  ${FEATURE_NAME}Notifier.new,
);

/// Model
class ${FEATURE_NAME}Model {
  const ${FEATURE_NAME}Model({this.id, this.name});
  final String? id;
  final String? name;
}