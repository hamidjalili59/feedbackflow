from pathlib import Path
root = Path(__file__).resolve().parents[1]
workspace = root / 'lib/features/forms/presentation/form_detail_screen.dart'
router = root / 'lib/app/router.dart'
create = root / 'lib/features/forms/presentation/create_form_screen.dart'
text = workspace.read_text()
required_tokens = [
    'enum FormWorkspaceSection',
    'FormWorkspaceSection.builder',
    'FormWorkspaceSection.preview',
    'FormWorkspaceSection.settings',
    'FormWorkspaceSection.publish',
    'FormWorkspaceSection.share',
    'FormWorkspaceSection.results',
    'createFormField',
    'updateFormField',
    'deleteFormField',
    'publishForm',
    'submitFormForApproval',
    'closeForm',
    'archiveForm',
    'formAnalyticsProvider',
    'submissionsProvider',
]
missing = [token for token in required_tokens if token not in text]
if missing:
    raise SystemExit(f'Missing workspace tokens: {missing}')
router_text = router.read_text()
if "path: '/forms/:id/:section'" not in router_text:
    raise SystemExit('Missing workspace section route')
if "context.go('/forms/${nextCreated.id}/builder')" not in create.read_text():
    raise SystemExit('Create flow does not navigate to builder')
print('[OK] form workspace workflow checks passed')
