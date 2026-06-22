# Aseprite Workflow
## Layer Defs
| Layer Name | Description |
| ---------- | ----------- |
| src        | Original source pixel art                               |
| uv         | Maps src pixels to tx                                   |
| tx         | Final pixel color                                       |
| id         | unique pixel colors used to track pixel positions on tx |

## Challenges
| Challenge | Difficulty | Script/Artist Process |
| --------- | ---------- | --------------------- |
| Generate uv, id, and tx layers | Easy | [generate_uv_tx_id.lua](generate_uv_tx_id.lua) |
| Update uv layer using id and tx layers | Very Easy | [rebuild_uv_from_tx.lua](rebuild_uv_from_tx.lua) |
| Artist rearranging pixels in tx layer to create texture layout | Medium | Artist Process |
| Merging multiple animation frames into a single texture layout by updating the id layer so multiple uv layer pixels map to the same tx layer pixel | Very Difficult | Artist Process |