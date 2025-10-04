import 'package:flutter/material.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/models/user_profile.dart';
import '../../data/feedback_repository.dart';
import '../../models/feedback.dart';

class ResidentFeedbackSheet extends StatefulWidget {
  const ResidentFeedbackSheet({
    super.key,
    required this.profile,
    required this.cityName,
    required this.onSubmitted,
  });

  final UserProfile profile;
  final String cityName;
  final ValueChanged<FeedbackEntry> onSubmitted;

  static Future<void> show(
    BuildContext context, {
    required UserProfile profile,
    required String cityName,
    required ValueChanged<FeedbackEntry> onSubmitted,
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
        child: ResidentFeedbackSheet(
          profile: profile,
          cityName: cityName,
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }

  @override
  State<ResidentFeedbackSheet> createState() => _ResidentFeedbackSheetState();
}

class _ResidentFeedbackSheetState extends State<ResidentFeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  int _rating = 3;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await FeedbackRepository.instance.createFeedback(
        author: widget.profile,
        city: widget.cityName,
        description: _descriptionController.text.trim(),
        rating: _rating,
      );

      final entry = FeedbackEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.profile.id,
        username: widget.profile.username,
        accessLevel: widget.profile.accessLevel,
        city: widget.cityName,
        text: _descriptionController.text.trim(),
        rating: _rating,
        createdAt: DateTime.now(),
      );
      widget.onSubmitted(entry);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _error = 'Unable to submit feedback. Please try again.');
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.residentFeedbackTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: AppStrings.feedbackDescriptionLabel,
                alignLabelWithHint: true,
              ),
              validator: requiredValidator,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  AppStrings.feedbackRatingPrompt,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _rating,
                  items: List.generate(5, (index) => index + 1)
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _rating = value);
                    }
                  },
                ),
              ],
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
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.feedbackSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
