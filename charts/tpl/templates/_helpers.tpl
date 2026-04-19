{{/*
=============================================================================
tpl v1.0.0 — helper templates
=============================================================================
*/}}

{{/*
------------------------------------------------------------------------------
NAMING
------------------------------------------------------------------------------
*/}}

{{/*
tpl.name — chart name, respects nameOverride.
Used in labels (app.kubernetes.io/name).
*/}}
{{- define "tpl.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
tpl.fullname — base name for all resources. Priority:
  1. fullnameOverride (if set)
  2. release-chart (truncated to 63 chars)
If release name already contains chart name, don't duplicate.
*/}}
{{- define "tpl.fullname" -}}
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
tpl.resourceName — full resource name for a map entry.
Usage: include "tpl.resourceName" (dict "context" . "name" $name)
Produces: fullname-name (or just fullname if name equals chart name).
*/}}
{{- define "tpl.resourceName" -}}
{{- $fullname := include "tpl.fullname" .context }}
{{- if eq $fullname .name }}
{{- $fullname }}
{{- else }}
{{- printf "%s-%s" $fullname .name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
------------------------------------------------------------------------------
LABELS
------------------------------------------------------------------------------
*/}}

{{/*
tpl.labels — standard Kubernetes labels + commonLabels.
*/}}
{{- define "tpl.labels" -}}
{{ include "tpl.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | default .Chart.Version | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
tpl.selectorLabels — immutable selector labels (name + instance).
*/}}
{{- define "tpl.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tpl.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
------------------------------------------------------------------------------
METADATA
------------------------------------------------------------------------------
*/}}

{{/*
tpl.metadata — common metadata block for any resource.
Usage: include "tpl.metadata" (dict "context" . "name" $name "labels" $extraLabels "annotations" $extraAnnotations)
*/}}
{{- define "tpl.metadata" -}}
name: {{ include "tpl.resourceName" (dict "context" .context "name" .name) }}
namespace: {{ .context.Release.Namespace }}
labels:
  {{- include "tpl.labels" .context | nindent 2 }}
  {{- with .labels }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- if or .annotations .context.Values.commonAnnotations }}
annotations:
  {{- with .context.Values.commonAnnotations }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with .annotations }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
------------------------------------------------------------------------------
DEEP MERGE
------------------------------------------------------------------------------
*/}}

{{/*
tpl.mergeDeep — deep-copy both sides before mustMergeOverwrite to prevent
mutation of the source dicts (the bleed bug from the old chart).
Usage: include "tpl.mergeDeep" (dict "base" $defaults "override" $specific)
Returns: YAML string of the merged dict.
*/}}
{{- define "tpl.mergeDeep" -}}
{{- $base := deepCopy .base }}
{{- $override := deepCopy .override }}
{{- mustMergeOverwrite $base $override | toYaml }}
{{- end }}

{{/*
------------------------------------------------------------------------------
IMAGE
------------------------------------------------------------------------------
*/}}

{{/*
tpl.image — render container image string.
Priority: imageString > digest > registry/repository:tag.
The container's image block is already merged with defaultContainer.image at this point.
Usage: include "tpl.image" (dict "container" $containerSpec)
*/}}
{{- define "tpl.image" -}}
{{- $c := .container }}
{{- if $c.imageString }}
{{- $c.imageString }}
{{- else }}
{{- $img := $c.image | default dict }}
{{- $registry := $img.registry | default "" }}
{{- $repository := $img.repository | default "" }}
{{- $tag := $img.tag | default "" }}
{{- $digest := $img.digest | default "" }}
{{- if $digest }}
{{- if $registry }}
{{- printf "%s/%s@%s" $registry $repository $digest }}
{{- else }}
{{- printf "%s@%s" $repository $digest }}
{{- end }}
{{- else if $tag }}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- else }}
{{- if $registry }}
{{- printf "%s/%s" $registry $repository }}
{{- else }}
{{- $repository }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
------------------------------------------------------------------------------
ENV
------------------------------------------------------------------------------
*/}}

{{/*
tpl.env — convert env map to Kubernetes env array.
Input map: { APP_NAME: {value: "x"}, DB_HOST: {from: configMap, name: y, key: z} }
Output: standard k8s env list.
Usage: include "tpl.env" (dict "env" $envMap)
*/}}
{{- define "tpl.env" -}}
{{- range $envName, $envSpec := .env }}
- name: {{ $envName }}
  {{- if eq (default "" $envSpec.from) "configMap" }}
  valueFrom:
    configMapKeyRef:
      name: {{ $envSpec.name }}
      key: {{ $envSpec.key }}
  {{- else if eq (default "" $envSpec.from) "secret" }}
  valueFrom:
    secretKeyRef:
      name: {{ $envSpec.name }}
      key: {{ $envSpec.key }}
  {{- else }}
  value: {{ $envSpec.value | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
------------------------------------------------------------------------------
CONFIG MOUNTS
------------------------------------------------------------------------------
*/}}

