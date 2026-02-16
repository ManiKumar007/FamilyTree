import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/api_service.dart';
import '../../../config/theme.dart';

class InviteScreen extends ConsumerStatefulWidget {
  final String? token;

  const InviteScreen({super.key, this.token});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _inviteData;
  String? _error;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _claimInvite();
    }
  }

  Future<void> _claimInvite() async {
    setState(() { _isLoading = true; });
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.claimInvite(widget.token!);
      setState(() { _claimed = true; _inviteData = result; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we have a token, show claim UI
    if (widget.token != null) {
      return _buildClaimUI();
    }
    // Otherwise show "select a person to invite" message
    return _buildInfoUI();
  }

  Widget _buildClaimUI() {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.card_giftcard_rounded, size: 22, color: kPrimaryColor),
            const SizedBox(width: 8),
            const Text('Claim Your Profile'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDividerColor.withOpacity(0.5)),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _isLoading
              ? const CircularProgressIndicator()
              : _claimed
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 80, color: kSuccessColor),
                        const SizedBox(height: 16),
                        Text('Profile Claimed!', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        const Text('You can now see your full family tree.'),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/tree'),
                          child: const Text('Go to My Tree'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 80, color: kErrorColor),
                        const SizedBox(height: 16),
                        Text(_error ?? 'Something went wrong'),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildInfoUI() {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person_add_outlined, size: 22, color: kPrimaryColor),
            const SizedBox(width: 8),
            const Text('Invite Family'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDividerColor.withOpacity(0.5)),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.send_rounded, size: 40, color: kPrimaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                'Invite Family Members',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Go to a person\'s profile in your tree and tap "Invite" to send them a link to claim their profile.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for generating and sharing an invite link
class InviteDialog extends ConsumerStatefulWidget {
  final String personId;
  final String personName;

  const InviteDialog({
    super.key,
    required this.personId,
    required this.personName,
  });

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  bool _isLoading = false;
  String? _inviteUrl;
  String? _message;
  String? _error;

  Future<void> _generateInvite() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.generateInvite(widget.personId);
      setState(() {
        _inviteUrl = result['invite_url'] as String?;
        _message = result['message'] as String?;
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _generateInvite();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Invite ${widget.personName}'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Text('Error: $_error')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Share this link with them:'),
                    const SizedBox(height: 8),
                    if (_inviteUrl != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kSurfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _inviteUrl!,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                  ],
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_inviteUrl != null) ...[
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _inviteUrl!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard!')),
              );
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () {
              Share.share(_message ?? _inviteUrl!);
            },
            child: const Text('Share via WhatsApp'),
          ),
        ],
      ],
    );
  }
}
