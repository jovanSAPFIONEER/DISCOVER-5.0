# DISCOVER 5.0 — Reproduction Kit

![CI](https://github.com/jovanSAPFIONEER/DISCOVER-5.0/actions/workflows/repro.yml/badge.svg)

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

License: MIT (inherits from the upstream code).  
Contact: jovanSAPFIONEER
