# <img src="images/ResourceManager.svg" width="48" alt="Godot Resource Manager icon"> Godot Resource Manager v0.1.0 

![Latest Release](https://img.shields.io/github/v/release/IMP1/godot-resource-manager?include_prereleases)


A Godot 4.x Plugin for easier editing of custom resources by displaying them all in more of a 
'spreadsheet' format. You can also add new resources, duplicate, and delete them from with the 
Resource Manager view.

![An example list of Godot Resources in the Resource Manager](images/screenshot.png)

## Installation

## Usage

Once you've got the plugin and enabled it in your Project Settings, you should see a ResourceManager 
tab at the top, alongside the 2D, 3D, Script, AssetLib views. Clicking on it will take you to a 
mostly empty screen.

Resource Manager finds any custom resources with 
[their own class name](https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html#registering-named-classes),
and will popuplate the dropdown with them. Choose one and press `Reload` to load up all the 
instances of that type. By default, Resource Manager looks through all your project directories to
find resources. You can tweak this in the settings.

### Settings

The following settings can be found in your Project Settings under `Addons/Resource Manager`.

> [!NOTE]  
> Either turn on Advanced Settings, or search for 'Resource Manager' to show the settings.

#### Config

  - **Only Include Allowed Directories**: If this is true, then only folders in the **Allowed 
Directories** list will be searched for resources. If this is false, then all folders, except those 
in the **Ignored Directories** will be searched for resources. 
  - **Include Allowed Directories Subfolders**: If this is true, then all subfolders of any allowed
folders will be searched, as will their subfolders, and so on. If this is false, the only the files
in any allowed folders will be included.
  - **Allowed Directories**: This is a list of folders to search. It's only used if **Only Include 
Allowed Directories** is true.
  - **Ignored Directories**: This is a list of folders that are not searched. Subfolders of these 
folders will also not be searched.
  - **Allowed Filetypes**: This is a list of filetypes that represent the resources. It defaults to 
including `tres` and `res` files.
  - **Ignored Files**: These are files that will not be included in any lists of resources. This 
takes priority over any directory-based inclusion or exclusion.

#### Display

  - **Flag Field Abbreviation**: This is relevant to any exported property that has the 
`export_flags` hint. If this is set to 'NONE', then the full name of any flag will be shown in the
editor. If this is set to `INITIALS`, then the first letter will be shown, and if it set to 
`BIT_POSITIONS` then a number will be shown, representing the flag's bit position.

## Supported Variant Types

Below is a list of the variant types that are valid types for an exported property of a resource.
The checked items have a direct way to edit them within the Resource Manager view. The unchecked 
items will default to a button that opens the resource in the inspector to be edited there. My 
intention is to have convenient ways to edit all of these types while also balancing both horizontal
and vertical space considerations to maximise readability of a resource.

  - [X] `bool`
  - [X] `int`
  - [X] `float`
  - [X] `String`
  - [X] `Vector2`
  - [X] `Vector2i`
  - [X] `Rect2`
  - [X] `Rect2i`
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
  - [X] `BitFlags`
  - [X] `Resource`


## Known Bugs

  - Resources that inherit from other custom Resources aren't recognised by the plugin

## Roadmap

(In no particular order)

  - Adding Undo/Redo
  - Adding Deletion of resources
  - Showing min/max and prefix/suffix where the exported property has that info
  - Saving in a new thread
  - Shortcuts (that are compatible with other Godot Editor shortcuts, and can be set in a settings 
somewhere)
  - Prompt for confirmation when there are unsaved changes (when swapping Resource types, closing 
the editor, etc.)
  - Collapsible columns for groups/categories/sub-categories
  - Add inputs for export types that use a string type (filepath, input action name, etc.)
  - Recognise color_no_alpha and treat them appropriately
  - *MAYBE* more spreadsheet-like functionality (if there's interest)
	- Filtering rows by certain values
	- Ordering rows by certain values
	- Conditional formatting particular columns
	- Analysis of columns (mean, variance, min, max, sum, etc.)
