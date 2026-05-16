from pathlib import Path

root = Path(__file__).resolve().parents[1]
api = root / 'lib/data/api/feedback_flow_api_client.dart'
text = api.read_text()

if 'JsonPayloadNormalizer.normalizeMap(value)' not in text:
    raise SystemExit('[FAIL] API client does not normalize request payloads')

if 'data: request.toJson()' in text:
    raise SystemExit('[FAIL] Found unnormalized request.toJson() body')

if 'data: _body(request.toJson())' not in text:
    raise SystemExit('[FAIL] No normalized request body calls found')

normalizer = root / 'lib/data/api/json_payload_normalizer.dart'
if not normalizer.exists():
    raise SystemExit('[FAIL] Missing json_payload_normalizer.dart')
normalizer_text = normalizer.read_text()
for needle in ['continue;', 'prevents payloads such as:', 'normalizeMap']:
    if needle not in normalizer_text:
        raise SystemExit(f'[FAIL] Normalizer missing expected guard: {needle}')

providers = (root / 'lib/app/providers.dart').read_text()
for needle in [
    'canSee: const <AudienceRuleDto>[]',
    'canAnswer: const <AudienceRuleDto>[]',
    'cannotSee: const <AudienceRuleDto>[]',
    'cannotAnswer: const <AudienceRuleDto>[]',
    'metadata: const <String, Object?>{}',
    'scoringConfig: const <String, Object?>{}',
]:
    if needle not in providers:
        raise SystemExit(f'[FAIL] Create form request builder missing: {needle}')

print('[OK] request payload normalization checks passed')
