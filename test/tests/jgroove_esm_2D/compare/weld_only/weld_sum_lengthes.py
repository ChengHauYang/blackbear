import csv
import math

def compute_path_length(csv_file):
    coords = []

    # Read CSV
    with open(csv_file, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            x = float(row["x"])
            y = float(row["y"])
            z = float(row["z"])
            coords.append((x, y, z))

    # Compute sum of distances
    total_length = 0.0
    for i in range(len(coords) - 1):
        x1, y1, z1 = coords[i]
        x2, y2, z2 = coords[i+1]
        total_length += math.dist((x1, y1, z1), (x2, y2, z2))

    return total_length

# ---- Run ----
csv_file = "weld_pass.csv"
length = compute_path_length(csv_file)
print(f"Total weld pass path length = {length:.6f} mm")

