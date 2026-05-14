import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC template - ${FEATURE_NAME} BLoC
class ${FEATURE_NAME}Bloc extends Bloc<${FEATURE_NAME}Event, ${FEATURE_NAME}State> {
  ${FEATURE_NAME}Bloc() : super(${FEATURE_NAME}State()) {
    on<${FEATURE_NAME}LoadRequested>(_onLoad);
    on<${FEATURE_NAME}SaveRequested>(_onSave);
  }

  Future<void> _onLoad(${FEATURE_NAME}LoadRequested event, Emitter<${FEATURE_NAME}State> emit) async {
    emit(state.copyWith(status: ${FEATURE_NAME}Status.loading));
    try {
      // TODO: Load data
      emit(state.copyWith(status: ${FEATURE_NAME}Status.loaded));
    } catch (e) {
      emit(state.copyWith(status: ${FEATURE_NAME}Status.failure, error: e.toString()));
    }
  }

  Future<void> _onSave(${FEATURE_NAME}SaveRequested event, Emitter<${FEATURE_NAME}State> emit) async {
    emit(state.copyWith(status: ${FEATURE_NAME}Status.saving));
    try {
      // TODO: Save data
      emit(state.copyWith(status: ${FEATURE_NAME}Status.saved));
    } catch (e) {
      emit(state.copyWith(status: ${FEATURE_NAME}Status.failure, error: e.toString()));
    }
  }
}

/// Events
abstract class ${FEATURE_NAME}Event {
  const ${FEATURE_NAME}Event();
}

class ${FEATURE_NAME}LoadRequested extends ${FEATURE_NAME}Event {
  const ${FEATURE_NAME}LoadRequested();
}

class ${FEATURE_NAME}SaveRequested extends ${FEATURE_NAME}Event {
  const ${FEATURE_NAME}SaveRequested({required this.data});
  final dynamic data;
}

/// State
class ${FEATURE_NAME}State {
  const ${FEATURE_NAME}State({
    this.status = ${FEATURE_NAME}Status.initial,
    this.data,
    this.error,
  });

  final ${FEATURE_NAME}Status status;
  final dynamic data;
  final String? error;

  ${FEATURE_NAME}State copyWith({
    ${FEATURE_NAME}Status? status,
    dynamic data,
    String? error,
  }) =>
      ${FEATURE_NAME}State(
        status: status ?? this.status,
        data: data ?? this.data,
        error: error ?? this.error,
      );
}

enum ${FEATURE_NAME}Status {
  initial,
  loading,
  loaded,
  saving,
  saved,
  failure,
}