#!/usr/bin/env python3
"""
Combine the mean AUC vs rewire curve with the paired delta p-values into a single panel.
Reads from a repeated-CV sweep directory and writes a PNG.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rep_dir', required=True, help='Directory with soa1_auc_mean_vs_rewire.csv and paired_deltas.csv')
    ap.add_argument('--out', required=True, help='Output PNG path')
    args = ap.parse_args()

    rep = Path(args.rep_dir)
    df_mean = pd.read_csv(rep / 'soa1_auc_mean_vs_rewire.csv')
    df_delta = pd.read_csv(rep / 'paired_deltas.csv')

    # Extract rewire from path like .../rewire_0p2/seq_....json -> 0.2
    def to_rewire(p: str) -> float:
        import re
        m = re.search(r"rewire_(\d+)p(\d+)", p)
        if not m:
            return float('nan')
        return float(f"{int(m.group(1))}.{int(m.group(2))}")

    df_delta['rewire_p'] = df_delta['other_json'].astype(str).map(to_rewire)
    df_delta = df_delta[np.isfinite(df_delta['rewire_p'])].copy()
    df_delta = df_delta.sort_values('rewire_p')

    fig, axes = plt.subplots(1, 2, figsize=(10, 4), constrained_layout=True)

    # Left: mean AUC ± SD
    ax = axes[0]
    x = df_mean['rewire_p'].to_numpy(dtype=float)
    y = df_mean['AUC_mean'].to_numpy(dtype=float)
    yerr = df_mean['AUC_std'].to_numpy(dtype=float)
    ax.errorbar(x, y, yerr=yerr, fmt='-o', capsize=3, color='#7b2cbf')
    ax.axhline(0.5, color='gray', linestyle='--', linewidth=1)
    ax.set_xlabel('Rewire probability')
    ax.set_ylabel('SOA 1 AUC (mean ± SD)')
    ax.set_title('Repeated-CV mean AUC vs rewire')

    # Right: paired deltas with p-values
    ax = axes[1]
    xd = df_delta['rewire_p'].to_numpy(dtype=float)
    yd = df_delta['delta_mean'].to_numpy(dtype=float)
    yde = df_delta['delta_std'].to_numpy(dtype=float)
    pv = df_delta['perm_p'].to_numpy(dtype=float)
    ax.errorbar(xd, yd, yerr=yde, fmt='-o', capsize=3, color='#1e88e5')
    ax.axhline(0.0, color='gray', linestyle='--', linewidth=1)
    for xi, yi, pi in zip(xd, yd, pv):
        ax.text(xi, yi + (0.005 if yi>=0 else -0.005), f"p={pi:.3g}", ha='center', va='bottom' if yi>=0 else 'top', fontsize=9)
    ax.set_xlabel('Rewire probability (vs baseline 0.0)')
    ax.set_ylabel('Paired ΔAUC (mean ± SD)')
    ax.set_title('Paired improvement with permutation p-values')

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=180)
    print('Wrote:', args.out)


if __name__ == '__main__':
    main()
