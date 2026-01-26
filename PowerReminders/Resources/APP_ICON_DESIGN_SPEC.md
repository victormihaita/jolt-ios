# Power Reminders App Icon Design Specification

## Brand Identity
Designed for Sam Beckman's tech-savvy audience (18-35 year-old content creators)

## Color Palette

### Primary: Electric Cyan
- Light Mode: `#00C9E0` (rgb: 0, 201, 224)
- Dark Mode: `#00E5FF` (rgb: 0, 229, 255)

### Background Options
- **Option A - True Black**: `#000000` (OLED optimized, cinematic)
- **Option B - Dark Gray**: `#0D0D0F` (subtle elevation)
- **Option C - Gradient**: `#000000` to `#1A1A1E` (135deg)

### Accent (for glow effects)
- Electric Cyan glow: `rgba(0, 201, 224, 0.4)`

## Icon Design Concepts

### Concept 1: Minimalist Bell (Recommended)
- **Background**: True black or dark gradient
- **Icon**: Stylized notification bell in Electric Cyan
- **Style**: Clean lines, geometric, modern
- **Glow**: Subtle cyan glow around bell

### Concept 2: Clock + Check
- **Background**: Dark gradient (black to dark gray)
- **Icon**: Circular clock face with checkmark overlay
- **Colors**: Cyan clock hands, cyan checkmark
- **Style**: Flat design with subtle depth

### Concept 3: "PR" Monogram
- **Background**: Electric Cyan gradient (light to dark cyan)
- **Icon**: Bold "PR" letters in white
- **Style**: Modern typography, rounded corners
- **Shadow**: Subtle inner glow

## Design Guidelines

### Shape
- iOS: Rounded square (Apple's standard superellipse)
- No custom masking needed - iOS handles rounding

### Visual Weight
- Icon should be visible and recognizable at all sizes (16px to 1024px)
- Avoid thin lines that disappear at small sizes
- Use bold, confident shapes

### Contrast
- Maintain high contrast for dark mode home screens
- Icon should pop against both light and dark wallpapers

### Do's
- Use the Electric Cyan as the primary accent
- Keep the design simple and scalable
- Include subtle depth through gradients or shadows
- Consider the cinematic, premium aesthetic

### Don'ts
- Don't use more than 2-3 colors
- Avoid complex illustrations
- No text smaller than what's legible at 40px
- Don't use pure white backgrounds

## Required Sizes

All sizes needed for the AppIcon.appiconset:

| Size | Filename | Use |
|------|----------|-----|
| 16x16 | 16.png | Mac 1x |
| 20x20 | 20.png | iPad 1x |
| 29x29 | 29.png | iPhone/iPad Settings 1x |
| 32x32 | 32.png | Mac 1x/2x |
| 40x40 | 40.png | iPhone/iPad Spotlight 1x/2x |
| 48x48 | 48.png | Apple Watch Notification 2x |
| 50x50 | 50.png | iPad Spotlight 1x |
| 55x55 | 55.png | Apple Watch Notification 2x |
| 57x57 | 57.png | iPhone App 1x (legacy) |
| 58x58 | 58.png | iPhone/iPad Settings 2x |
| 60x60 | 60.png | iPhone Notification 3x |
| 64x64 | 64.png | Mac 2x |
| 66x66 | 66.png | Apple Watch Notification 2x |
| 72x72 | 72.png | iPad App 1x (legacy) |
| 76x76 | 76.png | iPad App 1x |
| 80x80 | 80.png | iPhone/iPad Spotlight 2x, Watch Launcher |
| 87x87 | 87.png | iPhone Settings 3x, Watch Companion |
| 88x88 | 88.png | Apple Watch Launcher 40mm |
| 92x92 | 92.png | Apple Watch Launcher 41mm |
| 100x100 | 100.png | iPad Spotlight 2x, Watch Launcher |
| 102x102 | 102.png | Apple Watch Launcher 45mm |
| 108x108 | 108.png | Apple Watch Launcher 49mm |
| 114x114 | 114.png | iPhone App 2x (legacy) |
| 120x120 | 120.png | iPhone App 2x/3x, Spotlight 3x |
| 128x128 | 128.png | Mac 1x |
| 144x144 | 144.png | iPad App 2x (legacy) |
| 152x152 | 152.png | iPad App 2x |
| 167x167 | 167.png | iPad Pro App 2x |
| 172x172 | 172.png | Apple Watch Quick Look 38mm |
| 180x180 | 180.png | iPhone App 3x |
| 196x196 | 196.png | Apple Watch Quick Look 42mm |
| 216x216 | 216.png | Apple Watch Quick Look 44mm |
| 234x234 | 234.png | Apple Watch Quick Look 45mm |
| 256x256 | 256.png | Mac 1x/2x |
| 258x258 | 258.png | Apple Watch Quick Look 49mm |
| 512x512 | 512.png | Mac 1x/2x, iTunes |
| 1024x1024 | 1024.png | App Store, Marketing |

## Export Settings
- Format: PNG
- Color space: sRGB
- No transparency (use solid background)
- No rounded corners (iOS adds them automatically)

## Tools for Generation
1. **Figma/Sketch**: Design at 1024x1024, export all sizes
2. **SF Symbols**: Consider using SF Symbols for the bell icon
3. **Icon generators**:
   - https://appicon.co
   - https://makeappicon.com
   - Xcode's built-in icon generator

## Reference
This icon should match the Electric Cyan theme used throughout:
- iOS AccentColor: `#00C9E0` (light) / `#00E5FF` (dark)
- Website primary: `#00C9E0`
- Android primary: `#00C9E0`
