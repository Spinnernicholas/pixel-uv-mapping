-- rebuild_uv_from_tx.lua
--
-- Rebuilds the uv layer on the current frame by:
--   1. scanning id to map unique ID -> original position
--   2. scanning current tx to find where those IDs are now
--   3. writing original position into uv at the current tx position
--
-- UV encoding:
--   (R, G) = stored X as 16-bit little-endian
--   (B, A) = stored Y as 16-bit little-endian
--
-- Stored coords use full 16-bit inversion:
--   stored X = 65535 - actual X   if REVERSE_X = true
--   stored Y = 65535 - actual Y   if REVERSE_Y = true

local REVERSE_X = true
local REVERSE_Y = true
local MAX16 = 65535

local pc = app.pixelColor

local function rgba(r, g, b, a)
  return pc.rgba(r, g, b, a)
end

local function alphaOf(px)
  return pc.rgbaA(px)
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

local function decodeId(px)
  if pc.rgbaA(px) == 0 then
    return 0
  end

  local r = pc.rgbaR(px)
  local g = pc.rgbaG(px)
  local b = pc.rgbaB(px)

  return r | (g << 8) | (b << 16)
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

local function setCelImage(sprite, layer, frame, image)
  local cel = layer:cel(frame)
  if cel then
    cel.image = image
    cel.position = Point(0, 0)
  else
    sprite:newCel(layer, frame, image, Point(0, 0))
  end
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

local frame = app.activeFrame
if not frame then
  app.alert("No active frame.")
  return
end

local txLayer = findLayerByName(sprite, "tx")
local idLayer = findLayerByName(sprite, "id")
local uvLayer = findLayerByName(sprite, "uv")

if not txLayer or not idLayer or not uvLayer then
  app.alert('Missing one or more required layers: "tx", "id", "uv".')
  return
end

local txCel = txLayer:cel(frame)
local idCel = idLayer:cel(frame)

if not txCel or not idCel then
  app.alert('Current frame must contain cels for both "tx" and "id".')
  return
end

local txImage = txCel.image
local idImage = idCel.image

local idToOrigin = {}
local duplicateIdsInId = 0

for y = 0, idImage.height - 1 do
  for x = 0, idImage.width - 1 do
    local px = idImage:getPixel(x, y)
    if alphaOf(px) > 0 then
      local id = decodeId(px)
      if id ~= 0 then
        if idToOrigin[id] then
          duplicateIdsInId = duplicateIdsInId + 1
        else
          idToOrigin[id] = { x = x, y = y }
        end
      end
    end
  end
end

local newUv = makeImageLikeSprite(sprite)
clearImage(newUv)

local seenTxIds = {}
local duplicateIdsInTx = 0
local missingIds = 0
local validCount = 0

for y = 0, txImage.height - 1 do
  for x = 0, txImage.width - 1 do
    local px = txImage:getPixel(x, y)
    if alphaOf(px) > 0 then
      local id = decodeId(px)
      if id ~= 0 then
        if seenTxIds[id] then
          duplicateIdsInTx = duplicateIdsInTx + 1
        else
          seenTxIds[id] = true
        end

        local origin = idToOrigin[id]
        if origin then
          newUv:putPixel(x, y, encodeUv(origin.x, origin.y))
          validCount = validCount + 1
        else
          missingIds = missingIds + 1
        end
      end
    end
  end
end

app.transaction("Rebuild uv from tx", function()
  setCelImage(sprite, uvLayer, frame, newUv)
end)

app.refresh()

local msg = {
  "UV rebuild complete.",
  "",
  "Resolved pixels: " .. tostring(validCount),
  "Unknown IDs in tx: " .. tostring(missingIds),
  "Duplicate IDs in tx: " .. tostring(duplicateIdsInTx),
  "Duplicate IDs in id: " .. tostring(duplicateIdsInId),
  "",
  "REVERSE_X = " .. tostring(REVERSE_X),
  "REVERSE_Y = " .. tostring(REVERSE_Y),
}

app.alert(table.concat(msg, "\n"))