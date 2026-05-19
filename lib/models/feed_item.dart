class FeedItem {
  const FeedItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  factory FeedItem.fromJson(Map<String, Object?> json) {
    return FeedItem(
      id: json['id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final String imageUrl;
}
