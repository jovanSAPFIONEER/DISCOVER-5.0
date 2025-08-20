Param()
$ErrorActionPreference = 'Stop'

# Config
$RepoUrl = 'https://github.com/jovanSAPFIONEER/Orion'
$CloneDir = Join-Path $PSScriptRoot '..' | Resolve-Path | ForEach-Object { $_.Path }
$CloneDir = Join-Path $CloneDir 'orion_src'
$OutDir   = Join-Path $PSScriptRoot '..' | Resolve-Path | ForEach-Object { $_.Path }
$OutDir   = Join-Path $OutDir 'outputs'
$BroadcastGain = 0.6
$Rewires = '0.0,0.1,0.2,0.3,0.4'
$Repeats = 12
$B = 3000
$R = 8000

# 1) Clone upstream if needed
if (-not (Test-Path $CloneDir)) {
  Write-Host "==> Cloning upstream repo to $CloneDir"
  git clone $RepoUrl $CloneDir
}

# 2) Create venv and install requirements
$py = Join-Path $CloneDir '.venv/Scripts/python.exe'
if (-not (Test-Path $py)) {
  Write-Host '==> Creating virtual environment'
  & python -m venv (Join-Path $CloneDir '.venv')
}
Write-Host '==> Activating venv'
. (Join-Path $CloneDir '.venv/Scripts/Activate.ps1')
Write-Host '==> Installing requirements'
& python -m pip install --upgrade pip
& python -m pip install -r (Join-Path $CloneDir 'requirements.txt')

# 3) Run pipeline inside the upstream repo
Set-Location $CloneDir
Write-Host '==> Running rewire sweep (this can take a while)'
& python scripts/causal_rewire_sweep_cai.py --out runs/rewire_cai_sweep_gain0p6 --rewires $Rewires --broadcast_gain $BroadcastGain --n_mask 60 --n_blink 40 --n_cb 32 --n_dual 40 --boots 300
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '==> Running repeated-CV confirm'
& python scripts/rewire_repeated_cv_sweep.py --out runs/rewire_cai_sweep_gain0p6_rep --rewires $Rewires --broadcast_gain $BroadcastGain --repeats $Repeats --B $B --R $R
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '==> Computing paired deltas and plotting'
& python scripts/paired_rewire_delta.py --base runs/rewire_cai_sweep_gain0p6_rep/rewire_0p0/seq_auc_confirm_SOA1.json --others runs/rewire_cai_sweep_gain0p6_rep/rewire_0p1/seq_auc_confirm_SOA1.json runs/rewire_cai_sweep_gain0p6_rep/rewire_0p2/seq_auc_confirm_SOA1.json runs/rewire_cai_sweep_gain0p6_rep/rewire_0p3/seq_auc_confirm_SOA1.json runs/rewire_cai_sweep_gain0p6_rep/rewire_0p4/seq_auc_confirm_SOA1.json --out_csv runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& python scripts/plot_paired_deltas.py --csv runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv --out runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.png
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 4) Copy outputs back into wrapper repo
Write-Host '==> Exporting key outputs'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.csv $OutDir
Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.png $OutDir
Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv $OutDir
Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.png $OutDir
Copy-Item -Force runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.pdf $OutDir

Write-Host "==> Done. See $OutDir for outputs."
