# Liquid Glass Widgets

A comprehensive Flutter package implementing Apple's Liquid Glass design system with 26 beautiful, composable glass-morphic widgets.

[![pub package](https://img.shields.io/pub/v/liquid_glass_widgets.svg)](https://pub.dev/packages/liquid_glass_widgets)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- **26 Widgets** organized into five categories
- **Two Quality Modes** for performance optimization
- **Flexible Layer System** for efficient rendering
- **Highly Customizable** appearance with extensive glass settings
- **Apple Design Guidelines** faithful implementation
- **Fully Tested** with widget tests and golden visual regression tests

## Widget Categories

### Containers

Foundation primitives for content layout:

- `GlassContainer` - Base primitive with configurable dimensions and shape
- `GlassCard` - Elevated card with shadow for content grouping
- `GlassPanel` - Larger surface for major UI sections

### Interactive

User interaction components:

- `GlassButton` - Primary action button
- `GlassIconButton` - Icon-based button
- `GlassChip` - Tag/category indicator
- `GlassSwitch` - Toggle control
- `GlassSlider` - Range selection
- `GlassSegmentedControl` - Multi-option selector
- `GlassPullDownButton` - Menu trigger button with dropdown
- `GlassButtonGroup` - Container for grouping related buttons

### Input

Text input components:

- `GlassTextField` - Text input field
- `GlassTextArea` - Multi-line text input area
- `GlassPasswordField` - Secure text input with visibility toggle
- `GlassSearchBar` - Search-specific input
- `GlassPicker` - Scrollable item selector
- `GlassFormField` - Form field wrapper for validation

### Overlays

Modal and floating UI:

- `GlassDialog` - Modal dialog
- `GlassSheet` - Bottom sheet / modal sheet
- `GlassMenu` - iOS 26 morphing context menu
- `GlassMenuItem` - Individual menu action item

### Surfaces

Navigation and app structure:

- `GlassAppBar` - Top app bar
- `GlassBottomBar` - Bottom navigation bar
- `GlassTabBar` - Tab navigation bar
- `GlassSideBar` - Vertical navigation sidebar
- `GlassToolbar` - Action toolbar for tools and controls

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  liquid_glass_widgets: ^0.2.1-dev.7
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Preventing White Flash (Important!)

To eliminate the brief white flash when glass widgets first appear, precache the lightweight shader at app startup:

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LiquidGlassWidgets.initialize();

  runApp(const MyApp());
}
```

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: GlassContainer(
            width: 200,
            height: 100,
            child: Text('Hello, Glass!'),
          ),
        ),
      ),
    );
  }
}
```

### Grouped Widgets (Recommended for Multiple Glass Elements)

When you have multiple glass widgets, wrap them in an `AdaptiveLiquidGlassLayer` for better performance:

```dart
AdaptiveLiquidGlassLayer(
  settings: LiquidGlassSettings(
    thickness: 0.8,
    blur: 12.0,
    glassColor: Colors.white.withOpacity(0.1),
  ),
  child: Column(
    children: [
      GlassContainer(
        child: Text('First glass widget'),
      ),
      GlassButton(
        onPressed: () {},
        child: Text('Click me'),
      ),
      GlassCard(
        child: Text('Another glass widget'),
      ),
    ],
  ),
)
```

### Standalone Widget (For Single Glass Elements)

For a single glass widget or when you need different settings per widget:

```dart
GlassContainer(
  useOwnLayer: true,
  settings: LiquidGlassSettings(
    thickness: 1.0,
    blur: 15.0,
  ),
  child: Text('Standalone glass widget'),
)
```

## Platform Support

This package works seamlessly across **all Flutter platforms** with optimized rendering:

- ✅ **iOS** (Native Impeller & Skia)
- ✅ **Android** (Native Impeller & Skia)
- ✅ **macOS** (Native Impeller & Skia)
- ✅ **Web** (CanvasKit with per-widget shader instances)
- ✅ **Windows** (Skia)
- ✅ **Linux** (Skia)

**Adaptive Rendering:**

- **Impeller** (iOS/Android): Full shader pipeline with texture capture and chromatic aberration
- **Skia & Web**: High-performance lightweight fragment shader
- Platform detection is automatic—no configuration needed

## Glass Quality Modes

The package provides two quality modes optimized for different use cases:

### Standard Quality (Default, Recommended)

```dart
GlassContainer(
  quality: GlassQuality.standard,
  child: Text('Great for scrollable content'),
)
```

- Uses lightweight fragment shader for iOS 26 accurate glass effects
- Works universally across all platforms (native, Skia, web)
- **Use for**: Lists, forms, scrollable content, interactive widgets
- **Recommended default** for 95% of use cases

### Premium Quality (Static Layouts Only)

```dart
GlassAppBar(
  quality: GlassQuality.premium,
  title: Text('Static header with premium quality'),
)
```

- **Impeller (iOS/macOS native)**: Full shader pipeline with texture capture and chromatic aberration
- **Skia/Web**: Automatically falls back to lightweight shader (same as standard quality)
- Higher visual quality on capable platforms
- **Use only for**: Static, non-scrollable layouts (app bars, bottom bars, hero sections)
- **Warning**: May not render correctly in scrollable contexts on Impeller

## Customization

All glass widgets accept a `settings` parameter (in standalone mode) or inherit from parent `LiquidGlassLayer`:

```dart
LiquidGlassSettings(
  thickness: 0.8,              // Material thickness (0.0-1.0)
  blur: 12.0,                  // Blur radius
  refractiveIndex: 1.5,        // Light refraction (1.0-2.0)
  glassColor: Colors.white.withOpacity(0.1), // Tint color
  lightAngle: 45.0,            // Directional lighting angle
  lightIntensity: 0.8,         // Lighting strength
  ambientStrength: 0.3,        // Ambient light contribution
  saturation: 1.2,             // Color saturation multiplier
  chromaticAberration: 0.002,  // Color separation effect
)
```

## Widget Examples

### Button with Action

```dart
GlassButton(
  onPressed: () {
    print('Button pressed!');
  },
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  child: Text('Click Me'),
)
```

### Text Input Field

```dart
GlassTextField(
  hintText: 'Enter your name',
  onChanged: (value) {
    print('Text changed: $value');
  },
)
```

### Modal Dialog

```dart
showDialog(
  context: context,
  builder: (context) => GlassDialog(
    title: Text('Confirm'),
    content: Text('Are you sure?'),
    actions: [
      GlassButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      GlassButton(
        onPressed: () {
          // Handle confirm
          Navigator.pop(context);
        },
        child: Text('OK'),
      ),
    ],
  ),
);
```

### Bottom Sheet

```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (context) => GlassSheet(
    child: Column(
      children: [
        ListTile(title: Text('Option 1')),
        ListTile(title: Text('Option 2')),
        ListTile(title: Text('Option 3')),
      ],
    ),
  ),
);
```

### Segmented Control

```dart
GlassSegmentedControl(
  segments: ['Day', 'Week', 'Month'],
  selectedIndex: 0,
  onChanged: (index) {
    print('Selected segment: $index');
  },
)
```

## Complete Example

See the [example](example/) directory for a full showcase app demonstrating all widgets. Run it with:

```bash
cd example
flutter run
```

## Architecture

### Layer System

All widgets support two rendering modes:

- **Grouped Mode** (`useOwnLayer: false`, default): Multiple widgets share the same rendering context via parent `AdaptiveLiquidGlassLayer`. More performant for many glass elements.

- **Standalone Mode** (`useOwnLayer: true`): Each widget creates its own independent rendering context. Use for single widgets or different settings per widget.

### Shape System

Widgets use `LiquidShape` for customizable shapes, with `LiquidRoundedSuperellipse` (16px radius) as the default for a smooth, modern appearance.

## Performance Tips

1. **Precache the shader** at app startup with `await LiquidGlassWidgets.initialize();` to eliminate loading flash
2. **Use Grouped Mode** when you have multiple glass widgets - wrap them in `AdaptiveLiquidGlassLayer`
3. **Use Standard Quality** for scrollable content and interactive widgets (it's already very high quality!)
4. **Reserve Premium Quality** for static elements like app bars where you want Impeller's advanced features
5. **Limit glass widget depth** - avoid deeply nesting glass effects

## Custom Refraction for Interactive Indicators

Interactive widgets like `GlassSegmentedControl` can have **true liquid glass refraction** (background visible through the indicator with edge distortion) on all platforms including Web and Skia.

### Quick Setup (Recommended)

Use the `LiquidGlassScope.stack` convenience constructor to eliminate boilerplate:

```dart
LiquidGlassScope.stack(
  background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
  content: Scaffold(
    body: Center(
      child: GlassSegmentedControl(
        segments: ['Option A', 'Option B', 'Option C'],
        selectedIndex: 0,
        onSegmentSelected: (index) => print('Selected: $index'),
        quality: GlassQuality.standard,  // Uses custom shader
      ),
    ),
  ),
)
```

### Manual Setup (More Control)

For custom layouts, use the manual pattern:

```dart
LiquidGlassScope(
  child: Stack(
    children: [
      // 1. Mark the background for capture
      Positioned.fill(
        child: LiquidGlassBackground(
          child: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
        ),
      ),

      // 2. Glass widgets will refract through the background
      Center(
        child: GlassSegmentedControl(
          segments: ['Option A', 'Option B', 'Option C'],
          selectedIndex: 0,
          onSegmentSelected: (index) => print('Selected: $index'),
          quality: GlassQuality.standard,  // Uses custom shader
        ),
      ),
    ],
  ),
)
```

### Key Points

- **`LiquidGlassScope.stack`** - Convenience constructor that eliminates boilerplate (recommended)
- **`LiquidGlassScope`** - Creates the infrastructure for background capture
- **`LiquidGlassBackground`** - Marks which content should be visible through the glass
- **Nested Scopes** - Inner scopes override outer scopes (useful for isolated demos)
- **Automatic on Impeller** - On iOS/macOS with Impeller, `GlassQuality.premium` uses native scene graph instead
- **One Background Per Scope** - Each `LiquidGlassScope` should contain only one `LiquidGlassBackground`

### When to Use

| Scenario                        | Recommendation                                      |
| ------------------------------- | --------------------------------------------------- |
| Web / Skia platforms            | ✅ Use `LiquidGlassScope.stack` for refraction       |
| iOS / macOS with Impeller       | ⚡ Use `GlassQuality.premium` for native scene graph |
| Multiple isolated demo sections | 🔄 Use separate scopes for each                     |
| App-wide fallback               | 🏠 Wrap root with `LiquidGlassScope.stack`          |

> 💡 **Tip:** Run the example app on an Impeller device (iOS/macOS) to see a side-by-side comparison of Impeller vs Custom Shader rendering in the "Shader Comparison" section of the Interactive page for `GlassSegmentedControl`.

## Dependencies

This package builds on the excellent work of:

### liquid_glass_renderer

Powers the **Impeller integration** for native scene graph rendering on iOS/Android/macOS with `GlassQuality.premium`. This sophisticated renderer provides texture capture and advanced chromatic aberration effects through Impeller's native pipeline.

For **Skia and Web platforms**, this package uses custom fragment shaders (`lightweight_glass.frag`, `interactive_indicator.frag`) to deliver iOS 26-accurate glass effects universally.

- **Package**: [`liquid_glass_renderer`](https://pub.dev/packages/liquid_glass_renderer)
- **Repository**: [flutter_liquid_glass](https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer)
- **Author**: [whynotmake-it](https://github.com/whynotmake-it)

A huge thank you to the whynotmake-it team for creating the Impeller integration that makes premium-quality glass rendering possible on native platforms.

### Other Dependencies

- [`motor`](https://pub.dev/packages/motor) - Animation utilities

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## Testing

```bash
# Run all tests
flutter test

# Run excluding golden tests
flutter test --exclude-tags golden

# Run golden tests only (macOS)
flutter test --tags golden
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

This package implements Apple's Liquid Glass design guidelines as a high-level widget library.

**Special Thanks:**

- The [whynotmake-it](https://github.com/whynotmake-it) team for creating the [`liquid_glass_renderer`](https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer) package, which provides the sophisticated shader-based rendering engine that powers all the glass effects in this library. Their work on custom shaders, texture capture, and advanced glass rendering techniques made this widget library possible.

## Links

- [Homepage](https://github.com/sdegenaar/liquid_glass_widgets)
- [Repository](https://github.com/sdegenaar/liquid_glass_widgets)
- [Issue Tracker](https://github.com/sdegenaar/liquid_glass_widgets/issues)
- [Pub.dev Package](https://pub.dev/packages/liquid_glass_widgets)

# Example

### main.dart

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets_example/constants/glass_settings.dart';
import 'package:liquid_glass_widgets_example/pages/containers_page.dart';
import 'package:liquid_glass_widgets_example/pages/input_page.dart';
import 'package:liquid_glass_widgets_example/pages/interactive_page.dart';
import 'package:liquid_glass_widgets_example/pages/overlays_page.dart';
import 'package:liquid_glass_widgets_example/pages/surfaces_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized before loading shaders
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes the Liquid Glass library.
  await LiquidGlassWidgets.initialize();

  runApp(const AppleLiquidGlassShowcaseApp());
}

class AppleLiquidGlassShowcaseApp extends StatelessWidget {
  const AppleLiquidGlassShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apple Liquid Glass Showcase',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          surface: Colors.black,
        ),
      ),
      home: const ShowcaseHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ShowcaseHomePage extends StatefulWidget {
  const ShowcaseHomePage({super.key});

  @override
  State<ShowcaseHomePage> createState() => _ShowcaseHomePageState();
}

class _ShowcaseHomePageState extends State<ShowcaseHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    ContainersPage(),
    InteractivePage(),
    OverlaysPage(),
    SurfacesPage(),
    InputPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScope.stack(
      background: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/wallpaper_dark.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),
      content: Positioned.fill(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: _pages[_selectedIndex],
          bottomNavigationBar: GlassBottomBar(
            quality: GlassQuality.premium,
            indicatorColor: Colors.black26,
            glassSettings: RecommendedGlassSettings.bottomBar,
            // unselectedIconColor: Colors.red,
            // barBorderRadius: 20,
            tabs: [
              GlassBottomBarTab(
                label: 'Home',
                icon: CupertinoIcons.home,
                selectedIcon: CupertinoIcons.house_fill,
              ),
              GlassBottomBarTab(
                label: 'Containers',
                icon: CupertinoIcons.square_stack_3d_up,
                selectedIcon: CupertinoIcons.square_stack_3d_up_fill,
              ),
              GlassBottomBarTab(
                label: 'Interactive',
                icon: CupertinoIcons.hand_point_right,
                selectedIcon: CupertinoIcons.hand_point_right_fill,
              ),
              GlassBottomBarTab(
                label: 'Overlays',
                icon: CupertinoIcons.square_stack,
                selectedIcon: CupertinoIcons.square_stack_fill,
              ),
              GlassBottomBarTab(
                label: 'Surfaces',
                icon: CupertinoIcons.rectangle_3_offgrid,
                selectedIcon: CupertinoIcons.rectangle_3_offgrid_fill,
              ),
              GlassBottomBarTab(
                label: 'Input',
                icon: CupertinoIcons.keyboard,
              ),
            ],
            selectedIndex: _selectedIndex,
            onTabSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            // extraButton: GlassBottomBarExtraButton(
            //   icon: CupertinoIcons.rectangle_3_offgrid_fill,
            //   iconColor: Colors.amber,
            //   onTap: () {
            //
            //   },
            //   label: 'AI Chat',
            // ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLiquidGlassLayer(
      settings: RecommendedGlassSettings.standard,
      quality: GlassQuality.standard, // Scrollable content - use standard
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Apple Liquid Glass',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Widget Showcase',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 40),
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.sparkles,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Explore the glass widget collection',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'This showcase demonstrates Apple Liquid Glass widgets following Apple\'s design philosophy of composable primitives.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Widget Categories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CategoryCard(
                      icon: CupertinoIcons.square_stack_3d_up_fill,
                      title: 'Containers',
                      description:
                          'GlassCard, GlassPanel, and GlassContainer for content',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _CategoryCard(
                      icon: CupertinoIcons.hand_point_right_fill,
                      title: 'Interactive',
                      description:
                          'GlassButton, GlassSwitch, and GlassSegmentedControl',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _CategoryCard(
                      icon: CupertinoIcons.square_stack_fill,
                      title: 'Overlays',
                      description:
                          'GlassSheet for modal dialogs and bottom sheets',
                      color: Colors.cyan,
                    ),
                    const SizedBox(height: 12),
                    _CategoryCard(
                      icon: CupertinoIcons.rectangle_3_offgrid_fill,
                      title: 'Surfaces',
                      description:
                          'GlassAppBar and GlassBottomBar for navigation',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    const _CategoryCard(
                      icon: CupertinoIcons.keyboard,
                      title: 'Input',
                      description: 'GlassTextField for text input',
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}