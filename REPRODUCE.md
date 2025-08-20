# Reproduce the Causal Rewire Result (Windows PowerShell)

This repo is a thin wrapper that pulls the upstream Orion codebase and runs the full lesion→recovery pipeline automatically.

## One-command run

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_repro.ps1
```

What it does:
1) Clones the upstream repo into `./orion_src` (if not present)
2) Creates `./orion_src/.venv` and installs requirements
3) Runs the rewire sweep and repeated‑CV confirm
4) Computes paired ΔAUC vs baseline (0.0) and plots p‑values
5) Copies the key CSV/PNG/PDF outputs into `./outputs`

## Customize
Edit defaults at the top of `scripts/bootstrap_repro.ps1`:
- $BroadcastGain (default 0.6)
- $Rewires (default '0.0,0.1,0.2,0.3,0.4')
- $Repeats (default 12)
- $B, $R for bootstrap/permutation budgets

## Outputs
- outputs/soa1_auc_mean_vs_rewire.(csv|png)
- outputs/paired_deltas.csv
- outputs/paired_deltas_plot.(png|pdf)

Full run artifacts remain in `./orion_src/runs/...`.
