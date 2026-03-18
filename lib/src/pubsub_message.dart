/// A decoded Redis Pub/Sub frame.
class PubSubMessage {
  /// Redis Pub/Sub frame type such as `message`, `pmessage`, or `subscribe`.
  final String type;

  /// The channel associated with the frame, when present.
  final String? channel;

  /// The subscription pattern associated with the frame, when present.
  final String? pattern;

  /// The message payload for data frames.
  final dynamic payload;

  /// The active subscription count reported by subscription event frames.
  final int? subscriptionCount;

  /// Creates a Pub/Sub message wrapper from a decoded frame.
  PubSubMessage(
    this.type, {
    this.channel,
    this.pattern,
    this.payload,
    this.subscriptionCount,
  });

  /// Whether this frame is a subscription acknowledgement event.
  bool get isSubscriptionEvent =>
      type == 'subscribe' ||
      type == 'psubscribe' ||
      type == 'unsubscribe' ||
      type == 'punsubscribe';

  /// Whether this frame carries published application data.
  bool get isDataMessage => type == 'message' || type == 'pmessage';

  @override
  String toString() =>
      'PubSubMessage($type, channel: $channel, pattern: $pattern, payload: $payload, count: $subscriptionCount)';
}
