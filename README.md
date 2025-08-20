# DISCOVER 5.0 — Reproduction Kit

![CI (fast)](https://github.com/jovanSAPFIONEER/DISCOVER-5.0/actions/workflows/repro.yml/badge.svg) [![Releases](https://img.shields.io/github/v/release/jovanSAPFIONEER/DISCOVER-5.0)](https://github.com/jovanSAPFIONEER/DISCOVER-5.0/releases) [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.16912657.svg)](https://doi.org/10.5281/zenodo.16912657)

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

## Releases and citation

Create a tagged release (triggers release workflow and uploads outputs):
```powershell
git tag v0.1.0
git push origin v0.1.0
```

Citation: see `CITATION.cff` or https://doi.org/10.5281/zenodo.16912657. Zenodo metadata is in `.zenodo.json`.

---

## Interpreting the figures

- `soa1_auc_mean_vs_rewire.(csv|png)`: Mean SOA‑1 AUC vs rewire probability. Expect near‑chance at 0.0 (long‑range lesion) and recovery peaking around 0.2. Error bars reflect across‑repeat variability.
- `paired_deltas.(csv|plot)`: Per‑repeat paired ΔAUC relative to the lesion baseline (0.0). Positive deltas indicate recovery; permutation p‑values quantify significance at each rewire level.
- Takeaway: The early access (SOA‑1) signal depends on long‑range connectivity—removing it collapses the signal, partially restoring it revives the signal in a graded way.

---

License: MIT (inherits from the upstream code).  
Contact: jovanSAPFIONEER
