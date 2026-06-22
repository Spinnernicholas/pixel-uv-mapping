# pixel-uv-mapping

# Summary
The main purpose of this project is to develop processes and tools for pixel art uv texture mapping.

Inspired by this video: [Pixel Art Animation. Reinvented - Astortion Devlog](https://www.youtube.com/watch?v=HsOKwUwL1bE) by [aarthificial](https://www.youtube.com/@aarthificial)

# Encoding scheme
The encoding scheme maps the point (X,Y) on the final texture to the Red, Green, Blue, and Alpha Channels of an RGBA image pixel so it can be quickly rendered using a custom shader.

(R,G,B,A) -> (X, Y)

X = 65535 - 256G - R

Y = 65535 - 256A - B

# Workflows
- [Aseprite](/aseprite/ASEPRITE.md)