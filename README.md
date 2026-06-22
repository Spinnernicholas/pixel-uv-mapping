# pixel-uv-mapping

# Summary

The main purpose of this project is to develop processes and tools for pixel art UV texture mapping.

## Use Case

This technique enables a **single texture image to drive all sprite animations**, automatically updating every frame without needing to redraw individual animation sprites. This is particularly useful when you want **pixel-perfect control without managing 3D models**.

**When to use this approach:**
- **Sprite-based animations** with many frames (e.g., character walk cycles, attack animations)
- Designs that require texture updates to propagate across all animation frames instantly
- Projects seeking an alternative to 3D models with precise pixel-level control

**When this isn't necessary:**
- Individual/single sprites (just draw them directly)
- Projects already using 3D models for animation generation

For comparison, if you prefer a full 3D look, you can generate sprite animations using a 3D modeling program like Blender instead.

Inspired by this video: [Pixel Art Animation. Reinvented - Astortion Devlog](https://www.youtube.com/watch?v=HsOKwUwL1bE) by [aarthificial](https://www.youtube.com/@aarthificial)

# Encoding scheme
The encoding scheme maps the point (X,Y) on the final texture to the Red, Green, Blue, and Alpha Channels of an RGBA image pixel so it can be quickly rendered using a custom shader.

(R,G,B,A) -> (X, Y)

X = 65535 - 256G - R

Y = 65535 - 256A - B

# Workflows
- [Aseprite](/aseprite/README.md)