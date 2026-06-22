-- generate_uv_tx_id.lua
--
-- Creates 3 layers from the active layer on the current frame:
--   tx: source-like but unique colors for each non-transparent source pixel
--   id: copy of tx, used as original reference
--   uv: packed original coordinates
--
-- UV encoding:
--   (R, G) = stored X as 16-bit little-endian
--   (B, A) = stored Y as 16-bit little-endian
--
-- Stored coords use full 16-bit inversion:
--   stored X = 65535 - actual X   if REVERSE_X = true
--   stored Y = 65535 - actual Y   if REVERSE_Y = true
--
-- Uniqueness for tx/id:
--   - Start from source RGBA
--   - If already used, search nearby colors
--   - Prefer smallest brightness difference
--   - Then prefer smallest RGB distance
--   - Preserve source alpha

local REVERSE_X = true
local REVERSE_Y = true
local MAX16 = 65535
local MAX_RADIUS = 16

local pc = app.pixelColor

local function rgba(r, g, b, a)
  return pc.rgba(r, g, b, a)
end

local function alphaOf(px)
  return pc.rgbaA(px)
end

local function redOf(px)
  return pc.rgbaR(px)
end

local function greenOf(px)
  return pc.rgbaG(px)
end

local function blueOf(px)
  return pc.rgbaB(px)
end

local function makeImageLikeSprite(sprite)
  return Image(sprite.spec)
end

local function clearImage(img)
  local transparent = rgba(0, 0, 0, 0)
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      img:putPixel(x, y, transparent)
    end
  end
end

local function luma(r, g, b)
  return 77 * r + 150 * g + 29 * b
end

local function encodeUv(x, y)
  local storedX = x
  local storedY = y

  if REVERSE_X then
    storedX = MAX16 - x
  end

  if REVERSE_Y then
    storedY = MAX16 - y
  end

  local r = storedX & 0xFF
  local g = (storedX >> 8) & 0xFF
  local b = storedY & 0xFF
  local a = (storedY >> 8) & 0xFF

  return rgba(r, g, b, a)
end

local function findLayerByName(sprite, name)
  for _, layer in ipairs(sprite.layers) do
    if layer.name == name then
      return layer
    end
  end
  return nil
end

local function removeLayerIfExists(sprite, name)
  local layer = findLayerByName(sprite, name)
  if layer then
    sprite:deleteLayer(layer)
  end
end

local function setCelImage(sprite, layer, frame, image)
  local cel = layer:cel(frame)
  if cel then
    cel.image = image
    cel.position = Point(0, 0)
  else
    sprite:newCel(layer, frame, image, Point(0, 0))
  end
end

local function makeUniqueColor(srcPx, used)
  local r0 = redOf(srcPx)
  local g0 = greenOf(srcPx)
  local b0 = blueOf(srcPx)
  local a0 = alphaOf(srcPx)

  local original = rgba(r0, g0, b0, a0)
  if not used[original] then
    return original
  end

  local baseLuma = luma(r0, g0, b0)

  for radius = 1, MAX_RADIUS do
    local bestPx = nil
    local bestScore = nil

    for dr = -radius, radius do
      for dg = -radius, radius do
        for db = -radius, radius do
          if math.max(math.abs(dr), math.abs(dg), math.abs(db)) == radius then
            local r = r0 + dr
            local g = g0 + dg
            local b = b0 + db

            if r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 then
              local px = rgba(r, g, b, a0)
              if not used[px] then
                local brightnessDiff = math.abs(luma(r, g, b) - baseLuma)
                local rgbDistance =
                  math.abs(dr) + math.abs(dg) + math.abs(db)
                local score = brightnessDiff * 1000 + rgbDistance

                if bestScore == nil or score < bestScore then
                  bestScore = score
                  bestPx = px
                end
              end
            end
          end
        end
      end
    end

    if bestPx ~= nil then
      return bestPx
    end
  end

  for r = 0, 255 do
    for g = 0, 255 do
      for b = 0, 255 do
        local px = rgba(r, g, b, a0)
        if not used[px] then
          return px
        end
      end
    end
  end

  return nil
end

local sprite = app.activeSprite
if not sprite then
  app.alert("No active sprite.")
  return
end

if sprite.colorMode ~= ColorMode.RGB then
  app.alert("This script requires an RGBA sprite.")
  return
end

if sprite.width - 1 > MAX16 or sprite.height - 1 > MAX16 then
  app.alert("Sprite dimensions exceed 16-bit coordinate range.")
  return
end

local sourceLayer = app.activeLayer
if not sourceLayer or not sourceLayer.isImage then
  app.alert("Select a pixel layer first.")
  return
end

local frame = app.activeFrame
if not frame then
  app.alert("No active frame.")
  return
end

local sourceCel = sourceLayer:cel(frame)
if not sourceCel then
  app.alert("The selected layer has no cel on the current frame.")
  return
end

local sourceImage = sourceCel.image
local sourcePos = sourceCel.position

app.transaction("Generate uv/tx/id", function()
  removeLayerIfExists(sprite, "uv")
  removeLayerIfExists(sprite, "tx")
  removeLayerIfExists(sprite, "id")

  local txLayer = sprite:newLayer()
  txLayer.name = "tx"

  local idLayer = sprite:newLayer()
  idLayer.name = "id"

  local uvLayer = sprite:newLayer()
  uvLayer.name = "uv"

  local txImage = makeImageLikeSprite(sprite)
  local idImage = makeImageLikeSprite(sprite)
  local uvImage = makeImageLikeSprite(sprite)

  clearImage(txImage)
  clearImage(idImage)
  clearImage(uvImage)

  local used = {}
  local written = 0

  for sy = 0, sourceImage.height - 1 do
    for sx = 0, sourceImage.width - 1 do
      local srcPx = sourceImage:getPixel(sx, sy)
      if alphaOf(srcPx) > 0 then
        local dx = sourcePos.x + sx
        local dy = sourcePos.y + sy

        if dx >= 0 and dx < sprite.width and dy >= 0 and dy < sprite.height then
          local uniquePx = makeUniqueColor(srcPx, used)
          if not uniquePx then
            app.alert("Failed to find a unique color for a pixel.")
            return
          end

          used[uniquePx] = true

          txImage:putPixel(dx, dy, uniquePx)
          idImage:putPixel(dx, dy, uniquePx)
          uvImage:putPixel(dx, dy, encodeUv(dx, dy))

          written = written + 1
        end
      end
    end
  end

  setCelImage(sprite, txLayer, frame, txImage)
  setCelImage(sprite, idLayer, frame, idImage)
  setCelImage(sprite, uvLayer, frame, uvImage)

  idLayer.isVisible = false
  app.activeLayer = txLayer
end)

app.refresh()