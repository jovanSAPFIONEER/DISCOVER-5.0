Param()
$ErrorActionPreference = 'Stop'

# Config
$RepoUrl = 'https://github.com/jovanSAPFIONEER/Orion'
$PinnedCommit = 'c8582a0025f83120698efb9c970e664c9ca411db'  # Orion commit to pin
$CloneDir = Join-Path $PSScriptRoot '..' | Resolve-Path | ForEach-Object { $_.Path }
$CloneDir = Join-Path $CloneDir 'orion_src'
$OutDir   = Join-Path $PSScriptRoot '..' | Resolve-Path | ForEach-Object { $_.Path }
$OutDir   = Join-Path $OutDir 'outputs'

# Allow environment overrides for CI/fast mode
$BroadcastGain = if ($env:BROADCAST_GAIN) { [double]$env:BROADCAST_GAIN } else { 0.6 }
$Rewires = if ($env:REWIRES) { $env:REWIRES } else { '0.0,0.1,0.2,0.3,0.4' }
$Repeats = if ($env:REPEATS) { [int]$env:REPEATS } else { 12 }
$B = if ($env:B_BUDGET) { [int]$env:B_BUDGET } else { 3000 }
$R = if ($env:R_BUDGET) { [int]$env:R_BUDGET } else { 8000 }
$Boots = if ($env:BOOTS) { [int]$env:BOOTS } else { 300 }
$SkipCaiSweep = if ($env:SKIP_CAI_SWEEP) { [int]$env:SKIP_CAI_SWEEP } else { 0 }

# 1) Clone upstream if needed
if (-not (Test-Path $CloneDir)) {
  Write-Host "==> Cloning upstream repo to $CloneDir"
  git clone $RepoUrl $CloneDir
}

# Checkout pinned commit
Write-Host "==> Checking out pinned commit $PinnedCommit"
git -C $CloneDir fetch --all --tags
git -C $CloneDir checkout $PinnedCommit

# 2) Create venv and install requirements
$py = Join-Path $CloneDir '.venv/Scripts/python.exe'
if (-not (Test-Path $py)) {
  Write-Host '==> Creating virtual environment'
  & python -m venv (Join-Path $CloneDir '.venv')
}
Write-Host '==> Activating venv'
. (Join-Path $CloneDir '.venv/Scripts/Activate.ps1')
# Force headless plotting
$env:MPLBACKEND = if ($env:MPLBACKEND) { $env:MPLBACKEND } else { 'Agg' }
Write-Host '==> Installing requirements'
& python -m pip install --upgrade pip
& python -m pip install -r (Join-Path $CloneDir 'requirements.txt')

# 3) Run pipeline inside the upstream repo
Set-Location $CloneDir
if ($SkipCaiSweep -eq 1) {
  Write-Host '==> Skipping rewire CAI sweep (SKIP_CAI_SWEEP=1)'
} else {
  Write-Host '==> Running rewire sweep (this can take a while)'
  & python scripts/causal_rewire_sweep_cai.py --out runs/rewire_cai_sweep_gain0p6 --rewires $Rewires --broadcast_gain $BroadcastGain --n_mask 60 --n_blink 40 --n_cb 32 --n_dual 40 --boots $Boots
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host '==> Running repeated-CV confirm (or CI fallback)'
if (Test-Path 'scripts/rewire_repeated_cv_sweep.py') {
  & python scripts/rewire_repeated_cv_sweep.py --out runs/rewire_cai_sweep_gain0p6_rep --rewires $Rewires --broadcast_gain $BroadcastGain --repeats $Repeats --B $B --R $R
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
  Write-Host '[warn] upstream scripts/rewire_repeated_cv_sweep.py not found; using CI fallback generator' -ForegroundColor Yellow
  $wrapScripts = Join-Path $PSScriptRoot 'ci_fallback_generate_outputs.py'
  & python $wrapScripts --rep_dir runs/rewire_cai_sweep_gain0p6_rep --rewires $Rewires
}

Write-Host '==> Computing paired deltas and plotting'
$base = 'runs/rewire_cai_sweep_gain0p6_rep/rewire_0p0/seq_auc_confirm_SOA1.json'
$others = @()
foreach ($w in $Rewires.Split(',')) {
  if ($w -ne '0.0') {
    $lbl = $w.Replace('.', 'p')
    $f = "runs/rewire_cai_sweep_gain0p6_rep/rewire_${lbl}/seq_auc_confirm_SOA1.json"
    if (Test-Path $f) { $others += $f }
  }
}
if ((Test-Path $base) -and $others.Count -gt 0) {
  & python scripts/paired_rewire_delta.py --base $base --others $others --out_csv runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv
  if ($LASTEXITCODE -ne 0) { Write-Host '[warn] paired delta failed' -ForegroundColor Yellow }
  if (Test-Path 'runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv') {
    & python scripts/plot_paired_deltas.py --csv runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv --out runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.png
  }
} else {
  Write-Host '[warn] Skipping paired deltas: not enough levels present' -ForegroundColor Yellow
}

# 3b) Combined panel (best-effort; script lives alongside this bootstrap)
try {
  $panelPy = Join-Path $PSScriptRoot 'make_combined_panel.py'
  if (Test-Path $panelPy) {
    & python $panelPy --rep_dir runs/rewire_cai_sweep_gain0p6_rep --out runs/rewire_cai_sweep_gain0p6_rep/combined_rewire_panel.png
  }
} catch { Write-Host "[warn] Combined panel generation failed: $_" -ForegroundColor Yellow }

# 4) Copy outputs back into wrapper repo
Write-Host '==> Exporting key outputs'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
if (Test-Path runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.csv) { Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.csv $OutDir }
if (Test-Path runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.png) { Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.png $OutDir }
if (Test-Path runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv) { Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv $OutDir }
if (Test-Path runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.png) { Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.png $OutDir }
if (Test-Path runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.pdf) { Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.pdf $OutDir }
if (Test-Path runs/rewire_cai_sweep_gain0p6_rep/combined_rewire_panel.png) { Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/combined_rewire_panel.png $OutDir }

Write-Host "==> Done. See $OutDir for outputs."
