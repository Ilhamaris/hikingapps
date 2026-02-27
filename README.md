---

**PROMPT**

I want to change the bottom card display to a *draggable bottom sheet* like the following example: a bottom panel that can be slid up and down, has a handle (gray line), and its contents can be scrolled.
The final result should resemble the reference screenshot: the panel sticks to the bottom, can be dragged, and when fully expanded displays a list of estimated post times.

Technical instructions:

1. Use `DraggableScrollableSheet` *or* `showModalBottomSheet` with `isScrollControlled: true`.
2. The panel should have a rounded top and a handle at the top.
3. The panel should contain a ListView containing post items (Pos 1, Post 2, etc.).
4. The default minChildSize is around 0.20, maxChildSize around 0.85.
5. Make sure the panel stays on top of the map without disrupting the map layout.
6. Don't change the map logic; simply replace the static cards with a draggable bottom sheet.
7. Provide the final output in the form of Flutter code that can be directly installed to replace the old cards.

The output must include:

* `DraggableScrollableSheet` structure
* Panel decorations (rounded, shadow, handle)
* ListView post content
* Example integration in `Stack` to appear above the map

Do not use PageView because this is not a horizontal slider, but a vertical draggable bottom sheet.

---