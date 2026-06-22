# Aseprite Workflow
## Layer Defs
| Layer Name | Description |
| ---------- | ----------- |
| src        | Original source pixel art                               |
| uv         | Maps src pixels to tx                                   |
| tx         | Final pixel color                                       |
| id         | unique pixel colors used to track pixel positions on tx |

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

## Challenges
| Challenge | Difficulty | Script/Artist Process |
| --------- | ---------- | --------------------- |
| Generate uv, id, and tx layers | Easy | [generate_uv_tx_id.lua](generate_uv_tx_id.lua) |
| Update uv layer using id and tx layers | Very Easy | [rebuild_uv_from_tx.lua](rebuild_uv_from_tx.lua) |
| Artist rearranging pixels in tx layer to create texture layout | Medium | Artist Process |
| Merging multiple animation frames into a single texture layout by updating the id layer so multiple uv layer pixels map to the same tx layer pixel | Very Difficult | Artist Process |