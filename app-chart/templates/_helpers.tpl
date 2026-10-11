```yaml
{{/*
Application name
*/}}
{{- define "app.name" -}}
{{- .Chart.Name -}}
{{- end }}

{{/*
Full resource name
*/}}
{{- define "app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```
