import 'package:feedbackflow_flutter_client/data/dto/dto.dart';
import 'package:feedbackflow_flutter_client/features/forms/presentation/form_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial review prefers explicit query submission id', () {
    expect(
      submissionIdForInitialReview(
        querySubmissionId: ' query-submission ',
        formSubmissionId: 'form-submission',
      ),
      'query-submission',
    );
  });

  test('initial review falls back to form detail submission id', () {
    expect(
      submissionIdForInitialReview(
        querySubmissionId: null,
        formSubmissionId: ' form-submission ',
      ),
      'form-submission',
    );
  });

  test('form detail parses my submission id from server json', () {
    final form = FormDetailDto.fromJson({
      'id': '10000000-0000-0000-0000-000000000001',
      'organization_id': '10000000-0000-0000-0000-000000000002',
      'creator_id': '10000000-0000-0000-0000-000000000003',
      'title': 'Parent survey',
      'description': null,
      'category': null,
      'tags': <String>[],
      'status': 'published',
      'visibility_mode': 'organization',
      'publish_mode': 'organization',
      'settings': {
        'allow_anonymous_answers': false,
        'one_submission_per_user': true,
        'answers_editable_after_submission': true,
        'start_at': null,
        'end_at': null,
        'max_submissions': null,
        'submission_cooldown_seconds': 30,
        'submission_mode': 'editable_submission',
        'answer_visibility': 'visible_to_creator',
        'guests_can_answer': false,
        'metadata': <String, Object?>{},
      },
      'visibility': {
        'mode': 'organization',
        'can_see': <Object>[],
        'can_answer': <Object>[],
        'cannot_see': <Object>[],
        'cannot_answer': <Object>[],
        'guest_can_answer': false,
        'anonymous_allowed': false,
        'metadata': <String, Object?>{},
      },
      'public_protection': {
        'level': 'standard',
        'strategies': <String>[],
        'ip_limit_per_minute': null,
        'token_limit_per_day': null,
        'access_limit_per_minute': null,
        'cooldown_seconds': null,
        'max_submissions_per_ip': null,
        'max_submissions_per_fingerprint': null,
        'captcha_enabled': false,
        'email_verification_enabled': false,
        'phone_verification_enabled': false,
        'disabled_limits': <String>[],
        'metadata': <String, Object?>{},
      },
      'scoring_mode': 'none',
      'scoring_config': <String, Object?>{},
      'fields': <Object>[],
      'public_token': null,
      'my_submission_id': '20000000-0000-0000-0000-000000000001',
      'approved_at': null,
      'published_at': null,
      'closed_at': null,
      'created_at': '2026-06-03T00:00:00Z',
      'updated_at': '2026-06-03T00:00:00Z',
    });

    expect(form.mySubmissionId, '20000000-0000-0000-0000-000000000001');
  });
}
