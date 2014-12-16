require! <[fs path optimist canvas tinygradient]>

# Make directory for output
argv = optimist.argv
dst-dir = argv.o
if !fs.exists-sync dst-dir then fs.mkdir-sync dst-dir

# Initial some values
gradient = tinygradient(\blue, \red).rgb 101
dim = 500

# Travel the file(s) and process
for src in argv._
  if fs.exists-sync src
    stats = fs.stat-sync src
    if stats.is-file! then draw-heatmap src
    else if stats.is-directory!
      for fn in fs.readdir-sync src
        draw-heatmap "#src/#fn"

!function draw-heatmap

  # Read file
  data = (fs.read-file-sync it) / "\n"; data.pop!

  # Normalize
  data = data.map (x) ->
    arr = x / "\t"; seg = arr.0; value = arr.slice 1, -1
    value = value.map (y) -> parseInt y
    min = max = value.0
    for v in value then min <?= v
    for v in value then max >?= v
    range = max - min
    if range == 0 then value = value.map (y) -> 0
    else value = value.map (y) ->
      parseInt(10000*((parseInt(y) - min) / range)) / 10000
    seg: parseInt(seg), value: value

  # Sort
  data = data.sort (x, y) -> x.seg - y.seg

  # Generate matrix
  width-dim = dim
  height-dim = data.length * parseInt width-dim / data.length
  row-height = height-dim / data.length
  matrix = []; height-count = height-dim
  for d in data
    col-width = parseInt width-dim / d.seg
    row = []; width-count = width-dim
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
  img-canvas = new canvas width-dim, height-dim
  ctx = img-canvas.getContext \2d
  img = ctx.create-image-data width-dim, height-dim
  for row to height-dim - 1
    for col to width-dim - 1
      color-index = matrix[row][col]
      if color-index > 1 then color-index = 100
      else if color-index < 0 then color-index = 0
      else color-index = parseInt color-index * 100
      i = (width-dim * row + col) .<<. 2
      img.data[i + 0] = gradient[color-index]._r
      img.data[i + 1] = gradient[color-index]._g
      img.data[i + 2] = gradient[color-index]._b
      img.data[i + 3] = 255
  ctx.putImageData img, 0, 0
  base64 = (img-canvas.toDataURL!).replace /^data:image\/\w+;base64,/, ""
  console.log "#dst-dir/#{path.basename it}.png"
  fs.write-file-sync "#dst-dir/#{path.basename it}.png", (new Buffer base64, \base64)

