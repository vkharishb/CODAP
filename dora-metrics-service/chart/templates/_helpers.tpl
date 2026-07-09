{{- define "dora-metrics-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "dora-metrics-service.fullname" -}}
{{- printf "%s" (include "dora-metrics-service.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
