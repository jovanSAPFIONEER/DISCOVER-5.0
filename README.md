# DISCOVER 5.0 — Reproduction Kit

![CI (fast)](https://github.com/jovanSAPFIONEER/DISCOVER-5.0/actions/workflows/repro.yml/badge.svg) [![Releases](https://img.shields.io/github/v/release/jovanSAPFIONEER/DISCOVER-5.0)](https://github.com/jovanSAPFIONEER/DISCOVER-5.0/releases)

A minimal, one-command reproduction kit for the DISCOVER/Orion causal rewire result:
“Lesioning long‑range connectivity eliminates the early access (SOA‑1) signal; restoring it recovers the signal in a graded way.”

## Quick start (Windows PowerShell)

From this repo’s root:

```powershell
# Run everything end-to-end (clone code, create venv, install deps, run pipeline)
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_repro.ps1
```

Outputs will be copied to:
- `./outputs/soa1_auc_mean_vs_rewire.(csv|png)`
- `./outputs/paired_deltas.csv`
- `./outputs/paired_deltas_plot.(png|pdf)`

The underlying code is cloned into `./orion_src` and the full run logs and artifacts remain in `./orion_src/runs/...`.

See `REPRODUCE.md` for details and customization.

## Try it on Linux/macOS

```bash
bash scripts/bootstrap_repro.sh
```

## Container (Docker)

```bash
docker build -t discover5 .
docker run --rm -it -v "$PWD/outputs:/app/outputs" discover5
```

---

## Sanity check (fast mode)
Use environment overrides to run a quick subset suitable for CI/tryouts:

Windows PowerShell:
```powershell
$env:REWIRES='0.0,0.2'; $env:REPEATS='3'; $env:B_BUDGET='1000'; $env:R_BUDGET='4000'; $env:BOOTS='120'
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_repro.ps1
```

Linux/macOS:
```bash
REWIRES='0.0,0.2' REPEATS='3' B_BUDGET='1000' R_BUDGET='4000' BOOTS='120' bash scripts/bootstrap_repro.sh
```

Expected directional outcomes (fast mode may be noisy):
- SOA‑1 mean AUC rises from ~0.50 at rewire 0.0 toward ~0.64–0.66 at 0.2.
- Paired ΔAUC (0.2 − 0.0) positive; permutation p typically < 0.05 on full run.

---

License: MIT (inherits from the upstream code).  
Contact: jovanSAPFIONEER
