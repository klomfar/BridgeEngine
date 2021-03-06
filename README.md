# Welcome to Bridge Engine 1.1!

We're glad to have you onboard. We're committed to enhancing Bridge Engine, so we take all of your feedback and support very earnestly.

Check out the <a href="https://www.youtube.com/watch?v=qbkwew3bfWU&list=PLxCu2yuPufWPjCthmZYOOJG9ieRnGAL79" target="_blank">Occipital YouTube Playlist for recent videos on Bridge Engine</a>.  

### Bridge Engine 1.1: iPhone XS + iOS 12 Compatibility Release

Bridge Engine has been update to support the iPhone XS and iOS 12! 

The iPhone XS, with it's top of the line processor and camera, will fit into any Bridge for iPhone X unit. The Bridge Engine rendering system has been updated for this new hardware. Previous to Bridge Engine 1.1, stereo display on the iPhone XS was slightly skewed and off center. 

Additionally, a number of rendering issues on iOS 12 have been fixed, including a problem in stereo mode where both views would display on the left eye. 

This update also includes general stability improvements.

### New in Bridge Engine 1.0

We're incredibly excited to announce that after nearly 18 months of updates; Bridge Engine is leaving beta!  The 1.0 version of Bridge Engine comes with support for a whole new rendering language (Metal) and many stability and performance fixes.

Additionally, with the inclusion of Metal in both SceneKit and Unity, we have access to physical shaders and have updated the Bridget sample to take full advantage of PBR support.

**Improvements**

- Choose your rendering API: OpenGL ES2 or Metal.
    - Locate your BEView subclass in your Storyboard. In the Attributes Inspector, select "Prefers Metal" = On.
    - Alternatively, You can programmatically create your BEView and select a rendering mode using `-initWithRenderingAPI:`.
- Upgraded to GoogleVR 1.120.0.
- Auto-hides the Home button on iPhone X (no more home bar in your Bridge Headset).
- Better lighting through full Linear Color Space support in Metal + SceneKit / Unity.
- Added a welcome screen example with start / settings button in Bridget Sample.
- Access a CVPixelBuffer from the color camera to color your own environment mesh in OpenGL or Metal.
- Unity : Objects no longer fall through the world.

**Fixes**

- Apps no longer crashes after resuming from backgrounding.
- Full iPad support.
    - UI is better aligned in Mono render mode.
    - iPad will no longer require Wide Vision Lens calibration.
- Touch-screen hit testing now works correctly on iOS 9 & 10 when running with Mono rendering mode.
- All OpenBE samples and Unity do a first-run check, to explicitly set their default settings. This solves certain situations such as mono-mode selection not being respected.
- Better warnings in the Debug Settings screen for low-volume and disabled bluetooth.
- Bridget will no longer run into real world geometry.
- Resolved an issue where color only tracking could crash the app.
- Fixed environment / camera sync issues while in placing objects.
- Normalized instructional sign images.
- Fixed Physics time step in Mono.
- Unity: Resolved a bug in Unity where disabling the settings screen would crash the app.
- Unity: Better color camera alignment to 3D mesh.
- Unity: BridgeEngine.unitypackage will offers to upgrade if there is a GoogleVR version missmatch.
- Unity: Fixed stereo FOV for iPhone X Unity projects.
- Unity: Resolved a bug in Unity where disabling the settings screen would crash the app.

### New in Beta 6.3: iPhone X Support

Bridge Engine has been updated to support the iPhone X!  We've standardized the field of view across all devices and added accurate camera intrinsics for the iPhone X.

More iPhone X updates will be coming soon, including additional improvements to the iPhone X's FOV.  

### Improvements in Beta 6.2: Stability and Rendering Updates

Bridge Engine has been updated with better iPhone 8 support and general stability and performance improvements.

We've updated Bridge Engine to enable **1440x1080** support on the iPhone 8! This new resolution improves the bridge engine field of view and rendering quality significantly.

We've also increased stability and performance of Bridge Engine as a whole by streamlining some of our shaders.

**Improvements**

