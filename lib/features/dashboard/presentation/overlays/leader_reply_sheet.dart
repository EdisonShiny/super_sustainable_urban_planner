import 'package:flutter/material.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/models/user_profile.dart';
import '../../data/feedback_repository.dart';
import '../../models/feedback.dart';
import '../../models/leader_reply.dart';

class LeaderReplySheet extends StatefulWidget {
  const LeaderReplySheet({
    super.key,
    required this.leader,
    required this.feedbackEntries,
    required this.onReplyCreated,
  });

  final UserProfile leader;
  final List<FeedbackEntry> feedbackEntries;
  final ValueChanged<LeaderReply> onReplyCreated;

  static Future<void> show(
    BuildContext context, {
    required UserProfile leader,
    required List<FeedbackEntry> feedbackEntries,
    required ValueChanged<LeaderReply> onReplyCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: LeaderReplySheet(
          leader: leader,
          feedbackEntries: feedbackEntries,
          onReplyCreated: onReplyCreated,
        ),
      ),
    );
  }

  @override
  State<LeaderReplySheet> createState() => _LeaderReplySheetState();
}

class _LeaderReplySheetState extends State<LeaderReplySheet> {
  FeedbackEntry? _selectedFeedback;
  final _replyController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.feedbackEntries.isNotEmpty) {
      _selectedFeedback = widget.feedbackEntries.first;
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_selectedFeedback == null) {
      setState(() => _error = 'Select feedback to respond to.');
      return;
    }
    if (requiredValidator(_replyController.text) != null) {
      setState(() => _error = AppStrings.fieldRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final reply = await FeedbackRepository.instance.createReply(
        feedbackId: _selectedFeedback!.id,
        leader: widget.leader,
        replyText: _replyController.text.trim(),
      );
      widget.onReplyCreated(reply);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _error = 'Unable to send reply. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.leaderReplyTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.feedbackEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'No resident feedback yet. Encourage participation to receive updates.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            DropdownButtonFormField<FeedbackEntry>(
              initialValue: _selectedFeedback,
              items: widget.feedbackEntries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry,
                      child: Text('${entry.username} (${entry.rating}/5)'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedFeedback = value);
              },
              decoration: const InputDecoration(
                labelText: 'Select resident feedback',
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _replyController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reply to resident',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReply,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.replySubmit),
            ),
          ),
        ],
      ),
    );
  }
}

