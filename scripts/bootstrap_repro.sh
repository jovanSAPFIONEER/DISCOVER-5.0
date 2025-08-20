#!/usr/bin/env bash
set -euo pipefail

# Config
REPO_URL="https://github.com/jovanSAPFIONEER/Orion"
PINNED_COMMIT="c8582a0025f83120698efb9c970e664c9ca411db"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLONE_DIR="$ROOT_DIR/orion_src"
OUT_DIR="$ROOT_DIR/outputs"
BROADCAST_GAIN="${BROADCAST_GAIN:-0.6}"
REWIRES="${REWIRES:-0.0,0.1,0.2,0.3,0.4}"
REPEATS="${REPEATS:-12}"
B="${B_BUDGET:-3000}"
R="${R_BUDGET:-8000}"
BOOTS="${BOOTS:-300}"
SKIP_CAI_SWEEP="${SKIP_CAI_SWEEP:-0}"

# 1) Clone upstream if needed
if [ ! -d "$CLONE_DIR" ]; then
  echo "==> Cloning upstream repo to $CLONE_DIR"
  git clone "$REPO_URL" "$CLONE_DIR"
fi

# Checkout pinned commit
echo "==> Checking out pinned commit $PINNED_COMMIT"
git -C "$CLONE_DIR" fetch --all --tags
git -C "$CLONE_DIR" checkout "$PINNED_COMMIT"

# 2) Create venv and install requirements
if [ ! -d "$CLONE_DIR/.venv" ]; then
  echo "==> Creating virtual environment"
  python3 -m venv "$CLONE_DIR/.venv"
fi
# shellcheck source=/dev/null
source "$CLONE_DIR/.venv/bin/activate"
# Force headless plotting
export MPLBACKEND=${MPLBACKEND:-Agg}
python -m pip install --upgrade pip
python -m pip install -r "$CLONE_DIR/requirements.txt"

# 3) Run pipeline inside upstream repo
cd "$CLONE_DIR"
if [ "$SKIP_CAI_SWEEP" != "1" ]; then
  echo "==> Running rewire sweep (this can take a while)"
  python scripts/causal_rewire_sweep_cai.py --out runs/rewire_cai_sweep_gain0p6 --rewires "$REWIRES" --broadcast_gain "$BROADCAST_GAIN" --n_mask 60 --n_blink 40 --n_cb 32 --n_dual 40 --boots "$BOOTS"
else
  echo "==> Skipping rewire CAI sweep (SKIP_CAI_SWEEP=1)"
fi

echo "==> Running repeated-CV confirm"
python scripts/rewire_repeated_cv_sweep.py --out runs/rewire_cai_sweep_gain0p6_rep --rewires "$REWIRES" --broadcast_gain "$BROADCAST_GAIN" --repeats "$REPEATS" --B "$B" --R "$R"

echo "==> Computing paired deltas and plotting"
# Build dynamic list of 'others' from REWIRES (excluding 0.0) and only include existing files
OTHERS=()
IFS=',' read -r -a rw_arr <<< "$REWIRES"
for w in "${rw_arr[@]}"; do
  if [ "$w" != "0.0" ]; then
    lbl=${w//./p}
    f="runs/rewire_cai_sweep_gain0p6_rep/rewire_${lbl}/seq_auc_confirm_SOA1.json"
    [ -f "$f" ] && OTHERS+=("$f")
  fi
done

BASE="runs/rewire_cai_sweep_gain0p6_rep/rewire_0p0/seq_auc_confirm_SOA1.json"
if [ -f "$BASE" ] && [ ${#OTHERS[@]} -gt 0 ]; then
  python scripts/paired_rewire_delta.py --base "$BASE" --others "${OTHERS[@]}" --out_csv runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv || echo "[warn] paired delta failed"
  [ -f runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv ] && python scripts/plot_paired_deltas.py --csv runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv --out runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.png || true
else
  echo "[warn] Skipping paired deltas: not enough levels present"
fi

# 4) Combined recovery panel
CDIR_ORION="$ROOT_DIR/scripts"
# combined panel script is provided in wrapper repo under scripts/
python "$CDIR_ORION/make_combined_panel.py" --rep_dir runs/rewire_cai_sweep_gain0p6_rep --out runs/rewire_cai_sweep_gain0p6_rep/combined_rewire_panel.png || echo "[warn] Combined panel generation failed"

# 5) Export outputs
mkdir -p "$OUT_DIR"
[ -f runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.csv ] && cp runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.csv "$OUT_DIR" || true
[ -f runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.png ] && cp runs/rewire_cai_sweep_gain0p6_rep/soa1_auc_mean_vs_rewire.png "$OUT_DIR" || true
[ -f runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv ] && cp runs/rewire_cai_sweep_gain0p6_rep/paired_deltas.csv "$OUT_DIR" || true
[ -f runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.png ] && cp runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.png "$OUT_DIR" || true
[ -f runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.pdf ] && cp runs/rewire_cai_sweep_gain0p6_rep/paired_deltas_plot.pdf "$OUT_DIR" || true
[ -f runs/rewire_cai_sweep_gain0p6_rep/combined_rewire_panel.png ] && cp runs/rewire_cai_sweep_gain0p6_rep/combined_rewire_panel.png "$OUT_DIR" || true

echo "==> Done. See $OUT_DIR for outputs."
