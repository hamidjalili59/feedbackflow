import 'package:dio/dio.dart';
import 'package:feedbackflow_flutter_client/data/api/feedback_flow_api_client.dart';
import 'package:feedbackflow_flutter_client/data/dto/dto.dart';
import 'package:feedbackflow_flutter_client/data/repositories/analytics_repository.dart';
import 'package:feedbackflow_flutter_client/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'set audience segment members accepts success envelope from PUT',
    () async {
      late RequestOptions captured;
      final dio = _stubDio((options) {
        captured = options;
        expect(options.method, 'PUT');
        expect(
          options.path,
          '/api/v1/audience-segments/fca792f5-64e0-47c1-bde5-0f95974d7afa/members',
        );
        expect(options.data, {
          'user_ids': ['user-1', 'user-2'],
        });
        return {
          'success': true,
          'data': {
            'members': [
              {
                'user_id': 'user-1',
                'display_name': 'Student One',
                'primary_role': 'student',
                'role_snapshot': 'student',
                'metadata': <String, Object?>{},
                'created_at': '2026-06-06T08:00:00Z',
              },
              {
                'user_id': 'user-2',
                'display_name': 'Teacher Two',
                'primary_role': 'teacher',
                'role_snapshot': 'teacher',
                'metadata': <String, Object?>{},
                'created_at': '2026-06-06T08:00:00Z',
              },
            ],
          },
          'error': null,
          'meta': <String, Object?>{},
        };
      });
      final repository = DioAnalyticsRepository(FeedbackFlowApiClient(dio));

      final members = await repository.setAudienceSegmentMembers(
        id: 'fca792f5-64e0-47c1-bde5-0f95974d7afa',
        request: const SetAudienceSegmentMembersRequest2(
          userIds: ['user-1', 'user-2'],
        ),
      );

      expect(captured.data, isA<Map>());
      expect(members, hasLength(2));
      expect(members.first.userId, 'user-1');
      expect(members.first.displayName, 'Student One');
      expect(members.first.primaryRole, UserRole.student);
      expect(members.last.primaryRole, UserRole.teacher);
    },
  );

  test(
    'set audience segment members reloads members when PUT data is null',
    () async {
      final requests = <String>[];
      final dio = _queuedDio([
        (options) {
          requests.add('${options.method} ${options.path}');
          expect(options.method, 'PUT');
          return {
            'success': true,
            'data': null,
            'error': null,
            'meta': <String, Object?>{},
          };
        },
        (options) {
          requests.add('${options.method} ${options.path}');
          expect(options.method, 'GET');
          return {
            'success': true,
            'data': [
              {
                'user_id': 'user-1',
                'display_name': 'Student One',
                'primary_role': 'student',
                'role_snapshot': 'student',
                'metadata': <String, Object?>{},
                'created_at': '2026-06-06T08:00:00Z',
              },
            ],
            'error': null,
            'meta': <String, Object?>{},
          };
        },
      ]);
      final repository = DioAnalyticsRepository(FeedbackFlowApiClient(dio));

      final members = await repository.setAudienceSegmentMembers(
        id: 'segment-1',
        request: const SetAudienceSegmentMembersRequest2(userIds: ['user-1']),
      );

      expect(requests, [
        'PUT /api/v1/audience-segments/segment-1/members',
        'GET /api/v1/audience-segments/segment-1/members',
      ]);
      expect(members, hasLength(1));
      expect(members.single.userId, 'user-1');
    },
  );

  test(
    'set audience group members accepts success envelope from PUT',
    () async {
      final dio = _stubDio((options) {
        expect(options.method, 'PUT');
        expect(options.path, '/api/v1/audience-groups/group-1/members');
        expect(options.data, {
          'members': [
            {'user_id': 'user-1', 'role_in_group': 'leader'},
            {'user_id': 'user-2'},
          ],
        });
        return {
          'success': true,
          'data': [
            {
              'user_id': 'user-1',
              'display_name': 'Student One',
              'primary_role': 'student',
              'role_in_group': 'leader',
              'created_at': '2026-06-06T08:00:00Z',
            },
            {
              'user_id': 'user-2',
              'display_name': 'Parent Two',
              'primary_role': 'parent',
              'role_in_group': null,
              'created_at': '2026-06-06T08:00:00Z',
            },
          ],
          'error': null,
          'meta': <String, Object?>{},
        };
      });
      final repository = DioAnalyticsRepository(FeedbackFlowApiClient(dio));

      final members = await repository.setAudienceGroupMembers(
        id: 'group-1',
        request: const SetAudienceGroupMembersRequest2(
          members: [
            AudienceGroupMemberInputDto2(
              userId: 'user-1',
              roleInGroup: 'leader',
            ),
            AudienceGroupMemberInputDto2(userId: 'user-2'),
          ],
        ),
      );

      expect(members, hasLength(2));
      expect(members.first.userId, 'user-1');
      expect(members.first.roleInGroup, 'leader');
      expect(members.last.primaryRole, UserRole.parent);
      expect(members.last.roleInGroup, isNull);
    },
  );

  test('member dialogs sync selection state from successful API response', () {
    final segmentMembers = [
      const AudienceSegmentMemberDto2(
        userId: 'segment-user-1',
        displayName: 'Segment User One',
        primaryRole: UserRole.student,
      ),
      const AudienceSegmentMemberDto2(
        userId: 'segment-user-2',
        displayName: 'Segment User Two',
        primaryRole: UserRole.teacher,
      ),
    ];
    final groupMembers = [
      const AudienceGroupMemberDto2(
        userId: 'group-user-1',
        displayName: 'Group User One',
        primaryRole: UserRole.student,
        roleInGroup: 'leader',
      ),
      const AudienceGroupMemberDto2(
        userId: 'group-user-2',
        displayName: 'Group User Two',
        primaryRole: UserRole.parent,
      ),
    ];

    expect(audienceSegmentMemberIds(segmentMembers), {
      'segment-user-1',
      'segment-user-2',
    });
    expect(audienceGroupMemberIds(groupMembers), {
      'group-user-1',
      'group-user-2',
    });
    expect(audienceGroupRoleByUserId(groupMembers), {
      'group-user-1': 'leader',
      'group-user-2': null,
    });
  });
}

Dio _stubDio(Map<String, Object?> Function(RequestOptions options) respond) {
  return _queuedDio([respond]);
}

Dio _queuedDio(
  List<Map<String, Object?> Function(RequestOptions options)> responses,
) {
  final dio = Dio(
    BaseOptions(baseUrl: 'http://localhost:8080', validateStatus: (_) => true),
  );
  var index = 0;
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (index >= responses.length) {
          throw StateError('No stub response registered for ${options.path}');
        }
        final respond = responses[index++];
        handler.resolve(
          Response<Map<String, Object?>>(
            requestOptions: options,
            statusCode: 200,
            data: respond(options),
          ),
        );
      },
    ),
  );
  return dio;
}
