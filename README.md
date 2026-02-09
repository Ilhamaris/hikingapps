Fix the following Flutter error:

1. I'm using Flutter + flutter_map (latest version).
2. I have a FloatingActionButton (FAB) placed on top of the FlutterMap using Stack + Positioned.
3. When the "Find My Location" FAB is pressed, the button doesn't respond at all.
4. Another issue: when the FAB is pressed, the map pans, and when the button is double-taped, the map zooms in, as if the FAB isn't receiving pointer input.
5. I want the FAB to function normally:

* Executing the code `mapController.move(currentLocation, 17);`
* Not triggering the map gesture
* Not causing the map to drag/zoom
* Not being hit by MapWidget`s hit test

Please do the following:

Step 1: Analyze the most likely causes why the button isn't receiving clicks (e.g., gesture conflict, pointer event capture by MapWidget, Stack clipBehavior issue, or need to use `IgnorePointer`/`AbsorbPointer`).

Step 2: Provide a code solution that *certainly works*, for example:

* ensuring the FAB is outside the map's area capturing gestures,
* or wrapping the FlutterMap with `IgnorePointer`,
* or wrapping the FAB with `GestureDetector(behavior: HitTestBehavior.opaque)` so that clicks don't "bleed through" the map,
* or adding `mapController.onReady` and ensuring the map doesn't override pointer events.

Step 3: Provide a complete, ready-to-paste code patch that correctly places the FAB above the FlutterMap so that:

* the FAB has pointer priority,
* the FAB is clickable,
* the map doesn't react.
---