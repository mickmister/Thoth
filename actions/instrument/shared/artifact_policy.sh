#!/bin/false
# shellcheck shell=bash

configure_artifact_policy() {
  case "${INPUT_ARTIFACTS:-enabled}" in
    enabled) export OTEL_GITHUB_ARTIFACTS_DISABLED=FALSE ;;
    disabled)
      export OTEL_GITHUB_ARTIFACTS_DISABLED=TRUE
      if ! [[ "${INPUT_TRACEPARENT:-}" =~ ^00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]$ ]] ||
         [[ "$INPUT_TRACEPARENT" = 00-00000000000000000000000000000000-* ]] ||
         [[ "$INPUT_TRACEPARENT" = *-0000000000000000-* ]]; then
        echo '::error::artifact-free instrumentation requires a valid externally persisted traceparent' >&2
        return 1
      fi
      for exporter in "${OTEL_TRACES_EXPORTER:-otlp}" "${OTEL_METRICS_EXPORTER:-otlp}" "${OTEL_LOGS_EXPORTER:-otlp}"; do
        if [ "$exporter" = deferred ]; then
          echo '::error::deferred artifact export is forbidden when artifacts are disabled' >&2
          return 1
        fi
      done
      export TRACEPARENT="$INPUT_TRACEPARENT"
      ;;
    *) echo '::error::artifacts must be enabled or disabled' >&2; return 1 ;;
  esac
}
