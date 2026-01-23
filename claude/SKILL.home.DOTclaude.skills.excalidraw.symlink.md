---
name: excalidraw
description: Create valid .excalidraw JSON files for architecture diagrams, flowcharts, and sketches. Use when asked to generate Excalidraw diagrams, create diagram files, or export drawings to Excalidraw format.
---

# Excalidraw File Creation

Create valid `.excalidraw` JSON files that can be imported into Excalidraw.

## File Structure

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [...],
  "appState": {
    "gridSize": 20,
    "gridStep": 5,
    "gridModeEnabled": false,
    "viewBackgroundColor": "#ffffff"
  },
  "files": {}
}
```

## Element Base Properties

All elements require these properties:

```json
{
  "id": "unique-id",
  "type": "rectangle",
  "x": 100,
  "y": 100,
  "width": 200,
  "height": 100,
  "angle": 0,
  "strokeColor": "#1e1e1e",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 1,
  "opacity": 100,
  "seed": 12345,
  "version": 1,
  "versionNonce": 67890,
  "index": "a0",
  "isDeleted": false,
  "groupIds": [],
  "frameId": null,
  "boundElements": null,
  "updated": 1706000000000,
  "link": null,
  "locked": false
}
```

### Property Reference

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique identifier |
| `type` | string | Element type (see below) |
| `x`, `y` | number | Position coordinates |
| `width`, `height` | number | Dimensions |
| `angle` | number | Rotation in radians (0-2π) |
| `strokeColor` | string | Border color (`#hex` or `"transparent"`) |
| `backgroundColor` | string | Fill color (`#hex` or `"transparent"`) |
| `fillStyle` | string | `"solid"`, `"hachure"`, `"cross-hatch"`, `"zigzag"` |
| `strokeWidth` | number | Line thickness (1=thin, 2=normal, 4=bold) |
| `strokeStyle` | string | `"solid"`, `"dashed"`, `"dotted"` |
| `roughness` | number | 0=architect, 1=artist, 2=cartoonist |
| `opacity` | number | 0-100 |
| `seed` | number | Random seed for hand-drawn look |
| `roundness` | object/null | `{"type": 3}` for rounded corners, `null` for sharp |

## Element Types

### Rectangle, Diamond, Ellipse

Basic shapes - use base properties only.

```json
{"type": "rectangle", "roundness": {"type": 3}}
{"type": "diamond", "roundness": {"type": 2}}
{"type": "ellipse", "roundness": {"type": 2}}
```

### Text

```json
{
  "type": "text",
  "text": "Hello World",
  "fontSize": 20,
  "fontFamily": 1,
  "textAlign": "left",
  "verticalAlign": "top",
  "containerId": null,
  "originalText": "Hello World",
  "autoResize": true,
  "lineHeight": 1.25
}
```

**Font Families:** 1=Virgil (hand-drawn), 2=Helvetica, 3=Cascadia (code)

**Text Alignment:** `"left"`, `"center"`, `"right"`

**Vertical Align:** `"top"`, `"middle"`, `"bottom"`

### Text Inside Shapes (Contained Text)

To put text inside a shape:

1. Shape must have `boundElements` referencing the text:
```json
{
  "id": "shape-1",
  "type": "rectangle",
  "boundElements": [{"id": "text-1", "type": "text"}]
}
```

2. Text must reference the container:
```json
{
  "id": "text-1",
  "type": "text",
  "containerId": "shape-1",
  "verticalAlign": "middle",
  "textAlign": "center"
}
```

### Arrow Labels (Text on Arrows)

To add a label to an arrow (like "getPresignedUrl()" on a connection), use the same binding pattern as text in shapes:

1. Arrow must have `boundElements` referencing the label:
```json
{
  "id": "arrow-1",
  "type": "arrow",
  "boundElements": [{"id": "arrow-label", "type": "text"}]
}
```

2. Text must reference the arrow as its container:
```json
{
  "id": "arrow-label",
  "type": "text",
  "text": "getPresignedUrl()",
  "containerId": "arrow-1",
  "textAlign": "center",
  "verticalAlign": "middle"
}
```

The label will be positioned at the midpoint of the arrow and will move with it when the arrow is dragged.

### Arrow / Line

```json
{
  "type": "arrow",
  "points": [[0, 0], [200, 100]],
  "startBinding": null,
  "endBinding": null,
  "startArrowhead": null,
  "endArrowhead": "arrow",
  "elbowed": false,
  "boundElements": [{"id": "my-label", "type": "text"}]
}
```

**Arrowhead Types:**
- `null` - no arrowhead
- `"arrow"` - standard arrow
- `"bar"` - flat line
- `"circle"` - filled circle
- `"circle_outline"` - hollow circle
- `"triangle"` - filled triangle
- `"triangle_outline"` - hollow triangle
- `"diamond"` - filled diamond
- `"diamond_outline"` - hollow diamond

