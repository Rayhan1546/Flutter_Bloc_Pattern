class Owner {
  final String login;
  final int id;
  final String nodeId;
  final String avatarUrl;
  final String url;
  final String htmlUrl;
  final String type;

  const Owner({
    required this.login,
    required this.id,
    required this.nodeId,
    required this.avatarUrl,
    required this.url,
    required this.htmlUrl,
    required this.type,
  });

  Owner copyWith({
    String? login,
    int? id,
    String? nodeId,
    String? avatarUrl,
    String? url,
    String? htmlUrl,
    String? type,
  }) {
    return Owner(
      login: login ?? this.login,
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      url: url ?? this.url,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Owner &&
          runtimeType == other.runtimeType &&
          login == other.login &&
          id == other.id &&
          nodeId == other.nodeId &&
          avatarUrl == other.avatarUrl &&
          url == other.url &&
          htmlUrl == other.htmlUrl &&
          type == other.type;

  @override
  int get hashCode =>
      login.hashCode ^
      id.hashCode ^
      nodeId.hashCode ^
      avatarUrl.hashCode ^
      url.hashCode ^
      htmlUrl.hashCode ^
      type.hashCode;
}
