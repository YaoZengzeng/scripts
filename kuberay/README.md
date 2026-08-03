# KubeRay operator install

One-shot installer for the KubeRay operator + CRDs, at the version the verl demo
(`/root/scripts/rl`) expects (**v1.5.1**). Follows the upstream instructions in
`llm-d-rl/integrations/verl/deploy/kuberay/setting-kuberay.md`.

## Prereqs

- `kubectl` and `helm` on PATH, pointing at your target cluster.
- Cluster-admin (only for the one-time CRD install; use `SKIP_CRDS=1` otherwise).

## Usage

```bash
bash /root/scripts/kuberay/install-kuberay.sh            # CRDs + operator
bash /root/scripts/kuberay/install-kuberay.sh uninstall  # remove operator (keeps CRDs)
```

What it does:
1. Installs the Ray CRDs cluster-wide (skipped if already present, or `SKIP_CRDS=1`).
2. Ensures the target namespace.
3. Helm-installs `kuberay-operator` v1.5.1 into that namespace with
   `singleNamespaceInstall=true --skip-crds`, and waits until it is available.

## Env overrides

- `NAMESPACE` — operator namespace (default `llm-d-rl-demo`, matching
  `run-demo.sh`; the single-namespace operator only watches this namespace).
- `KUBERAY_VERSION` — chart/CRD version (default `1.5.1`).
- `SKIP_CRDS=1` — skip the cluster-scoped CRD install (a cluster-admin added them).

## Then run the demo

```bash
bash /root/scripts/rl/run-demo.sh
```

Keep `NAMESPACE` consistent between the two scripts (both default to
`llm-d-rl-demo`).
