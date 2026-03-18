/// Base exception type for all package-defined failures.
class DaredisException implements Exception {
  /// Human-readable error message.
  final String message;

  DaredisException([this.message = 'Daredis error']);

  @override
  String toString() => '${runtimeType.toString()}: $message';
}

/// Thrown when a connection cannot be opened or used.
class DaredisConnectionException extends DaredisException {
  DaredisConnectionException([super.message = 'Connection error']);
}

/// Thrown when a command exceeds its configured timeout.
class DaredisTimeoutException extends DaredisException {
  DaredisTimeoutException([super.message = 'Command timed out']);
}

/// Thrown for low-level socket and transport failures.
class DaredisNetworkException extends DaredisException {
  DaredisNetworkException([super.message = 'Network error']);
}

/// Thrown when Redis returns an error reply for a command.
class DaredisCommandException extends DaredisException {
  DaredisCommandException([super.message = 'Command error']);
}

/// Thrown for cluster topology and routing failures.
class DaredisClusterException extends DaredisException {
  DaredisClusterException([super.message = 'Cluster error']);
}

/// Thrown for malformed or unsupported RESP payloads.
class RespException extends DaredisException {
  RespException(super.message);
}

/// Signals that more bytes are required to decode a full RESP frame.
class IncompleteDataException extends DaredisException {
  IncompleteDataException([super.message = 'Incomplete RESP data']);
}

/// Thrown when a client or session is used in an invalid lifecycle state.
class DaredisStateException extends DaredisException {
  DaredisStateException([super.message = 'Invalid client state']);
}

/// Thrown when method arguments are invalid or inconsistent.
class DaredisArgumentException extends DaredisException {
  DaredisArgumentException([super.message = 'Invalid argument']);
}

/// Thrown when an operation is intentionally unsupported by a client type.
class DaredisUnsupportedException extends DaredisException {
  DaredisUnsupportedException([super.message = 'Unsupported operation']);
}

/// Thrown when Redis replies do not match the expected protocol shape.
class DaredisProtocolException extends DaredisException {
  DaredisProtocolException([super.message = 'Unexpected response']);
}
