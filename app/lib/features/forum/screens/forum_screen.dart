import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';

/// Forum screen showing posts (recipes, stories, photos, etc.)
class ForumScreen extends ConsumerStatefulWidget {
  const ForumScreen({super.key});

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ForumPost> _posts = [];
  bool _isLoading = true;
  String? _error;
  String _selectedType = 'all';

  final List<String> _postTypes = [
    'all',
    'recipe',
    'story',
    'photo_album',
    'announcement',
    'discussion',
    'memory'
  ];

  final Map<String, IconData> _typeIcons = {
    'recipe': Icons.restaurant,
    'story': Icons.auto_stories,
    'photo_album': Icons.photo_library,
    'announcement': Icons.campaign,
    'discussion': Icons.forum,
    'memory': Icons.favorite,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _postTypes.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = _postTypes[_tabController.index];
        });
        _loadPosts();
      }
    });
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final queryParams = _selectedType != 'all' ? '?post_type=$_selectedType' : '';
      final response = await apiService.get('/forum/posts$queryParams');

      if (response['data'] != null) {
        setState(() {
          _posts = (response['data'] as List)
              .map((json) => ForumPost.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createPost() async {
    // Navigate to create post screen (to be created)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create post screen coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Family Forum'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _postTypes.map((type) {
            final icon = type == 'all'
                ? Icons.dynamic_feed
                : _typeIcons[type] ?? Icons.article;
            return Tab(
              icon: Icon(icon, size: 20),
              text: type == 'all'
                  ? 'All Posts'
                  : type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _typeIcons[_selectedType] ?? Icons.forum,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedType == 'all'
                                ? 'No posts yet'
                                : 'No ${_selectedType.replaceAll('_', ' ')}s yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to share!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return _PostCard(
                            post: post,
                            onTap: () {
                              // Navigate to post detail
                              context.push('/forum/post/${post.id}');
                            },
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onTap;

  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postTypeIcon = {
      'recipe': Icons.restaurant,
      'story': Icons.auto_stories,
      'photo_album': Icons.photo_library,
      'announcement': Icons.campaign,
      'discussion': Icons.forum,
      'memory': Icons.favorite,
    }[post.postType] ?? Icons.article;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Type icon + title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      postTypeIcon,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.postType
                              .split('_')
                              .map((w) => w[0].toUpperCase() + w.substring(1))
                              .join(' '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Content preview
              Text(
                post.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Media preview (if any)
              if (post.media != null && post.media!.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.media!.length > 5 ? 5 : post.media!.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final media = post.media![index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          media.mediaUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: theme.colorScheme.surfaceVariant,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // Footer: stats
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('${post.likeCount ?? 0}', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                  Icon(Icons.comment_outlined, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('${post.comments?.length ?? 0}', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility_outlined, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('${post.viewCount}', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Text(
                    _formatDate(post.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return '${diff.inMinutes}m ago';
        }
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
