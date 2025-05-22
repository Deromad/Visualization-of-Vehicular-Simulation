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
```
#### Junction (`type`: `junction`)

Represents a junction.

##### Required Fields

| Field     | Type      | Description |
|-----------|-----------|-------------|
| `type`    | `string`  | Must be `"junction"` |
| `id`      | `string`  | Unique identifier for the building |
| `shape`   | `array`   | List of points (`x`, `y`, `z`) forming a non-intersecting polygon |


---

##### Building Example

```json
{
  "type": "junction",
  "id": "J1",
  "shape": [
    {"x": 190, "y": 190, "z": 0},
    {"x": 190, "y": 187.5, "z": 0}]},
    {"x": 187.5, "y": 187.5, "z": 0},
  ]
}
```
#### Road (`type`: `road`)

Represents a junction.
#### Road (`type`: `road`)

Represents road with at least one lane, lanes has to be in order from right to left

##### Required Fields

| Field       | Type      | Description |
|-------------|-----------|-------------|
| `type`      | `string`  | Must be `"road"` |
| `id`        | `string`  | Unique identifier for the road |
| `laneCount` | `integer` | Number of lanes |
| `lanes`     | `array`   | List of lane objects containing individual lane details |

##### Required Fields per Lane Object

| Field            | Type     | Description |
|------------------|----------|-------------|
| `id`             | `string` | Unique identifier for the lane |
| `width`          | `number` | Width of the lane in meters |
| `allowedClasses` | `array`  | List of allowed vehicle classes |
| `canChangeLeft`  | `array`  | Vehicle classes allowed to change to the left if emtpy draw a continous line to the left|
| `canChangeRight` | `array`  | Vehicle classes allowed to change to the right if emtpy draw a continous line to the right|
| `shape`          | `array`  | List of points (`x`, `y`, `z`) defining the lane geometry |
---

##### Building Example

```json
{
  "type": "road",
  "id": "ed",
  "laneCount": 1,
  "lanes": [
    {
      "id": "ed_0",
      "width": 3.2,
      "allowedClasses": [
        "bus"
      ],
      "canChangeLeft": [
        "private", "emergency", "authority", "army", "vip", "pedestrian", "passenger", "hov", "taxi", "bus", "coach", "delivery", "truck", "trailer", "motorcycle", "moped", "bicycle", "evehicle", "tram", "rail_urban", "rail", "rail_electric", "rail_fast", "ship", "container", "cable_car", "subway", "aircraft", "wheelchair", "scooter", "drone", "custom1", "custom2"
      ],
      "canChangeRight": [
        "private", "emergency", "authority", "army", "vip", "pedestrian", "passenger", "hov", "taxi", "bus", "coach", "delivery", "truck", "trailer", "motorcycle", "moped", "bicycle", "evehicle", "tram", "rail_urban", "rail", "rail_electric", "rail_fast", "ship", "container", "cable_car", "subway", "aircraft", "wheelchair", "scooter", "drone", "custom1", "custom2"
      ],
      "shape": [
        {
          "x": 116.3,
          "y": 91.44,
          "z": 0
        },
        {
          "x": 91.44,
          "y": 116.3,
          "z": 0
        }
      ],
      "links": [
        {
          "lane": "ewo2_0",
          "direction": "right"
        }
      ]
    }
  ]
}
```
