class DaredisException implements Exception {
  final String message;

  DaredisException([this.message = 'Daredis error']);

  @override
  String toString() => '${runtimeType.toString()}: $message';
}

class DaredisConnectionException extends DaredisException {
  DaredisConnectionException([super.message = 'Connection error']);
}

class DaredisTimeoutException extends DaredisException {
  DaredisTimeoutException([super.message = 'Command timed out']);
}

class DaredisNetworkException extends DaredisException {
  DaredisNetworkException([super.message = 'Network error']);
}

class DaredisCommandException extends DaredisException {
  DaredisCommandException([super.message = 'Command error']);
}

class DaredisClusterException extends DaredisException {
  DaredisClusterException([super.message = 'Cluster error']);
}

class RespException extends DaredisException {
  RespException(super.message);
}

class IncompleteDataException extends DaredisException {
  IncompleteDataException([super.message = 'Incomplete RESP data']);
}

class DaredisStateException extends DaredisException {
  DaredisStateException([super.message = 'Invalid client state']);
}

class DaredisArgumentException extends DaredisException {
  DaredisArgumentException([super.message = 'Invalid argument']);
}

class DaredisUnsupportedException extends DaredisException {
  DaredisUnsupportedException([super.message = 'Unsupported operation']);
}

class DaredisProtocolException extends DaredisException {
  DaredisProtocolException([super.message = 'Unexpected response']);
}