**Points Array:** Coordinates relative to element's `x`, `y` position.

For curved arrows, add intermediate points:
```json
"points": [[0, 0], [100, -50], [200, 0]]
```

### Freedraw

```json
{
  "type": "freedraw",
  "points": [[0, 0], [10, 5], [20, 3]],
  "pressures": [0.5, 0.7, 0.6],
  "simulatePressure": true
}
```

### Image

```json
{
  "type": "image",
  "fileId": "abc123",
  "status": "saved",
  "scale": [1, 1]
}
```

Images require a corresponding entry in the `files` object:
```json
"files": {
  "abc123": {
    "mimeType": "image/png",
    "id": "abc123",
    "dataURL": "data:image/png;base64,...",
    "created": 1706000000000
  }
}
```

## Connections (Bindings)

To connect an arrow to shapes, use **bidirectional references**:

### Arrow Bindings

```json
{
  "id": "arrow-1",
  "type": "arrow",
  "startBinding": {
    "elementId": "rect-1",
    "fixedPoint": [1.0, 0.5],
    "mode": "orbit"
  },
  "endBinding": {
    "elementId": "rect-2",
    "fixedPoint": [0.0, 0.5],
    "mode": "orbit"
  }
}
```

### Shape boundElements

```json
{
  "id": "rect-1",
  "type": "rectangle",
  "boundElements": [{"id": "arrow-1", "type": "arrow"}]
}
```

### fixedPoint Coordinates

`fixedPoint: [x, y]` where x and y are ratios (0.0 to 1.0):

```
[0.0, 0.0] = top-left      [0.5, 0.0] = top-center     [1.0, 0.0] = top-right
[0.0, 0.5] = middle-left   [0.5, 0.5] = center         [1.0, 0.5] = middle-right
[0.0, 1.0] = bottom-left   [0.5, 1.0] = bottom-center  [1.0, 1.0] = bottom-right
```

### Binding Modes

- `"orbit"` - Arrow connects to shape's edge (most common)
- `"inside"` - Arrow goes to exact fixedPoint inside shape
- `"skip"` - No automatic binding calculation

