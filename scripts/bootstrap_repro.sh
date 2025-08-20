#!/usr/bin/env bash
set -euo pipefail

# Config
REPO_URL="https://github.com/jovanSAPFIONEER/Orion"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLONE_DIR="$ROOT_DIR/orion_src"
OUT_DIR="$ROOT_DIR/outputs"
BROADCAST_GAIN="0.6"
REWIRES="0.0,0.1,0.2,0.3,0.4"
REPEATS="12"
B="3000"
R="8000"

# 1) Clone upstream if needed
if [ ! -d "$CLONE_DIR" ]; then
  echo "==> Cloning upstream repo to $CLONE_DIR"
  git clone "$REPO_URL" "$CLONE_DIR"
fi

# 2) Create venv and install requirements
if [ ! -d "$CLONE_DIR/.venv" ]; then
  echo "==> Creating virtual environment"
  python3 -m venv "$CLONE_DIR/.venv"
fi
# shellcheck source=/dev/null
source "$CLONE_DIR/.venv/bin/activate"
python -m pip install --upgrade pip
python -m pip install -r "$CLONE_DIR/requirements.txt"

# 3) Run pipeline inside upstream repo
cd "$CLONE_DIR"
echo "==> Running rewire sweep (this can take a while)"
python scripts/causal_rewire_sweep_cai.py --out runs/rewire_cai_sweep_gain0p6 --rewires "$REWIRES" --broadcast_gain "$BROADCAST_GAIN" --n_mask 60 --n_blink 40 --n_cb 32 --n_dual 40 --boots 300

echo "==> Running repeated-CV confirm"
python scripts/rewire_repeated_cv_sweep.py --out runs/rewire_cai_sweep_gain0p6_rep --rewires "$REWIRES" --broadcast_gain "$BROADCAST_GAIN" --repeats "$REPEATS" --B "$B" --R "$R"

echo "==> Computing paired deltas and plotting"
python scripts/paired_rewire_delta.py --base runs/rewire_cai_sweep_gain0p6_rep/rewire_0p0/seq_auc_confirm_SOA1.json --others runs/rewire_cai_sweep_gain0p6_rep/rewire_0p1/seq_auc_confirm_SOA1.json runs/rewire_cai_sweep_gain0p6_rep/rewire_0p2/seq_auc_confirm_SOA1.json runs/rewire_cai_sweep_gain0p6_rep/rewire_0p3/seq_auc_confirm_SOA1.json runs/rewire_cai_sweep_gain0p6_rep/rewire_0p4/seq_auc_confirm_SOA1.json --out_csv runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv
python scripts/plot_paired_deltas.py --csv runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv --out runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.png

# 4) Combined recovery panel
CDIR="$ROOT_DIR/scripts"
python "$CDIR/make_combined_panel.py" --rep_dir runs/rewire_cai_sweep_gain0p6_rep --out runs/rewire_cai_sweep_gain0p6_rep/combined_rewire_panel.png || echo "[warn] Combined panel generation failed"

# 5) Export outputs
mkdir -p "$OUT_DIR"
cp runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.csv "$OUT_DIR" || true
cp runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.png "$OUT_DIR" || true
cp runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv "$OUT_DIR" || true
cp runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.png "$OUT_DIR" || true
cp runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.pdf "$OUT_DIR" || true
cp runs/rewire_cai_sweep_gain0p6_rep/combined_rewire_panel.png "$OUT_DIR" || true

echo "==> Done. See $OUT_DIR for outputs."
