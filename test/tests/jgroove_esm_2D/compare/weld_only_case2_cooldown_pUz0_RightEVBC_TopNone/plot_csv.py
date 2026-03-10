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

# --- Read CSV ---
df = pd.read_csv("hoop_axial_stress.csv")

x = df["Normalized distance"]
y = df["Hoop Stress (MPa)"]

# --- Plot ---
plt.figure(figsize=(6, 4))

plt.plot(
    x, y,
    marker='o',
    markersize=6,
    markerfacecolor='none',
    color="black",
    linewidth=1.8
)
plt.plot(x, np.ones(len(x)) * 152.531, '--')
plt.plot(x, np.ones(len(x)) * 199.854, '--')

plt.legend(["DEI", "MOOSE", "MOOSE (w/ EVBC)"])


plt.xlabel(r"\text{Normalized hoop-direction distance}")
plt.ylabel(r"\text{Hoop Stress (MPa)}")

plt.grid(True, which="both", ls="--", linewidth=0.6)

plt.tight_layout()
plt.savefig("hoop_axial_stress_plot.pdf")
plt.savefig("hoop_stress_plot.png", dpi=300)
plt.show()


y2 = df["Axial Stress"]

# --- Plot ---
plt.figure(figsize=(6, 4))

plt.plot(
    x, y2,
    marker='o',
    markersize=6,
    markerfacecolor='none',
    color="black",
    linewidth=1.8
)
plt.plot(x, np.ones(len(x)) * 20.1719, '--')

plt.plot(x, np.ones(len(x)) * 48.9316, '--')

plt.legend(["DEI", "MOOSE", "MOOSE (w/ EVBC)"])


plt.xlabel(r"\text{Normalized hoop-direction distance}")
plt.ylabel(r"\text{Axial Stress (MPa)}")

plt.grid(True, which="both", ls="--", linewidth=0.6)

plt.tight_layout()
plt.savefig("axial_stress_plot.pdf")
plt.savefig("axial_stress_plot.png", dpi=300)
plt.show()