## Complete Example: Two Connected Boxes

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [
    {
      "id": "box-a",
      "type": "rectangle",
      "x": 100,
      "y": 100,
      "width": 150,
      "height": 80,
      "angle": 0,
      "strokeColor": "#1e1e1e",
      "backgroundColor": "transparent",
      "fillStyle": "solid",
      "strokeWidth": 2,
      "strokeStyle": "solid",
      "roughness": 1,
      "opacity": 100,
      "seed": 1001,
      "version": 1,
      "versionNonce": 2001,
      "index": "a0",
      "isDeleted": false,
      "groupIds": [],
      "frameId": null,
      "boundElements": [
        {"id": "label-a", "type": "text"},
        {"id": "connector", "type": "arrow"}
      ],
      "updated": 1706000000000,
      "link": null,
      "locked": false,
      "roundness": {"type": 3}
    },
    {
      "id": "label-a",
      "type": "text",
      "x": 145,
      "y": 127,
      "width": 60,
      "height": 26,
      "angle": 0,
      "strokeColor": "#1e1e1e",
      "backgroundColor": "transparent",
      "fillStyle": "solid",
      "strokeWidth": 2,
      "strokeStyle": "solid",
      "roughness": 1,
      "opacity": 100,
      "seed": 1002,
      "version": 1,
      "versionNonce": 2002,
      "index": "a1",
      "isDeleted": false,
      "groupIds": [],
      "frameId": null,
      "boundElements": null,
      "updated": 1706000000000,
      "link": null,
      "locked": false,
      "text": "Box A",
      "fontSize": 20,
      "fontFamily": 1,
      "textAlign": "center",
      "verticalAlign": "middle",
      "containerId": "box-a",
      "originalText": "Box A",
      "autoResize": true,
      "lineHeight": 1.25
    },
    {
      "id": "box-b",
      "type": "rectangle",
      "x": 400,
      "y": 100,
      "width": 150,
      "height": 80,
      "angle": 0,
      "strokeColor": "#1e1e1e",
      "backgroundColor": "transparent",
      "fillStyle": "solid",
      "strokeWidth": 2,
      "strokeStyle": "solid",
      "roughness": 1,
      "opacity": 100,
      "seed": 1003,
      "version": 1,
      "versionNonce": 2003,
      "index": "a2",
      "isDeleted": false,
      "groupIds": [],
      "frameId": null,
      "boundElements": [
        {"id": "label-b", "type": "text"},
        {"id": "connector", "type": "arrow"}
      ],
      "updated": 1706000000000,
      "link": null,
      "locked": false,
      "roundness": {"type": 3}
    },
    {
      "id": "label-b",
      "type": "text",
      "x": 445,
      "y": 127,
      "width": 60,
      "height": 26,
      "angle": 0,
      "strokeColor": "#1e1e1e",
      "backgroundColor": "transparent",
      "fillStyle": "solid",
      "strokeWidth": 2,
      "strokeStyle": "solid",
      "roughness": 1,
      "opacity": 100,
      "seed": 1004,
      "version": 1,
      "versionNonce": 2004,
      "index": "a3",
      "isDeleted": false,
      "groupIds": [],
      "frameId": null,
      "boundElements": null,
      "updated": 1706000000000,
      "link": null,
      "locked": false,
      "text": "Box B",
      "fontSize": 20,
      "fontFamily": 1,
      "textAlign": "center",
      "verticalAlign": "middle",
      "containerId": "box-b",
      "originalText": "Box B",
      "autoResize": true,
      "lineHeight": 1.25
    },
    {
      "id": "connector",
      "type": "arrow",
      "x": 250,
      "y": 140,
      "width": 150,
      "height": 0,
      "angle": 0,
      "strokeColor": "#1e1e1e",
      "backgroundColor": "transparent",
      "fillStyle": "solid",
      "strokeWidth": 2,
      "strokeStyle": "solid",
      "roughness": 1,
      "opacity": 100,
      "seed": 1005,
      "version": 1,
      "versionNonce": 2005,
      "index": "a4",
      "isDeleted": false,
      "groupIds": [],
      "frameId": null,
      "boundElements": null,
      "updated": 1706000000000,
      "link": null,
      "locked": false,
      "points": [[0, 0], [150, 0]],
      "startBinding": {
        "elementId": "box-a",
        "fixedPoint": [1.0, 0.5],
        "mode": "orbit"
      },
      "endBinding": {
        "elementId": "box-b",
        "fixedPoint": [0.0, 0.5],
        "mode": "orbit"
      },
      "startArrowhead": null,
      "endArrowhead": "arrow",
      "elbowed": false
    }
  ],
  "appState": {
    "gridSize": 20,
    "gridStep": 5,
    "gridModeEnabled": false,
    "viewBackgroundColor": "#ffffff"
  },
  "files": {}
}
```

## Guidelines

1. **ID Strategy**: Use descriptive IDs like `"user-service-box"`, `"api-arrow"` for maintainability.

2. **Seed Values**: Use different `seed` values for each element to get varied hand-drawn effects.

3. **Index Values**: Use fractional indices like `"a0"`, `"a1"`, `"b0"` for element ordering.

4. **Positioning**: Plan a grid layout. Common spacing: 200-300px between connected elements.

5. **Arrow Points**: The `points` array is relative to the arrow's `x`, `y`. First point is usually `[0, 0]`.

6. **Curved Arrows**: Add middle points: `[[0, 0], [100, -50], [200, 0]]` creates an upward curve.

7. **Text in Shapes**: Always set both `containerId` on text AND `boundElements` on the shape.

8. **Arrow Labels**: Bind text to arrows using `containerId` on text and `boundElements` on arrow. The label moves with the arrow.

9. **Colors**: Use `#1e1e1e` for dark strokes, `"transparent"` for no fill, or hex colors like `#e63946`.

10. **Roundness**:
    - `{"type": 3}` - adaptive radius (rectangles)
    - `{"type": 2}` - proportional radius (ellipses, diamonds)
    - `null` - sharp corners

## Examples

### Architecture Diagram Component
```json
{
  "type": "rectangle",
  "width": 180,
  "height": 80,
  "roundness": {"type": 3},
  "boundElements": [{"id": "text-id", "type": "text"}]
}
```

### Database Symbol (Ellipse)
```json
{
  "type": "ellipse",
  "width": 120,
  "height": 120,
  "roundness": {"type": 2}
}
```

### Bidirectional Arrow
```json
{
  "startArrowhead": "arrow",
  "endArrowhead": "arrow"
}
```

### Dashed Connection (Optional/Async)
```json
{
  "strokeStyle": "dashed"
}
```

### Labeled Arrow (Complete Example)
```json
// Arrow with label
{
  "id": "api-call-arrow",
  "type": "arrow",
  "points": [[0, 0], [150, 0]],
  "boundElements": [{"id": "api-call-label", "type": "text"}],
  "startBinding": {"elementId": "service-a", "fixedPoint": [1, 0.5], "mode": "orbit"},
  "endBinding": {"elementId": "service-b", "fixedPoint": [0, 0.5], "mode": "orbit"},
  "endArrowhead": "arrow"
}

// Label bound to the arrow
{
  "id": "api-call-label",
  "type": "text",
  "text": "REST API",
  "containerId": "api-call-arrow",
  "textAlign": "center",
  "verticalAlign": "middle",
  "fontSize": 14,
  "fontFamily": 1
}
```
