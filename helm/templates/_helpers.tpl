.{{- define "my-java-app1.labels" -}}
helm.sh/chart: {{ include "my-java-app1.chart" . }}
{{ include "my-java-app1.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "my-java-app1.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "my-java-app1.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "my-java-app1.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-java-app1.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}