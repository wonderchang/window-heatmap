require! <[fs path optimist canvas tinygradient]>
argv = optimist.argv
gradient = tinygradient(\blue, \red).rgb 101

width-dim = dim = 500

for src in argv._
  if fs.exists-sync src
    stats = fs.stat-sync src
    if stats.is-file!
      draw-heatmap src
    else if stats.is-directory!
      for fn in fs.readdir-sync src
        draw-heatmap "#src/#fn"

!function draw-heatmap
  # Parse path
  dir = path.dirname it; file = path.basename it; dst-dir = "whm_#dir"
  if !fs.exists-sync dst-dir then fs.mkdir-sync dst-dir
  # Read file
  data = (fs.read-file-sync it) / "\n"; data.pop!
  # Normalize
  data = data.map (x) ->
    arr = x / "\t"; seg = arr.0; value = arr.slice 1, -1
    value = value.map (y) -> parseInt y
    [min, max] = minmax value; range = max - min
    if range == 0 then value = value.map (y) -> 0
    else value = value.map (y) ->
      parseInt(10000*((parseInt(y) - min) / range)) / 10000
    seg: parseInt(seg), value: value
  # Sort
  data = data.sort (x, y) -> x.seg - y.seg
  # Generate matrix
  height-dim = data.length * parseInt width-dim / data.length
  row-height = height-dim / data.length
  matrix = []; height-count = dim
  for d in data
    col-width = parseInt width-dim / d.seg
    row = []; width-count = dim
    for v in d.value
      for i to col-width - 1
        row.push v; width-count--
    while width-count > 0
      row.push d.value[d.value.length - 1]
      width-count--
    for i to row-height - 1
      matrix.push row
      height-count--
  while height-count > 0
    matrix.push row
    height-count--
  # Draw heatmap
  img-canvas = new canvas dim, dim
  ctx = img-canvas.getContext \2d
  img = ctx.create-image-data dim, dim
  for row to dim - 1
    for col to dim - 1
      color-index = matrix[row][col]
      if color-index > 1 then color-index = 100
      else if color-index < 0 then color-index = 0
      else color-index = parseInt color-index * 100
      i = (dim * row + col) .<<. 2
      img.data[i + 0] = gradient[color-index]._r
      img.data[i + 1] = gradient[color-index]._g
      img.data[i + 2] = gradient[color-index]._b
      img.data[i + 3] = 255
  ctx.putImageData img, 0, 0
  base64 = (img-canvas.toDataURL!).replace /^data:image\/\w+;base64,/, ""
  console.log "#dst-dir/#file.png"
  fs.write-file-sync "#dst-dir/#file.png", (new Buffer base64, \base64)


function minmax
  m = M = it.0
  for v in it then m <?= v
  for v in it then M >?= v
  [m, M]

