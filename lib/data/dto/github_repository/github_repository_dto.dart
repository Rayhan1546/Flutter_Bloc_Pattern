import 'package:junie_ai_test/data/dto/github_repository/owner_dto.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';

class GithubRepositoryDto {
  final int id;
  final String nodeId;
  final String name;
  final String fullName;
  final bool private;
  final OwnerDto owner;
  final String htmlUrl;
  final String? description;
  final bool fork;
  final String url;

  const GithubRepositoryDto({
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

  factory GithubRepositoryDto.fromJson(Map<String, dynamic> json) {
    return GithubRepositoryDto(
      id: json['id'] as int,
      nodeId: json['node_id'] as String,
      name: json['name'] as String,
      fullName: json['full_name'] as String,
      private: json['private'] as bool,
      owner: OwnerDto.fromJson(json['owner'] as Map<String, dynamic>),
      htmlUrl: json['html_url'] as String,
      description: json['description'] as String?,
      fork: json['fork'] as bool,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'node_id': nodeId,
      'name': name,
      'full_name': fullName,
      'private': private,
      'owner': owner.toJson(),
      'html_url': htmlUrl,
      if (description != null) 'description': description,
      'fork': fork,
      'url': url,
    };
  }
}

// Extension to convert DTO to Domain Entity
extension GithubRepositoryDtoX on GithubRepositoryDto {
  GithubRepository toDomain() {
    return GithubRepository(
      id: id,
      nodeId: nodeId,
      name: name,
      fullName: fullName,
      private: private,
      owner: owner.toDomain(),
      htmlUrl: htmlUrl,
      description: description,
      fork: fork,
      url: url,
    );
  }
}
