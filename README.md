---
I want a complete Flutter implementation of the following pipeline: load the JSON scaler, load the TFLite model, perform preprocessing, perform inference for multiple segments, calculate the accumulation, and display the estimated results in a neat and informative bottom sheet.

---

## **1. Load the JSON scaler file from assets**

My file is located at:

```
assets\models\scaler_params.json
```

Format:

```json
{
"mean": [...],
"std": [...]
}
```

I want:

* The `ScalerModel(mean, std)` model class
* The async JSON load function
* Safe and structured parsing

---

## **2. Load TFLite model**

The model is located at:

```
assets\models\linear_regression.tflite
```

I want to:

* Initialize the interpreter
* Set up a thread
* Handle errors when the model fails to load
* A service named `TFLiteService`

---

## **3. Preprocessing**

The input JSON segment data is:

```json
{
"lat": -7.549114,
"lon": 111.567498,
"elev": 54.5,
"delta_dist_m": 1.1245212523,
"delta_elev_m": 0.0,
"slope_rad": 0.0,
"slope_deg": 0.0
}
```

However, the model only uses 3 features **in a mandatory order**:

1. delta_dist_m
2. delta_elev_m
3. slope_deg

I want to:

* The `preprocessSegment()` function
* Scaling `(value - mean[i]) / std[i]`
* Output 2D array `[ [x1, x2, x3] ]`

---

## **4. TFLite Inference**

I want:

* Function `runInference(List<double> input)`
* Input shape `[1,3]`
* Output as a predicted number

---

## **5. Process multiple segments**

I want:

* Function `processSegments(List<Map<String, dynamic>> rawSegments)`
* Loop per segment:

* Preprocess
* Inference
* Cumulative calculation
* Data model:

```dart
class SegmentResult {
final double predicted;

final double cumulative;

SegmentResult(this.predicted, this.cumulative);

}
```

---

## **6. ESTIMATION UI (REQUIRED)**

The estimation display **must**:

### **A. Draggable Bottom Sheet**

* Appears from the bottom
* Can be dragged up and down
* Initial height 25%
* Maximum fullscreen height

### **B. ListView contains vertical cards**

Each card represents a trip segment, for example:

* “Basecamp → Post 1”
* “Post 1 → Post 2”

Card contains:

* Segment label (e.g., “Segment 3”)
* Model prediction value
* Accumulative value

Cards must be neat:

* Rounded corners
* Light shadow
* Padding & margin

### **C. ListView data is taken from the results of theSegments() process**

Not a dummy.

---

## **8. Answer Criteria**

Answers must be:

* Complete code, not snippets
* No TODOs
* No placeholders
* All imports are correct
* The bottom sheet is functional and displays a real card list
* No maps or sliders added

---

## **9. My expected output**

When the application is run:

1. The JSON scaler is loaded
2. The TFLite model is loaded
3. The JSON segments are processed
4. The prediction is calculated per segment
5. The cumulative is calculated
6. The UI displays a draggable bottom sheet containing the complete estimation card

---