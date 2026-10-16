# Controls and limitations

## Getting started

Select a local folder with the Android system picker. The app saves the granted directory and last browsing location. **Continue last folder** becomes available while that permission remains valid. Android may restrict access to particular system directories.

The browser shows subfolders, ZIP archives and a group of SBS media in the current folder. By default, media must end in `.sbs.jpg`, `.sbs.jpeg`, `.sbs.png` or `.sbs.mp4` (case-insensitive). To open ordinary JPG/JPEG/PNG filenames, use **Include ordinary images as SBS**, keyboard R or gamepad RB. This opt-in applies to the current browser session, its subfolders, ZIPs and gallery changes; leaving the browser resets it. Switching it off restores the marked-only filter. A regular photograph is not converted into stereo by enabling this mode. Put the two eye views side by side in the source media. General layout detection, half-SBS correction, eye-order selection and MPO parsing are not part of this migration.

## Controls

- Menus: D-pad / left stick / arrow keys select; A, Y or Enter open; LB switches phone/VR menu layout; B or Escape returns/exits.
- Folder browser: X or Backspace goes to the parent folder; RB or R toggles ordinary images as SBS.
- Viewer: arrow left/right changes media; arrow up/down adjusts zoom; I/K and J/L move the image; LB/RB adjusts eye separation; Y resets; B or Escape returns.
- The viewer also accepts continuous joystick input. Physical-controller mappings are still awaiting device regression testing.

Touch is available for menu selection. A controller or keyboard is recommended for viewing controls. The picture is a flat SBS presentation; this migration does not claim head tracking, lens-distortion correction or spherical 180/360 video projection.

## Local data

The app reads directories explicitly selected by the user and copies opened media into its private cache. Preferences remember folder location and viewing settings. No account or cloud upload flow is included. Android debug/profile builds retain Flutter's development networking permission; the main application manifest does not request internet access.

Video codec compatibility, large ZIP behavior and the actual phone/controller combination need to be validated on physical hardware before a release.

## Format support and verification

| Input | Browser behavior | Verification / limits |
| --- | --- | --- |
| `.sbs.jpg`, `.sbs.jpeg`, `.sbs.png` | Included by default, any letter case | Synthetic JPEG/PNG decode and left/right color split tested automatically |
| Ordinary `.jpg`, `.jpeg`, `.png` | Explicit Images as SBS opt-in required | Folder opt-in, actual decode, return and opt-out tested automatically |
| `.sbs.mp4` | Included by default, any letter case | Existing playback path; device/codec playback remains unverified |
| Ordinary `.mp4` | Not selected | Rename an existing SBS video to `.sbs.mp4`; renaming does not convert it |
| ZIP | Same filter, including nested entries | Extraction, mode-specific cache invalidation and traversal rejection tested |
| GIF, WebP, JPS/PNS, MPO, top/bottom | Not supported by this browser | Future work; do not infer support from a filename rename |

Images use the left half for the left eye and the right half for the right eye, preserving each half's aspect ratio (Full-SBS assumption). Half-SBS horizontal correction and swapping eye order are deferred. Use an even image width; an odd trailing column is currently discarded. PNG is decoded and the split views are internally encoded as JPEG: transparency and lossless rendering are not preserved. No automatic stereo-layout detection is performed.

These automated checks use generated color images and mocked Android storage calls. Physical SAF providers, display appearance, gamepads and video playback still require device regression before release. ZIP extraction is limited to 2,000 selected media entries and 2 GiB of declared uncompressed selected content; these bounds do not guarantee a particular device can open every archive below them.