{{/*
tpl.configVolumes — generate volumes from container configs.
Each config entry becomes a volume named "config-<configName>".
Usage: include "tpl.configVolumes" (dict "containers" $containers "initContainers" $initContainers)
*/}}
{{- define "tpl.configVolumes" -}}
{{- $volumes := dict }}
{{- range $_, $containers := list .containers .initContainers }}
{{- range $_, $cSpec := $containers }}
{{- range $cfgName, $cfgSpec := ($cSpec.configs | default dict) }}
{{- $volName := printf "config-%s" $cfgName }}
{{- if not (hasKey $volumes $volName) }}
{{- $_ := set $volumes $volName $cfgSpec }}
- name: {{ $volName }}
  {{- if eq $cfgSpec.from "configMap" }}
  configMap:
    name: {{ $cfgSpec.name }}
    {{- if $cfgSpec.key }}
    items:
      - key: {{ $cfgSpec.key }}
        path: {{ base $cfgSpec.mountPath }}
    {{- end }}
    {{- with $cfgSpec.defaultMode }}
    defaultMode: {{ . }}
    {{- end }}
  {{- else if eq $cfgSpec.from "secret" }}
  secret:
    secretName: {{ $cfgSpec.name }}
    {{- if $cfgSpec.key }}
    items:
      - key: {{ $cfgSpec.key }}
        path: {{ base $cfgSpec.mountPath }}
    {{- end }}
    {{- with $cfgSpec.defaultMode }}
    defaultMode: {{ . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
tpl.configVolumeMounts — generate volumeMounts from container configs.
Usage: include "tpl.configVolumeMounts" (dict "configs" $configs)
*/}}
{{- define "tpl.configVolumeMounts" -}}
{{- range $cfgName, $cfgSpec := .configs }}
- name: config-{{ $cfgName }}
  mountPath: {{ $cfgSpec.mountPath }}
  {{- if $cfgSpec.key }}
  subPath: {{ base $cfgSpec.mountPath }}
  {{- end }}
  readOnly: true
{{- end }}
{{- end }}

{{/*
------------------------------------------------------------------------------
CHECKSUMS
------------------------------------------------------------------------------
*/}}

{{/*
tpl.checksumAnnotations — generate checksum annotations for auto-restart.
Input: list of "configMaps/name" or "secrets/name" references.
Usage: include "tpl.checksumAnnotations" (dict "checksums" $list "context" $)
*/}}
{{- define "tpl.checksumAnnotations" -}}
{{- $ctx := .context }}
{{- range .checksums }}
{{- $parts := splitList "/" . }}
{{- $kind := index $parts 0 }}
{{- $name := index $parts 1 }}
{{- $annKey := printf "checksum/%s-%s" $kind $name }}
{{- if eq $kind "configMaps" }}
{{- $cm := index ($ctx.Values.configMaps | default dict) $name | default dict }}
{{ $annKey }}: {{ $cm | toYaml | sha256sum }}
{{- else if eq $kind "secrets" }}
{{- $sec := index ($ctx.Values.secrets | default dict) $name | default dict }}
{{ $annKey }}: {{ $sec | toYaml | sha256sum }}
{{- end }}
{{- end }}
{{- end }}

{{/*
------------------------------------------------------------------------------
CONTAINER BUILDER
------------------------------------------------------------------------------
*/}}

{{/*
tpl.container — build a single Kubernetes container spec.
Merges defaultContainer, renders image, env, configs, volumeMounts.
Usage: include "tpl.container" (dict "name" $name "spec" $spec "context" $)
*/}}
{{- define "tpl.container" -}}
{{- $defaults := .context.Values.defaultContainer | default dict }}
{{- $merged := fromYaml (include "tpl.mergeDeep" (dict "base" $defaults "override" .spec)) }}
- name: {{ .name }}
  image: {{ include "tpl.image" (dict "container" $merged) }}
  {{- with $merged.imagePullPolicy }}
  imagePullPolicy: {{ . }}
  {{- end }}
  {{- with $merged.workingDir }}
  workingDir: {{ . }}
  {{- end }}
  {{- with $merged.command }}
  command: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $merged.args }}
  args: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $merged.ports }}
  ports: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $merged.securityContext }}
  securityContext: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $merged.resources }}
  resources: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $merged.env }}
  env:
    {{- include "tpl.env" (dict "env" .) | nindent 4 }}
  {{- end }}
  {{- with $merged.envFrom }}
  envFrom: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $merged.livenessProbe }}
  livenessProbe: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $merged.readinessProbe }}
  readinessProbe: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $merged.startupProbe }}
  startupProbe: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $merged.lifecycle }}
  lifecycle: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- if or $merged.volumeMounts $merged.configs }}
  volumeMounts:
    {{- with $merged.volumeMounts }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- with $merged.configs }}
    {{- include "tpl.configVolumeMounts" (dict "configs" .) | nindent 4 }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
tpl.containers — build a list of containers from a map.
Usage: include "tpl.containers" (dict "containers" $map "context" $)
*/}}
{{- define "tpl.containers" -}}
{{- range $name, $spec := .containers }}
{{- include "tpl.container" (dict "name" $name "spec" $spec "context" $.context) }}
{{- end }}
{{- end }}

{{/*
------------------------------------------------------------------------------
POD SPEC BUILDER
------------------------------------------------------------------------------
*/}}

