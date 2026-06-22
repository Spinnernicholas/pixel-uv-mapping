# Aseprite Workflow

## Installation

1. Copy the script files (`generate_uv_tx_id.lua` and `rebuild_uv_from_tx.lua`) to your Aseprite scripts folder
2. Access your scripts folder from Aseprite menu: **File > Scripts > Open Scripts Folder**

![Aseprite Scripts Menu](https://community.aseprite.org/uploads/default/original/2X/6/66bafdbd04f34fca30e9a3df1fea5261e557feaf.png)

3. Paste the `.lua` files into this folder
4. Reload scripts by pressing **F5** or going to **File > Scripts > Rescan Scripts Folder**
5. The new scripts should now appear in your **File > Scripts** menu

For more information on Aseprite scripting, see the [official documentation](https://www.aseprite.org/docs/scripting/).

## Usage

### Generating UV, TX, and ID Layers
1. Create a new sprite or open an existing one
2. Draw your source pixel art in a layer
3. Select that layer (any name is fine)
4. Go to **File > Scripts > generate_uv_tx_id**
5. Three new layers will be created: `tx`, `id`, and `uv`

### Updating UV Mapping After Changes
After rearranging pixels in the `tx` layer:
1. Go to **File > Scripts > rebuild_uv_from_tx**
2. The `uv` layer will be updated to reflect the new positions

## Workflow

1. **Create source art** - Draw original pixel art in the `src` layer
2. **Generate layers** - Run [generate_uv_tx_id.lua](generate_uv_tx_id.lua) to automatically create:
   - `tx` layer: source pixels with unique colors
   - `id` layer: reference copy of tx (preserves original pixel mappings)
   - `uv` layer: encoded coordinates mapping each tx pixel back to its original position in src
3. **Arrange texture layout** - Artist manually rearranges pixels in the `tx` layer to create the desired texture layout/packing
4. **For animations** - If combining multiple frames into one texture:
   - Update the `id` layer to map multiple original pixels to the same tx pixel
   - This allows sharing pixels across animation frames in a single texture
5. **Rebuild UV mapping** - After any changes to the `tx` layer, run [rebuild_uv_from_tx.lua](rebuild_uv_from_tx.lua) to:
   - Scan the `id` layer to track original positions
   - Update the `uv` layer to reflect the new positions of pixels in `tx`

## Layer Defs

| Layer Name | Description |
| ---------- | ----------- |
| src        | Original source pixel art (layer name not important, always uses select layer as src layer) |
| uv         | Maps src pixels to tx                                   |
| tx         | Final pixel color                                       |
| id         | unique pixel colors used to track pixel positions on tx |

## Color Uniqueness Algorithm

When generating the `tx` and `id` layers, the script ensures each non-transparent pixel has a unique color so that pixels can be individually tracked during the UV mapping process. To preserve visual similarity to the original source:

1. **Start with source color** - Begins with the original RGBA values from the src layer
2. **Check for uniqueness** - If the color is already used, search nearby colors within a radius
3. **Prioritize visual similarity** - When selecting a replacement color:
   - First priority: smallest brightness difference (preserves luminance/tone)
   - Second priority: smallest RGB distance (preserves hue/saturation)
4. **Preserve alpha** - The source alpha value is always maintained

If all pixels in the source are already unique, this algorithm is not needed and colors remain unchanged.

## Challenges

| Challenge | Difficulty | Script/Artist Process |
| --------- | ---------- | --------------------- |
| Generate uv, id, and tx layers | Easy | [generate_uv_tx_id.lua](generate_uv_tx_id.lua) |
| Update uv layer using id and tx layers | Very Easy | [rebuild_uv_from_tx.lua](rebuild_uv_from_tx.lua) |
| Artist rearranging pixels in tx layer to create texture layout | Medium | Artist Process |
| Merging multiple animation frames into a single texture layout by updating the id layer so multiple uv layer pixels map to the same tx layer pixel | Very Difficult | Artist Process |