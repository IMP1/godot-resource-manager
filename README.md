# Godot Resource Manager v0.1.0



![An example list of Godot Resources in the Resource Manager](screenshot.png)

## Supported Variant Types

> [!NOTE]  
> For unsupported types, the plugin defaults to a button which opens the resource in the inspector.

  - [X] `bool`
  - [X] `int`
  - [X] `float`
  - [X] `String`
  - [X] `Vector2`
  - [X] `Vector2i`
  - [ ] `Rect2`
  - [ ] `Rect2i`
  - [X] `Vector3`
  - [X] `Vector3i`
  - [ ] `Transform2D`
  - [X] `Vector4`
  - [X] `Vector4i`
  - [ ] `Plane`
  - [ ] `Quaternion`
  - [ ] `AABB`
  - [ ] `Basis`
  - [ ] `Transform3D`
  - [ ] `Projection`
  - [X] `Color`
  - [X] `StringName`
  - [ ] `NodePath`
  - [ ] `RID`
  - [ ] `Callable`
  - [ ] `Signal`
  - [ ] `Dictionary`
  - [ ] `Array`
  - [ ] `PackedByteArray`
  - [ ] `PackedInt32Array`
  - [ ] `PackedInt64Array`
  - [ ] `PackedFloat32Array`
  - [ ] `PackedFloat64Array`
  - [ ] `PackedStringArray`
  - [ ] `PackedVector2Array`
  - [ ] `PackedVector3Array`
  - [ ] `PackedColorArray`
  - [ ] `PackedVector4Array`
  - [X] `Enum`
  - [ ] `BitFlags`
  - [ ] `Node`


## Known Bugs

  - Duplicate/Delete icons get out of sync with the rows of the resources they're for.

## Roadmap

(In no particular order)

  - Adding Undo/Redo
  - Showing min/max and prefix/suffix where the exported property has that info
  - Pressing <kbd>Enter</kbd> to add new resource
  - Saving in a new thread
  - Shortcuts (that are compatible with other Godot Editor shortcuts, and can be set in a settings somewhere)
  - Plugin Settings <!-- https://forum.godotengine.org/t/is-there-a-convention-for-projectsettings-created-by-a-plugin/54031 -->
  - Setting for which folders to search/exclude when searching for resources
