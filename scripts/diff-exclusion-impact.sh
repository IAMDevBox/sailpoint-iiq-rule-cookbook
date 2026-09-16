#!/usr/bin/env bash
# Compares CertificationItem counts between two staged certifications of the
# same definition — one generated with an exclusion rule attached, one
# without — to quantify what the rule actually filtered before it ever
# reaches a live campaign with real reviewers.
#
# Run each certification as "Staged" from Certifications > Certification
# Schedule (this generates the CertificationEntity/CertificationItem rows
# without activating the campaign or notifying reviewers), then pass both
# certification names here.
#
# Usage:
#   DB_USER=identityiq DB_PASS=changeit \
#     ./diff-exclusion-impact.sh "Q3 Access Review (no rule)" "Q3 Access Review (with rule)"

set -euo pipefail

BASELINE_CERT="${1:?Usage: $0 <baseline certification name> <with-rule certification name>}"
CANDIDATE_CERT="${2:?Usage: $0 <baseline certification name> <with-rule certification name>}"
DB_USER="${DB_USER:-identityiq}"
DB_PASS="${DB_PASS:-changeit}"
DB_NAME="${DB_NAME:-identityiq}"

count_items() {
  local cert_name="$1"
  mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "
    SELECT COUNT(ci.id)
    FROM spt_certification_item ci
    JOIN spt_certification_entity ce ON ci.certification_entity = ce.id
    JOIN spt_certification c ON ce.certification = c.id
    WHERE c.name = '${cert_name//\'/\'\'}';
  "
}

baseline_count=$(count_items "$BASELINE_CERT")
candidate_count=$(count_items "$CANDIDATE_CERT")
excluded=$((baseline_count - candidate_count))

echo "Baseline certification  : $BASELINE_CERT -> $baseline_count items"
echo "Candidate certification : $CANDIDATE_CERT -> $candidate_count items"
echo "Excluded by rule        : $excluded items"

if [ "$excluded" -lt 0 ]; then
  echo "WARNING: candidate has MORE items than baseline — check you passed the arguments in the right order." >&2
fi

if [ "$baseline_count" -gt 0 ] && [ "$excluded" -eq "$baseline_count" ]; then
  echo "WARNING: exclusion rule removed 100% of items — this usually means a bug (e.g. a null check that always short-circuits), not a working filter." >&2
fi
