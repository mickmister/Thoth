#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
. ../shared/artifact_policy.sh
. ../shared/github.sh

INPUT_ARTIFACTS=disabled
INPUT_TRACEPARENT=00-123456789abcdef0123456789abcdef0-123456789abcdef0-01
configure_artifact_policy
test "$TRACEPARENT" = "$INPUT_TRACEPARENT"
test "$OTEL_GITHUB_ARTIFACTS_DISABLED" = TRUE
if gh_artifact_upload 1 1 forbidden /nonexistent 2>/dev/null; then exit 1; fi
if gh_artifact_download 1 1 forbidden /nonexistent 2>/dev/null; then exit 1; fi
if gh_artifact_delete 1 1 forbidden 2>/dev/null; then exit 1; fi
for key in OTEL_TRACES_EXPORTER OTEL_METRICS_EXPORTER OTEL_LOGS_EXPORTER; do
  if (export "$key=deferred"; configure_artifact_policy) 2>/dev/null; then exit 1; fi
done
for parent in '' invalid 00-00000000000000000000000000000000-123456789abcdef0-01 00-123456789abcdef0123456789abcdef0-0000000000000000-01; do
  if (INPUT_TRACEPARENT="$parent"; configure_artifact_policy) 2>/dev/null; then exit 1; fi
done
if (INPUT_ARTIFACTS=invalid; configure_artifact_policy) 2>/dev/null; then exit 1; fi
INPUT_ARTIFACTS=enabled
configure_artifact_policy
test "$OTEL_GITHUB_ARTIFACTS_DISABLED" = FALSE
echo 'Artifact-free policy validation and native helper guards passed.'
