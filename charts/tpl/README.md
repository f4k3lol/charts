# tpl v1.0.0

Generic Helm chart for templating Kubernetes resources from values.

## Usage modes

1. **Standalone** — install directly with your `values.yaml`
2. **Single dependency** — add as a dependency in another chart's `Chart.yaml`
3. **Multiple dependencies** — use as multiple aliased dependencies with `nameOverride` for unique selector labels

## Values merge order

All merges use `mustMergeOverwrite` with deep-copied sources to avoid cross-resource bleed:

1. `defaultContainer` → each `containers.<name>`
2. `defaultService` → each `services.<name>`
3. `defaultIngress` → each `services.<name>.ingresses.<name>`
4. `defaultVolumeClaimTemplate` → each `volumeClaimTemplates[n]`

## Resources generated

| Values key | K8s resource |
|---|---|
| `containers` | Deployment or StatefulSet |
| `services` | Service |
| `services.*.ingresses` | Ingress |
| `configMaps` | ConfigMap |
| `secrets` | Secret |
| `autoscaling` | HorizontalPodAutoscaler |
| `extraManifests` | Any (raw YAML) |

## Tpl rendering

Annotations, env values, pod annotations, and extra manifests support Go template rendering.
Use `{{ .Release.Name }}`, `{{ .Values.* }}`, etc. inside string values.

## Quick start

```yaml
containers:
  app:
    image:
      repository: nginx
      tag: "1.27"
    ports:
      - name: http
        containerPort: 80
        protocol: TCP

services:
  app:
    ports:
      - name: http
        port: 80
```

See [examples/](examples/) for full usage patterns.
