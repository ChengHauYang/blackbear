import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# --- Matplotlib LaTeX font settings ---
plt.rcParams.update({
    "text.usetex": True,
    "font.family": "serif",
    "font.serif": ["Times New Roman"],
    "text.latex.preamble": r"\usepackage{amsmath}"
})

# ================================
#  Read DEI CSV
# ================================
df = pd.read_csv("DEI_90deg.csv")
x = df["y"]
y = df["90deg"]
y_downhill = df["Downhill"]
y_uphill = df["Uphill"]

# ================================
#  MOOSE Line Colors (5 cases)
# ================================
moose_colors = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd"]

moose_labels = [
    "MOOSE (Point Uz = 0, Vessel Right None, Vessel Top None)",
    "MOOSE (Point Uz = 0, Vessel Right EVBC, Vessel Top None)",
    "MOOSE (Point Uz = 0, Vessel Right Ur = 0, Vessel Top None)",
    "MOOSE (Point None, Vessel Right EVBC, Vessel Top Uz = 0)",
    "MOOSE (Point None, Vessel Right Ur = 0, Vessel Top Uz = 0)"
]

# ================================
#  Create Figure & Axes
# ================================
fig, ax = plt.subplots(figsize=(6, 4))

# ================================
#  DEI curves
# ================================
ax.plot(
    x, y,
    marker='^',
    markersize=6,
    markerfacecolor='red',
    markeredgecolor='red',
    color="red",
    linewidth=1.8,
    label=r"DEI $90^\circ$"
)

ax.plot(
    x, y_downhill,
    marker='s',
    markersize=6,
    markerfacecolor='green',
    markeredgecolor='green',
    color="green",
    linewidth=1.8,
    label=r"DEI Downhill"
)

ax.plot(
    x, y_uphill,
    marker='D',
    markersize=6,
    markerfacecolor='blue',
    markeredgecolor='blue',
    color="blue",
    linewidth=1.8,
    label=r"DEI Uphill"
)

# ================================
#  Plot all 5 MOOSE cases
# ================================
for i in range(5):
    df_moose = pd.read_csv(f"case{i+1}.csv")
    df_moose.columns = df_moose.columns.str.strip()

    x_moose = -20 - (df_moose["Points:1"] - 109.49)
    y_moose = df_moose["stress_yy"]

    ax.plot(
        x_moose, y_moose,
        linestyle='--',
        color=moose_colors[i],
        linewidth=1.8,
        label=moose_labels[i]
    )

# ================================
#  Axis labels / Limits / Grid
# ================================
ax.set_xlabel(r"\text{y}")
ax.set_ylabel(r"\text{Axial Stress (MPa)}")
ax.set_xlim([-20.0, 60.0])
ax.grid(True, which="both", ls="--", linewidth=0.6)

# ================================
#  Legend outside (bottom)
# ================================
fig.legend(
    loc="lower center",
    bbox_to_anchor=(0.5, -0.18),
    ncol=1,
    fontsize=8,
    frameon=True
)

# Leave extra space at bottom for the legend
fig.subplots_adjust(bottom=0.32)

# ================================
#  Save Figures
# ================================
fig.savefig("axial_stress_over_y_plot.pdf", bbox_inches='tight')
fig.savefig("axial_stress_over_y_plot.png", dpi=300, bbox_inches='tight')

plt.show()