- **1440x1080** video capture format enabled for iPhone 8. *Bridge engine selects this format automatically so no code changes are needed.*
- Small stereo rendering performance (0.2ms per frame) improvement in SceneKit

**Fixes**

- Fixed: Black screen on first launch
- Fixed: Turning on bluetooth causes app to freeze
- Fixed: Auto Exposure while relocalizing `kBEAutoExposeWhileRelocalizing` now works in Unity Plugin
- Fixed: Relocalization sign not showing in SceneKit


### Improvements in Beta 6.1: iOS 11 and Unity Updates
Bridge Engine is now ready for **iOS 11** and the **latest version of Unity!**

We've updated Bridge Engine to work with iOS 11's new threading rules. Bridge Engine is now able to run in the iOS 11 environment succesfully. If you haven't updated, now is the time!

We've also reworked the Unity Plugin so you can develop Mixed Reality experiences using the newest version of Unity (`2017.1.1` as of this update).  We have an additional demo scene called *MR Example Without GoogleVR*, which demonstrates the Unity Plugin in action without any GoogleVR dependencies at all, although we do still offer a GoogleVR version to retain an easy upgrade path.

Finally, we've created custom Unity shaders for camera texture to world projection, obstacle avoidance, and a few more.  You can now change how your world is textured by switching materials on your `BEScene`.

**Improvements**

- **iOS 11** is now supported
- **Unity 5.6** through **Unity 2017.1.1** are now supported.
- **GoogleVR** is now optional in the Unity Plugin
- The Unity plugin now supports custom materials for Bridge Engine shading.
- The Unity plugin now supports shadows on the real world mesh.

**Fixes**

- Fixed: SceneKit elements render with incorrect occlusion with the real world in Mono rendering mode.
- Fixed: Unity Rendering now supports Stereo *and* Mono rendering.
- Fixed: Reduced texture size in the space skybox to improve Bridget performance.

### New in Beta 6: Mixed Reality in Unity & Major UI/UX Updates
We have two major things happening in this release.

First, and most significant to many developers: **The Bridge Engine Unity Plugin now supports Mixed Reality** (with camera passthrough and real world occlusion)! Now you can scan your surroundings and create full Mixed Reality scenes with projects build from Unity! This plugin is still in beta, so please report any issues you find.

The second thing is a series of general UX improvements across the board:

- Stereo Scanning UX is improved: Now, the selection menu will always remain upright.
- Markup is improved, it now projects where an object will be placed and has an updated UI.  Use a custom markup object by implementing the `- (BOOL) mixedRealityBridgeShouldProjectMarkupNode:(NSString *)markupName position:(SCNVector3)position eulerAngles:(SCNVector3)eulerAngles` delegate method.
- Debug Settings have been redesigned.
- Performance has been improved: You may notice a significant in-experience FPS increase.
- New sample! The Laser Manipulator, which demonstrates use of Bridge Controller's touchpad and 3-DoF tracking.

#### Beta 5.2: Maintenance Release
We're cleaning up a few odds and ends. Keep up the great feedback!

The biggest issue we cleared up was an unusual case of iOS 10's whole audio system stopping from playing any audio when OpenBE's `AudioEngine` attempted to play an audio clip. Get this update to clear it up. No code changes required.

There is a new Bridge Engine option `kBEAutoExposeWhileRelocalizing` that you can try out. This will enable the color camera to auto expose while relocalizing, which can re-establish a lock in changing light conditions. Let us know what you think.

Other odds and ends:

- Improved pathfinding performance, both speed and quality.  Please let us know if Bridget gets stuck anywhere!
- Baked in some lighting onto the Bridge Controller model, so you can see it in all light conditions.
- Improved the in-headset scanning UI; you can tap through with no controller needed, and improved the in-headset hud instructions.

#### Beta 5.1: Stereo Scanning
Keep your iPhone in the Bridge Headset and scan your world by looking around!  In-headset scanning is re-enabled however the feature is still in beta, please give us your feedback.

Also featured in this release:

