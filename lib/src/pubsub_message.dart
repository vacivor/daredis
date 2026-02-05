class PubSubMessage {
  final String type;
  final String? channel;
  final String? pattern;
  final dynamic payload;
  final int? subscriptionCount;

  PubSubMessage(
    this.type, {
    this.channel,
    this.pattern,
    this.payload,
    this.subscriptionCount,
  });

  bool get isSubscriptionEvent =>
      type == 'subscribe' ||
      type == 'psubscribe' ||
      type == 'unsubscribe' ||
      type == 'punsubscribe';

  bool get isDataMessage => type == 'message' || type == 'pmessage';

  @override
  String toString() =>
      'PubSubMessage($type, channel: $channel, pattern: $pattern, payload: $payload, count: $subscriptionCount)';
}
