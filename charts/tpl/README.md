# tpl

Generic chart for templating Kubernetes resources from values. Supports Deployment/StatefulSet, Services, Ingresses, ConfigMaps, Secrets, HPA, and raw extra manifests. Designed for use as a single chart, multiple dependencies, or as-is.

## Usage modes

1. **Standalone** — install directly with your `values.yaml`
2. **Single dependency** — add as a dependency in another chart's `Chart.yaml`
3. **Multiple dependencies** — use as multiple aliased dependencies with `nameOverride` for unique selector labels

## Values merge order

All merges use `deepCopy` + `mustMergeOverwrite` to prevent cross-resource bleed:

| Priority | Default key | Merged into |
|----------|------------|-------------|
| 1 | `global` | Passed to subcharts (lowest priority) |
| 2 | `defaultPod` | Every workload's pod spec |
| 3 | `defaultContainer` | Every container (including initContainers) |
| 4 | `defaultService` | Every service |
| 5 | `defaultIngress` | Every ingress (top-level and nested) |
| 6 | `defaultHttpRoute` | Every HTTPRoute |
| 7 | `defaultGrpcRoute` | Every GRPCRoute |
| 8 | `defaultTcpRoute` | Every TCPRoute |
| 9 | `defaultTlsRoute` | Every TLSRoute |
| 10 | `defaultVolumeClaimTemplate` | Every VCT (StatefulSet) |

Resource-level values always win: `global` < `default*` < resource-level.

## Resources generated

| Values key | K8s resource | Notes |
|---|---|---|
| `deployments` | Deployment | With optional HPA |
| `statefulSets` | StatefulSet | With VCTs |
| `daemonSets` | DaemonSet | |
| `jobs` | Job | |
| `cronJobs` | CronJob | |
| `services` | Service | Supports nested ingresses/httpRoutes |
| `ingresses` | Ingress | Top-level or nested under services |
| `httpRoutes` | HTTPRoute | Gateway API, top-level or nested |
| `grpcRoutes` | GRPCRoute | Gateway API |
| `tcpRoutes` | TCPRoute | Gateway API |
| `tlsRoutes` | TLSRoute | Gateway API |
| `gateways` | Gateway | Gateway API |
| `networkPolicies` | NetworkPolicy | |
| `configMaps` | ConfigMap | |
| `secrets` | Secret | Opaque, TLS, dockerconfigjson |
| `persistentVolumeClaims` | PersistentVolumeClaim | |
| `serviceAccounts` | ServiceAccount | |
| `podDisruptionBudgets` | PodDisruptionBudget | |
| `serviceMonitors` | ServiceMonitor | Prometheus Operator CRD |
| `podMonitors` | PodMonitor | Prometheus Operator CRD |
| `extraManifests` | Any | Native YAML objects |

## Quick start

```yaml
deployments:
  app:
    replicas: 1
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

See [examples/](examples/) for full usage patterns:
- [minimal.yaml](examples/minimal.yaml) — simplest deployment + service
- [deployment.yaml](examples/deployment.yaml) — HPA, ingress, httpRoute, config
- [statefulset.yaml](examples/statefulset.yaml) — Redis cluster with VCTs
- [daemonset.yaml](examples/daemonset.yaml) — Fluent Bit log collector
- [job.yaml](examples/job.yaml) — database migration
- [cronjob.yaml](examples/cronjob.yaml) — scheduled backup with PVC
- [defaults-override.yaml](examples/defaults-override.yaml) — merge priority demo
- [full-reference.yaml](examples/full-reference.yaml) — every possible value documented

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| commonAnnotations | object | `{}` |  |
| commonLabels | object | `{}` |  |
| configMaps | object | `{}` | Config / Storage |
| cronJobs | object | `{}` |  |
| daemonSets | object | `{}` |  |
| defaultContainer | object | `{}` |  |
| defaultGrpcRoute | object | `{}` |  |
| defaultHttpRoute | object | `{}` |  |
| defaultIngress.defaultPathType | string | `"ImplementationSpecific"` |  |
| defaultPod | object | `{"enableServiceLinks":false}` | Defaults (merged into every resource of the corresponding type) |
| defaultService | object | `{}` |  |
| defaultTcpRoute | object | `{}` |  |
| defaultTlsRoute | object | `{}` |  |
| defaultVolumeClaimTemplate.spec.accessModes[0] | string | `"ReadWriteOnce"` |  |
| deployments | object | `{}` | Workloads |
| extraManifests | list | `[]` | Escape hatch |
| fullnameOverride | string | `""` |  |
| gateways | object | `{}` |  |
| global | object | `{}` |  |
| grpcRoutes | object | `{}` |  |
| httpRoutes | object | `{}` |  |
| ingresses | object | `{}` |  |
| jobs | object | `{}` |  |
| nameOverride | string | `""` | Chart identity |
| networkPolicies | object | `{}` |  |
| persistentVolumeClaims | object | `{}` |  |
| podDisruptionBudgets | object | `{}` |  |
| podMonitors | object | `{}` |  |
| secrets | object | `{}` |  |
| serviceAccounts | object | `{}` | Cluster resources |
| serviceMonitors | object | `{}` | Monitoring |
| services | object | `{}` | Networking |
| statefulSets | object | `{}` |  |
| tcpRoutes | object | `{}` |  |
| tlsRoutes | object | `{}` |  |
