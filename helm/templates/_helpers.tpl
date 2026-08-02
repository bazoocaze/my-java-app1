.{{- define "my-java-app.labels" -}}
helm.sh/chart: {{ include "my-java-app.chart" . }}
{{ include "my-java-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "my-java-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "my-java-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "my-java-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-java-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}