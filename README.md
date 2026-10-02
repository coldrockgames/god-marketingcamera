![coldrock-banner-itch-960x110](https://github.com/coldrockgames/.github/blob/main/public_images/repo-banner-trans.png)

https://github.com/user-attachments/assets/46a1d513-d419-4156-b23d-322c0beacbbc

![Godot Version](https://img.shields.io/badge/Godot-4.6+-blue.svg) ![License](https://img.shields.io/badge/License-MIT-green.svg) ![Version](https://img.shields.io/badge/Version-2610.1-orange)

# Coldrock MarketingCamera
This repository contains a Camera3D node to take marketing screenshots. 

It allows you to explore the scene from arbitrary angles and perspectives that are outside of the standard gameplay mechanics.

## Main Features

* **Free camera movement** (WASD) and climbing up/down (QE) in any 3D scene
* **Hotkey for slo-mo mode** (reduce the time scale of the scene)
* When toggled on, **freezes the scene**, so you can move around freely and position the camera for the perfect screenshot for your Store-Images.

## QoL Features

* All settings configurable directly in the **inspector**
* **Export aware:** Disables itself when running in an export\
(you may choose to keep it alive even in exports, so your Marketing crew can create the perfect screenshots from the running game without access to the source code)
* Choose your hotkeys by setting **Input Map names** in the inspector


## Default hotkeys

|Key|Action|
|---|---|
|`TAB`|Activate/Deactivate the MarketingCamera.|
|`WASD`|Move the camera freely over the scene.|
|`QE`|Move the camera up/down along the Y-axis.|
|`R`|Reset the camera to default position, fov and rotation.|
|`Mouse Wheel`|Zoom in/out by moving the camera closer. Hold `SHIFT` to modify the FOV instead.|
|`Middle Mouse Button`|Rotate the camera. Hold `SHIFT` to pan instead of rotating.|
|`CTRL`|Hold down this key to set the scene into slo-mo mode.|
