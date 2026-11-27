# Backup v2 — staging only

Do not merge or apply SQL to production until tested against a separate Supabase project with synthetic accounts. The branch currently retains the production URL in index.html; replace it locally with staging URL and publishable key before opening the app. Do not commit credentials or real backups.

Run `node --test tests/backup-v2.test.cjs`. Apply supabase/backup-v2.sql to staging with the existing schema and RLS. Test authenticated preview (no persistent changes), cancellation, repeated imports, two identical rows with distinct IDs, legacy content duplicates, same-date snapshot conflicts, invalid final row (all inserts rolled back), simultaneous imports, and cross-user access. Verify anonymous RPC denial and run security advisors. Test export/import via browser.

Current scope: six record collections; profile and settings exported for reference but intentionally not restored, and avatar binary not included. Existing records win on matching ID or snapshot date. Legacy rows without IDs are matched by content and may collapse genuinely identical rows. No encryption, external scheduled backup or consistent cross-table export snapshot yet. Do not treat this as a complete disaster recovery backup. Files over 5 MB cannot be imported. No production migration or deployment performed.
