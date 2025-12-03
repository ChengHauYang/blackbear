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
#  Read MOOSE CSV
# ================================
df_moose = pd.read_csv("axial_MOOSE.csv")

df_moose.columns = df_moose.columns.str.strip()   # clean column names
print("MOOSE columns:", df_moose.columns)

x_moose = df_moose["y"]
y_moose = df_moose["stress_yy"]

# ================================
#  Plot
# ================================
plt.figure(figsize=(6, 4))

plt.plot(
    x, y,
    marker='^',
    markersize=6,
    markerfacecolor='red',
    markeredgecolor='red',
    color="red",
    linewidth=1.8,
    label=r"DEI $90^\circ$"
)

plt.plot(
    x, y_downhill,
    marker='s',
    markersize=6,
    markerfacecolor='green',
    markeredgecolor='green',
    color="green",
    linewidth=1.8,
    label=r"DEI Downhill"
)

plt.plot(
    x, y_uphill,
    marker='D',
    markersize=6,
    markerfacecolor='blue',
    markeredgecolor='blue',
    color="blue",
    linewidth=1.8,
    label=r"DEI Uphill"
)

plt.plot(
    x_moose, y_moose,
    color="black",
    linewidth=1.8,
    label="MOOSE"
)

plt.xlabel(r"\text{y}")
plt.ylabel(r"\text{Axial Stress (MPa)}")
plt.xlim([-20.0, 60.0])

plt.grid(True, which="both", ls="--", linewidth=0.6)
plt.legend()

plt.tight_layout()
plt.savefig("axial_stress_over_y_plot.pdf")
plt.savefig("axial_stress_over_y_plot.png", dpi=300)
plt.show()
