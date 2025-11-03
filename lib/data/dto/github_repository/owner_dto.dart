import 'package:junie_ai_test/domain/entities/github_repository/owner.dart';

class OwnerDto {
  final String login;
  final int id;
  final String nodeId;
  final String avatarUrl;
  final String url;
  final String htmlUrl;
  final String type;

  const OwnerDto({
    required this.login,
    required this.id,
    required this.nodeId,
    required this.avatarUrl,
    required this.url,
    required this.htmlUrl,
    required this.type,
  });

  factory OwnerDto.fromJson(Map<String, dynamic> json) {
    return OwnerDto(
      login: json['login'] as String,
      id: json['id'] as int,
      nodeId: json['node_id'] as String,
      avatarUrl: json['avatar_url'] as String,
      url: json['url'] as String,
      htmlUrl: json['html_url'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'login': login,
      'id': id,
      'node_id': nodeId,
      'avatar_url': avatarUrl,
      'url': url,
      'html_url': htmlUrl,
      'type': type,
    };
  }
}

// Extension to convert DTO to Domain Entity
extension OwnerDtoX on OwnerDto {
  Owner toDomain() {
    return Owner(
      login: login,
      id: id,
      nodeId: nodeId,
      avatarUrl: avatarUrl,
      url: url,
      htmlUrl: htmlUrl,
      type: type,
    );
  }
}
