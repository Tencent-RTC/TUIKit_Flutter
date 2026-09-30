// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   Define @ AtomicXCore
// Function: Basic type definitions, including error handling, callback types and state management.

/// Callback for experimental event subscription, delivering roomID and JSON payload.
typedef ExperimentalEventCallback = void Function(String roomID, String jsonStr);

/// Callback for experimental API invocation completion, delivering the error code, message and the JSON string returned by the engine.
typedef ExperimentalAPICallback = void Function(int code, String message, String jsonStr);

/// Completion callback interface.
///
/// Interface for asynchronous operation result callbacks. Calls onSuccess on success, onFailure on failure.
///
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | ``errorCode`` | `int` | Error code |
/// | ``errorMessage`` | `String?` | Error message description |
/// | ``isSuccess`` | `bool` | Whether successful |
class CompletionHandler {
  /// Error code.
  int errorCode = 0;

  /// Error message description.
  String? errorMessage;

  /// Whether successful.
  bool get isSuccess => errorCode == 0;

  CompletionHandler();
}