{{/*
tpl.podSpec — build the pod template spec for any workload.
Merges defaultPod, applies pod-level fields, renders containers.
Usage: include "tpl.podSpec" (dict "workload" $spec "context" $)
*/}}
{{- define "tpl.podSpec" -}}
{{- $defaults := .context.Values.defaultPod | default dict }}
{{- $w := .workload }}
{{- /* Extract pod-level keys from workload, merge over defaultPod */ -}}
{{- $podKeys := dict }}
{{- with $w.podSecurityContext }}{{ $_ := set $podKeys "podSecurityContext" . }}{{ end }}
{{- if hasKey $w "enableServiceLinks" }}{{ $_ := set $podKeys "enableServiceLinks" $w.enableServiceLinks }}{{ end }}
{{- with $w.nodeSelector }}{{ $_ := set $podKeys "nodeSelector" . }}{{ end }}
{{- with $w.tolerations }}{{ $_ := set $podKeys "tolerations" . }}{{ end }}
{{- with $w.affinity }}{{ $_ := set $podKeys "affinity" . }}{{ end }}
{{- with $w.terminationGracePeriodSeconds }}{{ $_ := set $podKeys "terminationGracePeriodSeconds" . }}{{ end }}
{{- with $w.dnsPolicy }}{{ $_ := set $podKeys "dnsPolicy" . }}{{ end }}
{{- with $w.dnsConfig }}{{ $_ := set $podKeys "dnsConfig" . }}{{ end }}
{{- if hasKey $w "hostNetwork" }}{{ $_ := set $podKeys "hostNetwork" $w.hostNetwork }}{{ end }}
{{- if hasKey $w "hostPID" }}{{ $_ := set $podKeys "hostPID" $w.hostPID }}{{ end }}
{{- with $w.restartPolicy }}{{ $_ := set $podKeys "restartPolicy" . }}{{ end }}
{{- with $w.serviceAccountName }}{{ $_ := set $podKeys "serviceAccountName" . }}{{ end }}
{{- with $w.imagePullSecrets }}{{ $_ := set $podKeys "imagePullSecrets" . }}{{ end }}
{{- with $w.topologySpreadConstraints }}{{ $_ := set $podKeys "topologySpreadConstraints" . }}{{ end }}
{{- with $w.podLabels }}{{ $_ := set $podKeys "podLabels" . }}{{ end }}
{{- with $w.podAnnotations }}{{ $_ := set $podKeys "podAnnotations" . }}{{ end }}
{{- $pod := fromYaml (include "tpl.mergeDeep" (dict "base" $defaults "override" $podKeys)) }}
metadata:
  labels:
    {{- include "tpl.labels" .context | nindent 4 }}
    {{- with $pod.podLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- if or $pod.podAnnotations $w.checksumAnnotations .context.Values.commonAnnotations }}
  annotations:
    {{- with .context.Values.commonAnnotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- with $pod.podAnnotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- with $w.checksumAnnotations }}
    {{- include "tpl.checksumAnnotations" (dict "checksums" . "context" $.context) | nindent 4 }}
    {{- end }}
  {{- end }}
spec:
  {{- with $pod.serviceAccountName }}
  serviceAccountName: {{ . }}
  {{- end }}
  {{- with $pod.imagePullSecrets }}
  imagePullSecrets: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $pod.podSecurityContext }}
  securityContext: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- if kindIs "bool" $pod.enableServiceLinks }}
  enableServiceLinks: {{ $pod.enableServiceLinks }}
  {{- end }}
  {{- with $pod.nodeSelector }}
  nodeSelector: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $pod.tolerations }}
  tolerations: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $pod.affinity }}
  affinity: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $pod.topologySpreadConstraints }}
  topologySpreadConstraints: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with $pod.terminationGracePeriodSeconds }}
  terminationGracePeriodSeconds: {{ . }}
  {{- end }}
  {{- with $pod.dnsPolicy }}
  dnsPolicy: {{ . }}
  {{- end }}
  {{- with $pod.dnsConfig }}
  dnsConfig: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- if $pod.hostNetwork }}
  hostNetwork: {{ $pod.hostNetwork }}
  {{- end }}
  {{- if $pod.hostPID }}
  hostPID: {{ $pod.hostPID }}
  {{- end }}
  {{- with $pod.restartPolicy }}
  restartPolicy: {{ . }}
  {{- end }}
  {{- with $w.initContainers }}
  initContainers:
    {{- include "tpl.containers" (dict "containers" . "context" $.context) | nindent 4 }}
  {{- end }}
  containers:
    {{- include "tpl.containers" (dict "containers" $w.containers "context" .context) | nindent 4 }}
  {{- /* Combine explicit volumes + auto-generated config volumes */ -}}
  {{- $configVols := include "tpl.configVolumes" (dict "containers" ($w.containers | default dict) "initContainers" ($w.initContainers | default dict)) }}
  {{- if or $w.volumes $configVols }}
  volumes:
    {{- with $w.volumes }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- with $configVols }}
    {{- . | nindent 4 }}
    {{- end }}
  {{- end }}
{{- end }}
