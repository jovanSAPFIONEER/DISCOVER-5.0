# DISCOVER 5.0 — Reproduction Kit

[![CI (fast)](https://github.com/jovanSAPFIONEER/DISCOVER-5.0/actions/workflows/repro.yml/badge.svg)](https://github.com/jovanSAPFIONEER/DISCOVER-5.0/actions/workflows/repro.yml) [![Releases](https://img.shields.io/github/v/release/jovanSAPFIONEER/DISCOVER-5.0)](https://github.com/jovanSAPFIONEER/DISCOVER-5.0/releases) [![Tag](https://img.shields.io/github/v/tag/jovanSAPFIONEER/DISCOVER-5.0?label=tag&sort=semver)](https://github.com/jovanSAPFIONEER/DISCOVER-5.0/tags) [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.16912656.svg)](https://doi.org/10.5281/zenodo.16912656)

A minimal, one-command reproduction kit for the DISCOVER/Orion causal rewire result:
“Lesioning long‑range connectivity eliminates the early access (SOA‑1) signal; restoring it recovers the signal in a graded way.”
The numbers that were used in the Reproduction kit was from these repos: https://github.com/jovanSAPFIONEER/DISCOVER,
https://github.com/jovanSAPFIONEER/Orion

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

Citation: see `CITATION.cff` or https://doi.org/10.5281/zenodo.16912656 (concept DOI; always points to the latest version). Zenodo metadata is in `.zenodo.json`.

---

## Interpreting the figures

- `soa1_auc_mean_vs_rewire.(csv|png)`: Mean SOA‑1 AUC vs rewire probability. Expect near‑chance at 0.0 (long‑range lesion) and recovery peaking around 0.2. Error bars reflect across‑repeat variability.
- `paired_deltas.(csv|plot)`: Per‑repeat paired ΔAUC relative to the lesion baseline (0.0). Positive deltas indicate recovery; permutation p‑values quantify significance at each rewire level.
- Takeaway: The early access (SOA‑1) signal depends on long‑range connectivity—removing it collapses the signal, partially restoring it revives the signal in a graded way.

---

## How to cite

If you use this reproduction kit or its outputs, please cite:

DISCOVER 5.0 — Reproduction Kit for Causal Rewire Recovery (SOA‑1). Version v0.1.2. DOI: https://doi.org/10.5281/zenodo.16912656

BibTeX (example):

@software{discover5_repro_0_1_2,
	title        = {DISCOVER 5.0 — Reproduction Kit for Causal Rewire Recovery (SOA-1)},
	author       = {Jovan},
	year         = {2025},
	version      = {v0.1.2},
	doi          = {10.5281/zenodo.16912656},
	url          = {https://github.com/jovanSAPFIONEER/DISCOVER-5.0}
}

---

License: MIT (inherits from the upstream code).  
Contact: jovanSAPFIONEER
