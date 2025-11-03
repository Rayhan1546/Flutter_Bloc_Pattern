import 'package:junie_ai_test/domain/entities/github_repository/owner.dart';

class GithubRepository {
  final int id;
  final String nodeId;
  final String name;
  final String fullName;
  final bool private;
  final Owner owner;
  final String htmlUrl;
  final String? description;
  final bool fork;
  final String url;

  const GithubRepository({
    required this.id,
    required this.nodeId,
    required this.name,
    required this.fullName,
    required this.private,
    required this.owner,
    required this.htmlUrl,
    this.description,
    required this.fork,
    required this.url,
  });

  GithubRepository copyWith({
    int? id,
    String? nodeId,
    String? name,
    String? fullName,
    bool? private,
    Owner? owner,
    String? htmlUrl,
    String? description,
    bool? fork,
    String? url,
  }) {
    return GithubRepository(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      private: private ?? this.private,
      owner: owner ?? this.owner,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      description: description ?? this.description,
      fork: fork ?? this.fork,
      url: url ?? this.url,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GithubRepository &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nodeId == other.nodeId &&
          name == other.name &&
          fullName == other.fullName &&
          private == other.private &&
          owner == other.owner &&
          htmlUrl == other.htmlUrl &&
          description == other.description &&
          fork == other.fork &&
          url == other.url;

  @override
  int get hashCode =>
      id.hashCode ^
      nodeId.hashCode ^
      name.hashCode ^
      fullName.hashCode ^
      private.hashCode ^
      owner.hashCode ^
      htmlUrl.hashCode ^
      description.hashCode ^
      fork.hashCode ^
      url.hashCode;
}
