# Controls and limitations

## Getting started

Select a local folder with the Android system picker. The app saves the granted directory and last browsing location. **Continue last folder** becomes available while that permission remains valid. Android may restrict access to particular system directories.

The browser shows subfolders, ZIP archives and a group of SBS media in the current folder. Files must end in lowercase `.sbs.jpg` or `.sbs.mp4`. Put the two eye views side by side in the source media. General layout detection, half-SBS correction, eye-order selection and MPO parsing are not part of this migration.

## Controls

- Menus: D-pad / left stick / arrow keys select; A, Y or Enter open; LB switches phone/VR menu layout; B or Escape returns/exits.
- Folder browser: X or Backspace goes to the parent folder.
- Viewer: arrow left/right changes media; arrow up/down adjusts zoom; I/K and J/L move the image; LB/RB adjusts eye separation; Y resets; B or Escape returns.
- The viewer also accepts continuous joystick input. Physical-controller mappings are still awaiting device regression testing.

Touch is available for menu selection. A controller or keyboard is recommended for viewing controls. The picture is a flat SBS presentation; this migration does not claim head tracking, lens-distortion correction or spherical 180/360 video projection.

## Local data

The app reads directories explicitly selected by the user and copies opened media into its private cache. Preferences remember folder location and viewing settings. No account or cloud upload flow is included. Android debug/profile builds retain Flutter's development networking permission; the main application manifest does not request internet access.

Video codec compatibility, large ZIP behavior and the actual phone/controller combination need to be validated on physical hardware before a release.
