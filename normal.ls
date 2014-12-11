require! <[fs]>

for fn in fs.readdir-sync \origin
  line = (fs.read-file-sync "origin/#fn") / "\n"; line.pop!
  line = line.map (x) ->
    arr = x / "\t"
    seg = arr.0
    value = arr.slice 1, -1
    value = value.map (y) -> parseInt y
    [min, max] = minmax value
    range = max - min
    if range == 0
      value = value.map (y) -> 0
    else
      value = value.map (y) -> parseInt(10000*((parseInt(y) - min) / range)) / 10000
    seg: seg, value: value
  output = ''
  for l in line
    output += l.seg
    for v in l.value
      output += "\t#v"
    output += "\n"
  fs.write-file-sync "data/#fn", output


function minmax
  m = M = it.0
  for v in it then m <?= v
  for v in it then M >?= v
  [m, M]
