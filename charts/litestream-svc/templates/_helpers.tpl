{{/*
Expand the name of the chart.
*/}}
{{- define "litestream-svc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "litestream-svc.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "litestream-svc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "litestream-svc.labels" -}}
helm.sh/chart: {{ include "litestream-svc.chart" . }}
{{ include "litestream-svc.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "litestream-svc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "litestream-svc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "litestream-svc.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "litestream-svc.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the Secret holding Litestream's S3 credentials -- either a Secret this
chart creates itself, or one the caller already created (e.g. via ESO).
*/}}
{{- define "litestream-svc.litestreamSecretName" -}}
{{- if .Values.litestream.credentials.existingSecret }}
{{- .Values.litestream.credentials.existingSecret }}
{{- else }}
{{- printf "%s-litestream" (include "litestream-svc.fullname" .) }}
{{- end }}
{{- end }}
