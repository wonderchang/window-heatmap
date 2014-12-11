require! <[fs ./image]>

width-dim = dim = 840

for fn in fs.readdir-sync \data
  data = (fs.read-file-sync "data/#fn", \utf-8) / "\n"; data.pop!;
  data = data.map (x) ->
    arr = x / "\t"
    seg: arr[0], value: arr.slice 1
  height-dim = data.length * parseInt width-dim / data.length
  row-height = height-dim / data.length

  output = ''
  for d in data
    col-width = parseInt width-dim / d.seg
    row = []; count = dim
    for v in d.value
      for i to col-width - 1
        row.push v; count--
    while count > 0
      row.push d.value[d.value.length - 1]
      count--

    for i to row-height - 1
      output += row.join! + "\n";

  fs.write-file-sync "matrix/#fn", output
  console.log fn
  image.read-matrix "matrix/#fn"
    .write "heatmap/#fn.png"




