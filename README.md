# Visualization of Vehicular Simulation  
**Godot 4.x Project**

This project is an open source simulation and visualization tool for vehicular scenarios using Godot Engine 4.x.

> **License:**  
Published under either the **BSD-2-Clause** or **MIT License**, at the user’s discretion.  
**SPDX-License Identifier:** `BSD-2-Clause OR MIT`

---

## Input File Format

The input file defines the simulation scene. It consists of:

- A **first line** to define global parameters.
- Subsequent lines for **static objects** like buildings, streets, junctions, and traffic lights.

---

### First Line – Global Scenario Settings

This line must be a valid JSON object.

| Key     | Required | Description |
|---------|----------|-------------|
| `time`  | ✅        | Total duration of the scenario in simulation units. |
| `kood`  | ❌        | Coordinate `[x, y]`. If present, the scene is treated as a **satellite view**. This will render Earth and increase camera speed. Omit this if you're not focusing on satellite perspectives. |

**Example:**
```json
{"time": 200, "kood": [0, 0]}
```

### Static Objects

 These objects include buildings, junctions, roads, and traffic lights. The lines can be added **in any order** after the first line of the input file.

---

#### Common Structure

Each static object is defined as a **JSON object on a single line** with at least the following:

- A `type` field
- An `id` (unique within the file)
- Type-specific fields

---

#### Buildings (`type`: `building_2d5`)

Represents a 2.5D building drawn from a polygonal base.

##### Required Fields

| Field     | Type      | Description |
|-----------|-----------|-------------|
| `type`    | `string`  | Must be `"building_2d5"` |
| `id`      | `string`  | Unique identifier for the building |
| `shape`   | `array`   | List of points (`x`, `y`, `z`) forming a non-intersecting polygon |
| `color`   | `object`  | RGBA color object defining the building color |

##### Shape Field (Polygon)

The `shape` is an array of at least **3** points to form a closed polygon. Each point must have:

- `x`: float or int
- `y`: float or int
- `z`: typically 0 for 2.5D top-down view

**Note:** The final point **should close the polygon** by repeating the first point.

##### Color Field

Each color is an RGBA object:

- `r`: red (0–255)
- `g`: green (0–255)
- `b`: blue (0–255)
- `a`: alpha (opacity) (0–255)

---

##### Building Example

```json
{
  "type": "building_2d5",
  "id": "po_0",
  "shape": [
    {"x": 140, "y": 140, "z": 0},
    {"x": 185, "y": 140, "z": 0},
    {"x": 185, "y": 185, "z": 0},
    {"x": 140, "y": 185, "z": 0},
    {"x": 140, "y": 140, "z": 0}
  ],
  "color": {"r": 255, "g": 0, "b": 0, "a": 255}
}
