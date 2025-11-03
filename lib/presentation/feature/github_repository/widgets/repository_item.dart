import 'package:flutter/material.dart';
import 'package:junie_ai_test/domain/entities/github_repository/github_repository.dart';

class RepositoryItem extends StatelessWidget {
  final GithubRepository repository;

  const RepositoryItem({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(repository.owner.avatarUrl),
          radius: 24,
        ),
        title: Text(
          repository.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              repository.fullName,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (repository.description != null) ...[
              const SizedBox(height: 4),
              Text(
                repository.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  repository.private ? Icons.lock : Icons.public,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  repository.private ? 'Private' : 'Public',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (repository.fork) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.fork_right, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Fork',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
