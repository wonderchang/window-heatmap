require! <[fs canvas tinygradient]>

module.exports = {

  read: (filename) !->
    squid = fs.readFileSync filename
    img = new canvas.Image
    img.src = squid
    img-canvas = new canvas img.width, img.height
    ctx = img-canvas.getContext \2d
    ctx.drawImage img, 0, 0, img.width, img.height
    this.img = ctx.getImageData 0, 0, img.width, img.height
    #console.log "Read #filename, [" + img.width + ' x ' + img.height + ']'
    return this

  read-matrix: (filename) !->
    data = fs.readFileSync filename, \utf-8
    data = data.split \\n; data.pop!
    data = data.map (line) -> line.split \,
    width = data[0].length
    height = data.length
    max-value = 1
    gradient = tinygradient(\blue, \red).rgb 101
    img-canvas = new canvas width, height
    ctx = img-canvas.getContext \2d
    this.img = ctx.createImageData width, height
    for row to height - 1
      for col to width - 1
        color-index = (data[row][col] / max-value)
        if color-index > 1 then color-index = 100
        else if color-index < 0 then color-index = 0
        else color-index = parseInt color-index * 100
        i = (width * row + col) .<<. 2
        this.img.data[i + 0] = gradient[color-index]._r
        this.img.data[i + 1] = gradient[color-index]._g
        this.img.data[i + 2] = gradient[color-index]._b
        this.img.data[i + 3] = 255
    return this

  write: (filename) !->
    img-canvas = new canvas this.img.width, this.img.height
    ctx = img-canvas.getContext \2d
    ctx.putImageData this.img, 0, 0
    base64 = (img-canvas.toDataURL!).replace /^data:image\/\w+;base64,/, ""
    buffer = new Buffer base64, \base64
    fs.writeFileSync(filename, buffer);

  grayscale: !->
    for row to this.img.height - 1
      for col to this.img.width - 1
        i = (this.img.width * row + col) .<<. 2
        r = this.img.data[i + 0]
        g = this.img.data[i + 1]
        b = this.img.data[i + 2]
        g = Math.round 0.2126 * r + 0.7152 * g + 0.0722 * b
        this.img.data[i] = this.img.data[i + 1] = this.img.data[i + 2] = g
    #console.log " --> grayscale"
    return this

  channel: (ch) ->
    switch ch
    case "red" then ch1 = 1; ch2 = 2
    case "green" then ch1 = 0; ch2 = 2
    case "blue" then ch1 = 0; ch2 = 1
    for row to this.img.height - 1
      for col to this.img.width - 1
        i = (this.img.width * row + col) .<<. 2
        this.img.data[i + ch1] = this.img.data[i + ch2] = 0
    #console.log " --> #ch channel"
    return this

  equalize: !->
    p = r: { v: zero-arr(256) }, g: { v: zero-arr(256) }, b: { v: zero-arr(256) }
    w = this.img.width
    h = this.img.height
    for row to h - 1
      for col to w - 1
        i = (w * row + col) .<<. 2
        p.r.v[this.img.data[i + 0]]++
        p.g.v[this.img.data[i + 1]]++
        p.b.v[this.img.data[i + 2]]++
    p.r.cdf = create-cdf p.r.v
    p.g.cdf = create-cdf p.g.v
    p.b.cdf = create-cdf p.b.v
    for row to h - 1
      for col to w - 1
        i = (w * row + col) .<<. 2
        this.img.data[i + 0] = Math.round 255 * (p.r.cdf.f[this.img.data[i + 0]] - p.r.cdf.min) / (w * h)
        this.img.data[i + 1] = Math.round 255 * (p.g.cdf.f[this.img.data[i + 1]] - p.g.cdf.min) / (w * h)
        this.img.data[i + 2] = Math.round 255 * (p.b.cdf.f[this.img.data[i + 2]] - p.b.cdf.min) / (w * h)
    #console.log " --> equalize"
    return this

  center: !->
    w = this.img.width
    h = this.img.height
    r-mean = 0; g-mean = 0; b-mean = 0
    for row to h - 1
      for col to w - 1
        i = (w * row + col) .<<. 2
        r-mean += this.img.data[i + 0]
        g-mean += this.img.data[i + 1]
        b-mean += this.img.data[i + 2]
    shift = new Array 3
    shift[0] = 127 - (r-mean /= w * h)
    shift[1] = 127 - (g-mean /= w * h)
    shift[2] = 127 - (b-mean /= w * h)
    for row to h - 1
      for col to w - 1
        i = (w * row + col) .<<. 2
        for j to 2
          if this.img.data[i + j] + shift[j] < 0 then this.img.data[i + j] = 0
          else if this.img.data[i + j] + shift[j] > 255 then this.img.data[i + j] = 255
          else this.img.data[i + j] += shift[j]
    return this
}

function zero-arr num
  return Array.apply null, new Array num
    .map Number.prototype.valueOf, 0

function create-cdf arr
  cdf = zero-arr 256
  cdf[0] = arr[0]
  for i from 1 to 255
    cdf[i] += cdf[i - 1] + arr[i]
  for i to 255
    if cdf[i] != 0 then return { f: cdf, min: cdf[i] }


