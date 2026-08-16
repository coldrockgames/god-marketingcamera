# god-addon-template
Template repository to create a plugin for the Godot Asset Store.\
You can use this repository template for your new addon project.\
The `addons` folder already contains a copy of the coldrock MIT license dated with 2025.

### If you create a new plugin
Please verify the year in the license file.

If it is outdated, clone the original template repository `god-plugin-template` and update the (c)year to the current year.

**Do this in two files:**
* The `LICENSE` file in the repository root
* The `LICENSE_MIT_Coldrock_Games` file in the `addons` folder

Commit the template repository afterwards. Thanks!

# Important: The `.gitattributes` file
This file contains a block of commands for github how to treat exports/zip downloads from the asset store.

It is located at the end of the file and looks like this:
```
# Godot Plugin Repository attributes
# COMMENT THE BLOCK BELOW if this repository
# contains a full PROJECT TEMPLATE!
# This block is only needed if you publish this
# repository to the Godot Asset Store
# It tells github to only include the addons folder 
# when downloading from the Asset Library.
/**        export-ignore
/addons    !export-ignore
/addons/** !export-ignore
```

If you plan to publish this repository as a _full project template_ and not as a plugin for the asset store, it is very important, that you comment out the last three lines, otherwise your project can not be downloaded from the asset store correctly!

Commenting out a line simply requires a `#` character at the start of the line:
```
#/**        export-ignore
#/addons    !export-ignore
#/addons/** !export-ignore
```
