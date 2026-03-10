import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# --- Matplotlib settings for LaTeX fonts ---
plt.rcParams.update({
    "text.usetex": True,
    "font.family": "serif",
    "font.serif": ["Times New Roman"],
    "text.latex.preamble": r"\usepackage{amsmath}"
})

# --- Load data ---
df = pd.read_csv("hoop_axial_stress.csv")

x = df["Normalized distance"]
y_hoop = df["Hoop Stress (MPa)"]
y_axial = df["Axial Stress"]

# --- MOOSE horizontal line values (hoop + axial) ---
hoop_vals = [198.555, 194.371, 166.092, 195.357, 181.680]
axial_vals = [48.0219, 43.2991, -14.4747, 57.9736, 8.02026]

legend_labels = [
    "DEI",
    "MOOSE (Point Uz = 0, Vessel Right None, Vessel Top None)",
    "MOOSE (Point Uz = 0, Vessel Right EVBC, Vessel Top None)",
    "MOOSE (Point Uz = 0, Vessel Right Ur = 0, Vessel Top None)",
    "MOOSE (Point None, Vessel Right EVBC, Vessel Top Uz = 0)",
    "MOOSE (Point None, Vessel Right Ur = 0, Vessel Top Uz = 0)"
]


# =====================================================
# ====================== FIGURE 1 =====================
# =========== Hoop-direction Stress (MPa) =============
# =====================================================

fig1, ax1 = plt.subplots(figsize=(6, 4))

# DEI data curve
ax1.plot(
    x, y_hoop,
    marker='o',
    markersize=6,
    markerfacecolor='none',
    color="black",
    linewidth=1.8,
    label="DEI"
)

# Horizontal MOOSE lines
colors = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd"]  # matplotlib defaults
for val, col in zip(hoop_vals, colors):
    ax1.plot(x, np.ones(len(x)) * val, '--', color=col)

# Axes labels
ax1.set_xlabel(r"\text{Normalized hoop-direction distance}")
ax1.set_ylabel(r"\text{Hoop Stress (MPa)}")

# Grid
ax1.grid(True, which="both", ls="--", linewidth=0.6)

# Place legend OUTSIDE the figure (bottom)
fig1.legend(
    legend_labels,
    loc='lower center',
    bbox_to_anchor=(0.5, -0.13),
    ncol=1,
    frameon=True
)

# Create extra space at the bottom for the legend
fig1.subplots_adjust(bottom=0.32)

# Save figures
fig1.savefig("Figure1_Hoop_Stress.pdf", bbox_inches='tight')
fig1.savefig("Figure1_Hoop_Stress.png", dpi=300, bbox_inches='tight')

plt.show()


# =====================================================
# ====================== FIGURE 2 =====================
# ============ Axial-direction Stress (MPa) ============
# =====================================================

fig2, ax2 = plt.subplots(figsize=(6, 4))

# DEI data curve
ax2.plot(
    x, y_axial,
    marker='o',
    markersize=6,
    markerfacecolor='none',
    color="black",
    linewidth=1.8,
    label="DEI"
)

# Horizontal MOOSE lines
for val, col in zip(axial_vals, colors):
    ax2.plot(x, np.ones(len(x)) * val, '--', color=col)

# Axes labels
ax2.set_xlabel(r"\text{Normalized hoop-direction distance}")
ax2.set_ylabel(r"\text{Axial Stress (MPa)}")

# Grid
ax2.grid(True, which="both", ls="--", linewidth=0.6)

# Place legend OUTSIDE the figure (bottom)
fig2.legend(
    legend_labels,
    loc='lower center',
    bbox_to_anchor=(0.5, -0.13),
    ncol=1,
    frameon=True
)

# Create extra space at the bottom for the legend
fig2.subplots_adjust(bottom=0.32)

# Save figures
fig2.savefig("Figure2_Axial_Stress.pdf", bbox_inches='tight')
fig2.savefig("Figure2_Axial_Stress.png", dpi=300, bbox_inches='tight')

plt.show()