- Unity 5.5 and GoogleVR 1.4 fixes, picks up the correct GoogleVR release when downloading
- BE For Unity - tracking of reticle works even if no raycasts hit a collider
- Brand new Bridge Controller model, you'll see it in Bridget Sample when one is connected and you look down
- Corrected Bridge controller rotation, works better in all orientations
- Corrected Bridge controller touchpad tracking and state updates, touch.y is +1 for front tip of controller
- Debug setting UI at start of samples, makes for easier record and playback development workflow
- Debug option for manual Bridge controller selection, for crowded environments like hackathons
- Improved pathfinding, respects surfaces above Bridget and what is scanned floor
- Audio Engine init thread safety checks, so iOS 10 audio doesn't stop working

### New in Beta 5: Bridge Controller
Bridge Engine now supports the official controller with 3-DoF rotational tracking, a capacitive touchpad, a trigger & multiple buttons. Additionally, we've loaded the beta with lots of small updates! The BRIDGET sample has improvements to the portal and scan effect; The Unity plugin has matured with a simplified Unity package; We added realistic 3D positional audio support; and you can now record your screen directly from the app using ReplayKit. Note: *Stereo scanning has been temporarly disabled while we address a known issue, but it will be back in the next release.*


### New in Beta 4: Stereo Scanning

We have two really exciting updates in Beta 4. The first is stereo scanning, now you can put your Bridge on and build a map directly! Bridget’s also getting an upgrade! Bridge Engine Beta 4 adds an experimental feature that you may have seen in our videos - a portal into virtual reality. You can can access this new feature immediately to integrate into you own apps for Bridge. Additionally there are a handful of smaller features and updates.

#### Beta 3 Update 1: Bridget sample

We've just released the source of the Bridget sample, based on `OpenBE`, a Bridge Engine open source library containing Bridget's core functions like path planning, animation and scripting, as well as additional UI components, audio, and general mixed reality tools to help you develop with Bridge Engine.

### New in Beta 3: Bridge Headset Support & Rendering Overhaul
- It turns out we were working on a whole headset to go along with Bridge Engine! Learn more at the [Bridge website](https://bridge.occipital.com)
- Full-resolution rendering - critical for VR
- Forward rendering pipeline. This means compositing onto a global depth buffer with the room geometry, with all SceneKit material controls available like depth testing, rendering order and blending modes.

#### Get Involved
Want to help us expand the capabilities of Bridge Engine? We'd love contributions in the form of pull requests. Soon, we will formalize how to best contribute to Bridge Engine, but feel free to contact us and get involved here on Github.

### Please Use the Following Documentation & Resources to Get Up and Running
- Open `Reference/html/index.html` in your browser to view documentation
- [Documentation: Table of Contents and Calibrator App](https://github.com/OccipitalOpenSource/bridge-engine-beta/wiki)
- Note that Bridge Engine is not compatible with the iOS simulator.

### Changelog

##### Beta 6 changes

- Unity plugin: Now supports Mixed Reality
- New sample! The Laser Manipulator
- Stereo Scanning UX updates
- Markup redesign
- Debug settings simplified
- Performance: Significant FPS improvements

##### Beta 5 changes

- Bridge controller support
- Quicker robot scan-beam and portal improvements
- Unity improvements
- Added Spatial Audio support
- Added "ReplayKit" Screen Recording
- Exports texture OBJ of scanned world into the BridgeEngineScene folder

##### Beta 4 changes
- OpenBE: portal rendering code
- Supports in-headset scanning
- Exposes additional rendering information like system rendering order and shadow controls

##### Beta 3 Update 1 changes
- Added the Bridget sample
- Fixed OCC recording
- Fixed the layout and size of UI elements

##### Beta 3 changes
- Complete rendering overhaul
- Unity Package supporting inside-out tracking on iOS
- Bluetooth Controller integration
- Improved tracking and relocalization

##### Beta 2 changes
- In-app scanning: Scans can be performed from within the Bridge Engine.

##### Beta 1 changes
- Added new Rendering Sample (Updated sample names, and provisioning profiles). See [Rendering Documentation](https://github.com/OccipitalOpenSource/bridge-engine-beta/wiki/Documentation:-Advanced-Rendering-with-the-Bridge-Engine))
- Color-only tracking support - Scan the room with the Structure Sensor, but track in AR with only the the iOS camera!
