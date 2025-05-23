# Visualization of Vehicular Simulation  
**Godot 4.x Project**

This project is an open source simulation and visualization tool for vehicular scenarios using Godot Engine 4.x.

> **License:**  
Published under either the **BSD-2-Clause** or **MIT License**, at the user’s discretion.   
**SPDX-License Identifier:** `BSD-2-Clause OR MIT`

---
### Attribution

This project makes use of the following third-party resources:

- **Camera Script**  
  Adapted from: [adamviola/simple-free-look-camera](https://github.com/adamviola/simple-free-look-camera/blob/78109db3bcae477c2a28ef9fe144faa2435f0acb/camera.gd)

- **UI Icons**  
  - [Play Icon](https://www.svgrepo.com/svg/521789/play) from SVG Repo  
  - [Plus Icon](https://www.svgrepo.com/svg/532994/plus) from SVG Repo  
  - [Minus Icon](https://www.svgrepo.com/svg/532960/minus) from SVG Repo

- **Building Facade Texture**  
  - [Facade018A](https://ambientcg.com/a/Facade018A) from AmbientCG (CC0 licensed)

- **RSU and Satellite 3D Models**  
  - From [simplay project on GitLab](https://gitlab.com/Aschenstern/simplay/-/tree/f9de3d7ab8f0baa7d6a8b121bb8cc60aa5425506/)

- **Earth Picture**  
  - From [NASA visible Earth](https://visibleearth.nasa.gov/images/57730/the-blue-marble-land-surface-ocean-color-and-sea-ice/82679l)
## Input File Format

The input file defines the simulation scene. Its a JSONL and consists of:

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

### Dynamic Objects

 These objects include all objects that interact while the scene is playing
 after you initialize all static object write this line it marks the end of the static objects and begins the dynamic ones
 ```json
{
  "type": "update"
}
```

You have to declare start and end points of each timestep you want to do add, everything befor the end will be rendered it doesnt have to be after the begin of the timestep

 ```json
.
.   also calculated and rendered at time 20.7
.
{"type": "timestepBegin", "t": 20.7}
.
.   calculated and rendered at 20.7
.
{"type": "timestepEnd", "t": 20.7}

```
#### Vehicles

You have to add a vehicle, update a vehicle in every timestep it exists and at the end you have to remove it. If you want to change the model of a specific vehicle (like a drone) look into the vehicle.gd script, filter it in the create_vehicle function and instantiate it like instantiate_satellite just with its own function (e.g insantiate_drone)

##### Required Fields Add Vehicle

| Field     | Type      | Description |
|-----------|-----------|-------------|
| `type`    | `string`  | Must be `"vehicleAddition"` |
| `t`       | `number`  | Time at which the vehicle is added  |
| `id`      | `string`  | Unique identifier for the vehicle |
| `vclass`  | `string`  | Vehicle class (e.g., `passenger`, `bus`, `satellite`) |
| `vshape`  | `string`  | Visual model or type (e.g., `passenger`) |
| `color`   | `object`  | Color in RGBA format with keys `r`, `g`, `b`, `a` |
| `length`  | `number`  | Vehicle length in meters |
| `width`   | `number`  | Vehicle width in meters |
| `height`  | `number`  | Vehicle height in meters |
| `pos`     | `object`  | Position with `x`, `y`, `z` coordinates |
| `heading` | `object`  | Direction vector with `x`, `y` components |

---

##### Building Example

```json
{
  "type": "vehicleAddition",
  "t": 0.1,
  "id": "node[1]",
  "vclass": "passenger",
  "vshape": "passenger",
  "color": {
	"r": 255,
	"g": 255,
	"b": 0,
	"a": 255
  },
  "length": 5,
  "width": 1.8,
  "height": 1.5,
  "pos": {
	"x": 129.8,
	"y": 219.9,
	"z": 0
  },
  "heading": {
	"x": 0,
	"y": -1
  }
}
```
##### Required Fields update Vehicle

| Field     | Type      | Description |
|-----------|-----------|-------------|
| `type`    | `string`  | Must be `"vehicleUpdate"` |
| `t`       | `number`  | Simulation time of the update (in seconds) |
| `id`      | `string`  | Unique identifier for the vehicle being updated |
| `pos`     | `object`  | Position of the vehicle with `x`, `y`, `z` coordinates |
| `heading` | `object`  | Heading direction as a unit vector with `x`, `y` components |
| `slope`   | `number`  | Vehicle pitch or slope angle (in degrees or radians) |

##### Building Example

```json
{
  "type": "vehicleUpdate",
  "t": 0.2,
  "id": "node[0]",
  "pos": {
	"x": 20.2,
	"y": 30.2086,
	"z": 0
  },
  "heading": {
	"x": 6.12323e-17,
	"y": 1
  }
}

```
##### Required Fields remove Vehicle

| Field  | Type     | Description |
|--------|----------|-------------|
| `type` | `string` | Must be `"vehicleRemoval"` |
| `t`    | `number` | Time of removal (in seconds) |
| `id`   | `string` | Unique identifier for the vehicle to be removed |
```json
{
  "type": "vehicleRemoval",
  "t": 18.3,
  "id": "node[1]"
}

```

####RSUs
RSUs can also be added, and removed(even though its unlikely that it will be used)

##### Required Fields RSU Addition (`type`: `rsuAddition`)

| Field   | Type     | Description |
|---------|----------|-------------|
| `type`  | `string` | Must be `"rsuAddition"` |
| `t`     | `number` | Simulation time when the RSU is added (in seconds) |
| `id`    | `string` | Unique identifier for the RSU |
| `pos`   | `object` | Position of the RSU, with `x`, `y`, and `z` coordinates |

```json
{
  "type": "rsuAddition",
  "t": 0,
  "id": "rsu[0]",
  "pos": {
	"x": 110,
	"y": 110,
	"z": 3
  }
}
```
##### Required Fields remove RSU (`type`: `rsuRemoval`)

| Field  | Type     | Description |
|--------|----------|-------------|
| `type` | `string` | Must be `"rsuRemoval"` |
| `t`    | `number` | Time of removal (in seconds) |
| `id`   | `string` | Unique identifier for the vehicle to be removed |
```json
{
  "type": "rsuRemoval",
  "t": 100,
  "id": "rsu[0]"
}

```

#### Connectors and LogLines

if you want to illustrate a message between vehicles or rsus (or both of them) you have to split it up into the message with logLineAddition and the visualisation of the connector, you also can just implement one of them if you just want to have a message or a connection. The Connector has to be added and removed, the LogLine only needs to be added


##### Required Fields Log Line Addition (`type`: `logLineAddition`)

| Field     | Type      | Description |
|-----------|-----------|-------------|
| `type`    | `string`  | Must be `"logLineAddition"` |
| `t`       | `number`  | Simulation time when the message is logged (in seconds) |
| `message` | `string`  | The content of the log message |
| `color`   | `object`  | RGBA color of the message text with `r`, `g`, `b`, `a` values |
```json
{
  "type": "logLineAddition",
  "t": 20.7002,
  "message": "Car node[10] is rerouting to avoid road eei",
  "color": {
	"r": 0,
	"g": 0,
	"b": 0,
	"a": 255
  }
}

```


##### Required Fields Connector Addition (`type`: `connectorAddition`)

| Field     | Type     | Description |
|-----------|----------|-------------|
| `type`    | `string` | Must be `"connectorAddition"` |
| `t`       | `number` | Simulation time when the connector is added (in seconds) |
| `id`      | `string` | Unique identifier for the connector |
| `from_id` | `string` | ID of the source entity |
| `to_id`   | `string` | ID of the target entity |
| `color`   | `object` | RGBA color of the connector with `r`, `g`, `b`, `a` values |
```json
{
  "type": "connectorAddition",
  "t": 20.7002,
  "id": "tmp_id_112",
  "from_id": "node[4]",
  "to_id": "node[10]",
  "color": {
	"r": 0,
	"g": 0,
	"b": 255,
	"a": 255
  }
}
```
##### Required Fields Connector Removal (`type`: `connectorRemoval`)

| Field  | Type     | Description |
|--------|----------|-------------|
| `type` | `string` | Must be `"connectorRemoval"` |
| `t`    | `number` | Simulation time when the connector is removed (in seconds) |
| `id`   | `string` | Unique identifier of the connector to be removed |

```json
{
  "type": "connectorRemoval",
  "t": 21.7002,
  "id": "tmp_id_112"
}
```
#### Emojis and Bubbles
Thes annotations will pop up above the vehicle emojis show emojis and bubbles text. They need to be added and removed from the vehicle

##### Required Fields Emoji Addition (`type`: `emojiAddition`)

| Field     | Type     | Description |
|-----------|----------|-------------|
| `type`    | `string` | Must be `"emojiAddition"` |
| `t`       | `number` | Simulation time when the emoji is shown (in seconds) |
| `id`      | `string` | Unique identifier for the emoji event |
| `to_id`   | `string` | ID of the entity the emoji is attached to |
| `message` | `string` | The emoji character to display |
| `color`   | `object` | RGBA color of the emoji with `r`, `g`, `b`, `a` values |

```json
{
  "type": "emojiAddition",
  "t": 20.7002,
  "id": "tmp_id_116",
  "to_id": "node[10]",
  "message": "🌟",
  "color": {
	"r": 255,
	"g": 0,
	"b": 0,
	"a": 255
  }
}
```
##### Required Fields Bubble Addition (`type`: `bubbleAddition`)

| Field     | Type     | Description |
|-----------|----------|-------------|
| `type`    | `string` | Must be `"bubbleAddition"` |
| `t`       | `number` | Simulation time when the bubble appears (in seconds) |
| `id`      | `string` | Unique identifier for the bubble event |
| `to_id`   | `string` | ID of the entity the bubble is attached to |
| `message` | `string` | Text message displayed in the bubble |
| `color`   | `object` | RGBA color of the bubble with `r`, `g`, `b`, `a` values |

```json
{
  "type": "bubbleAddition",
  "t": 20.7,
  "id": "tmp_id_111",
  "to_id": "node[4]",
  "message": "stuck",
  "color": {
	"r": 255,
	"g": 0,
	"b": 0,
	"a": 255
  }
}
```

##### Required Fields Emoji Removal (`type`: `emojiRemoval`)

| Field  | Type     | Description |
|--------|----------|-------------|
| `type` | `string` | Must be `"emojiRemoval"` |
| `t`    | `number` | Simulation time when the emoji is removed (in seconds) |
| `id`   | `string` | Unique identifier of the emoji event to be removed |

```json
{
  "type": "emojiRemoval",
  "t": 21.7002,
  "id": "tmp_id_116"
}
```
##### Required Fields Bubble Removal (`type`: `bubbleRemoval`)

| Field  | Type     | Description |
|--------|----------|-------------|
| `type` | `string` | Must be `"bubbleRemoval"` |
| `t`    | `number` | Simulation time when the bubble is removed (in seconds) |
| `id`   | `string` | Unique identifier of the bubble event to be removed |

```json
{
  "type": "bubbleRemoval",
  "t": 21.7,
  "id": "tmp_id_111"
}
```
#### Polygons and Markers
These annotations will be generated in the world with global positions, they are annotations to help debug your simulation. There are two types the Polygon which generates a polygon in the scene and the marker which generates Text in the Scene which is not mounted to a vehicle

##### Required Fields Polygon Addition (`type`: `polygonAddition`)

| Field    | Type      | Description |
|----------|-----------|-------------|
| `type`   | `string`  | Must be `"polygonAddition"` |
| `t`      | `number`  | Simulation time when the polygon is added (in seconds) |
| `id`     | `string`  | Unique identifier for the polygon |
| `shape`  | `array`   | List of points defining the polygon, each with `x`, `y`, and `z` coordinates |
| `color`  | `object`  | RGBA color of the polygon with `r`, `g`, `b`, `a` values |

```json
{
  "type": "polygonAddition",
  "t": 20.7002,
  "id": "tmp_id_115",
  "shape": [
	{"x": 137.431, "y": 122.4, "z": 0.1},
	{"x": 139.431, "y": 122.4, "z": 0.1},
	{"x": 139.431, "y": 124.4, "z": 0.1},
	{"x": 137.431, "y": 124.4, "z": 0.1}
  ],
  "color": {
	"r": 255,
	"g": 0,
	"b": 0,
	"a": 255
  }
}
```
##### Required Fields Marker Addition (`type`: `markerAddition`)

| Field     | Type     | Description |
|-----------|----------|-------------|
| `type`    | `string` | Must be `"markerAddition"` |
| `t`       | `number` | Simulation time when the marker is added (in seconds) |
| `id`      | `string` | Unique identifier for the marker |
| `message` | `string` | Text message displayed on the marker |
| `pos`     | `object` | Position of the marker with `x`, `y`, and `z` coordinates |

```json
{
  "type": "markerAddition",
  "t": 20.7002,
  "id": "tmp_id_114",
  "message": "blocked",
  "pos": {
	"x": 138.431,
	"y": 123.4,
	"z": 5
  }
}
```
##### Required Fields Polygon Removal (`type`: `polygonRemoval`)

| Field  | Type     | Description |
|--------|----------|-------------|
| `type` | `string` | Must be `"polygonRemoval"` |
| `t`    | `number` | Simulation time when the polygon is removed (in seconds) |
| `id`   | `string` | Unique identifier of the polygon to be removed |

```json
{
  "type": "polygonRemoval",
  "t": 21.7002,
  "id": "tmp_id_115"
}
```
##### Required Fields Marker Removal (`type`: `markerRemoval`)

| Field  | Type     | Description |
|--------|----------|-------------|
| `type` | `string` | Must be `"markerRemoval"` |
| `t`    | `number` | Simulation time when the marker is removed (in seconds) |
| `id`   | `string` | Unique identifier of the marker to be removed |

```json
{
  "type": "markerRemoval",
  "t": 21.7002,
  "id": "tmp_id_114"
}
```

###Prisms
Prisms are also an annotation but they basically have to be used as a heatmap for e.g. vehicle density. They have to be instantiated with the static Objects so before the "type": "update" anad can then be updated with the dynamic objects. The only property that can be changed is the height of the prism:
##### Required Fields Prism Addition (`type`: `prismAddition`)

| Field    | Type      | Description |
|----------|-----------|-------------|
| `type`   | `string`  | Must be `"prismAddition"` |
| `t`      | `number`  | Simulation time when the prism is added (in seconds) |
| `id`     | `string`  | Unique identifier for the prism |
| `shape`  | `array`   | List of points defining the base polygon with `x` and `y` coordinates |
| `z_from` | `number`  | Starting height (base) of the prism |
| `z_to`   | `number`  | Ending height (top) of the prism |
| `color`  | `object`  | RGBA color of the prism with `r`, `g`, `b`, `a` values |

```json
{
  "type": "prismAddition",
  "t": 0,
  "id": "heatmap_0_0",
  "shape": [
	{"x": 0, "y": 0},
	{"x": 35.7143, "y": 0},
	{"x": 35.7143, "y": 35.7143},
	{"x": 0, "y": 35.7143}
  ],
  "z_from": -1.1,
  "z_to": 0,
  "color": {
	"r": 0,
	"g": 0,
	"b": 238,
	"a": 10
  }
}
```
##### Required Fields Prism Update (`type`: `prismUpdate`)

| Field  | Type     | Description |
|--------|----------|-------------|
| `type` | `string` | Must be `"prismUpdate"` |
| `t`    | `number` | Simulation time when the prism is updated (in seconds) |
| `id`   | `string` | Unique identifier of the prism to update |
| `z_to` | `number` | New top height of the prism |

```json
{
  "type": "prismUpdate",
  "t": 0.1,
  "id": "heatmap_0_0",
  "z_to": 1
}
```

###Traffic Lights
Like Prisms Traffic Lights have to be instantiated with the static objects but can be updated while the Scene is running.

The traffic light system currently supports the following states:
red, green_major, green_minor, yellow_major, yellow_minor, red_yellow, off_blinking, off_nosignal, and stop. The colors can be seen in the material folder, the names of the materials are the same as the states.

These states cover the typical signaling modes for traffic lights, including standard colors, blinking, off, and stop signals.
##### Required Fields Traffic Light (`type`: `trafficLight`)

| Field           | Type              | Description |
|-----------------|-------------------|-------------|
| `type`          | `string`          | Must be `"trafficLight"` |
| `id`            | `string`          | Unique identifier for the traffic light |
| `controlledLinks` | `object`        | Map from integer keys to arrays of link objects, each containing `incoming` and `outgoing` lane IDs |
| `state`         | `array`           | List of strings representing the state of each controlled link (e.g., `"green_major"`, `"red"`, etc.) |

```json
{
  "type": "trafficLight",
  "id": "J0",
  "controlledLinks": {
	"0": [{"incoming": "eni1_0", "outgoing": "eso_0"}],
	"1": [{"incoming": "eni1_1", "outgoing": "eso_1"}],
	"2": [{"incoming": "eni1_1", "outgoing": "eeo_1"}],
	"3": [{"incoming": "eei_0", "outgoing": "eno_0"}],
	"4": [{"incoming": "eei_0", "outgoing": "ewo1_0"}],
	"5": [{"incoming": "eei_1", "outgoing": "ewo1_1"}],
	"6": [{"incoming": "eei_1", "outgoing": "eso_1"}],
	"7": [{"incoming": "esi_0", "outgoing": "eeo_0"}],
	"8": [{"incoming": "esi_0", "outgoing": "eno_0"}],
	"9": [{"incoming": "esi_1", "outgoing": "eno_1"}],
	"10": [{"incoming": "esi_1", "outgoing": "ewo1_1"}],
	"11": [{"incoming": "ef1_0", "outgoing": "ef2_0"}],
	"12": [{"incoming": "ewi_0", "outgoing": "eso_0"}],
	"13": [{"incoming": "ewi_0", "outgoing": "eeo_0"}],
	"14": [{"incoming": "ewi_1", "outgoing": "eeo_1"}],
	"15": [{"incoming": "ewi_1", "outgoing": "eno_1"}]
  },
  "state": [
	"green_major", "green_major", "green_minor", "red", "red", "red", "red",
	"green_major", "green_major", "green_major", "green_minor", "red", "red",
	"red", "red", "red"
  ]
}
```
##### Required Fields Traffic Light Update (`type`: `trafficLightUpdate`)

| Field  | Type     | Description |
|--------|----------|-------------|
| `type` | `string` | Must be `"trafficLightUpdate"` |
| `t`    | `number` | Simulation time when the traffic light state is updated (in seconds) |
| `id`   | `string` | Unique identifier of the traffic light to update |
| `state`| `array`  | Updated list of states for each controlled link |

```json
{
  "type": "trafficLightUpdate",
  "t": 0.1,
  "id": "J0",
  "state": [
	"green_major", "green_major", "green_minor", "red", "red", "red", "red",
	"green_major", "green_major", "green_major", "green_minor", "red", "red",
	"red", "red", "red"
  ]
}
```
