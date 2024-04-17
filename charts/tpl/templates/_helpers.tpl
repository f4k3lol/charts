{{/*
Expand the name of the chart.
*/}}
{{- define "tpl.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tpl.fullname" -}}
  {{- .Values.fullnameOverride | default .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tpl.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tpl.labels" -}}
helm.sh/chart: {{ include "tpl.chart" . }}
{{ include "tpl.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tpl.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tpl.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tpl.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "tpl.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Check if volumes or configs exists in containers
*/}}
{{- define "tpl.volumesPresent" -}}
  {{- $mergedValues := mustMergeOverwrite (dict) .Values.global .Values }}
  {{- $result := false }}
  {{- range $container_name, $container_spec := $mergedValues.containers }}
    {{- if coalesce (hasKey $container_spec "volumes") (eq $.Values.kind "Deployment") (hasKey $container_spec "configs") }}
      {{- $result = true }}
    {{- end }}
  {{- end }}
  {{- print $result }}
{{- end }}

{{/*
value from here https://habr.com/ru/companies/flant/articles/529158/. used instead of raw tpl func
usage:
{{ include "render" (list $ . $.Values.key }}
*/}}
{{- define "tpl.render" }}
  {{- $ := index . 0 }}
  {{- $val := index . 2 }}
  {{- with index . 1 }}
    {{- if contains "{{" $val }}
      {{- tpl (cat "{{- with $.RelativeScope -}}" $val "{{- end }}") (merge (dict "RelativeScope" .) $) }}
    {{- else }}
      {{- $val }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
try to get key from nested dict, if not found - return ""
usage: {{ include "getOrNull" (list .Values "path.to.nested.value") }}
*/}}
{{- define "tpl.getOrNull" }}
  {{- $v := index . 0 }}
  {{- $k := index . 1 }}
  {{- $found := true }}
  {{- range $value := regexSplit "\\." $k -1 }}
    {{- if hasKey $v $value }}
      {{- $v = get $v $value }}
    {{- else }}
      {{- $found = false }}
    {{- end }}
  {{- end }}
  {{- if eq $found true }}
    {{- $v }}
  {{- else }}
    {{- print "" }}
  {{- end }}
{{- end }}
