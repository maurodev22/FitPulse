# Muestrea colores de una captura PNG (System.Drawing) sin depender de ver la imagen.
# Uso: powershell -File sample_pixels.ps1 <imagen> "x1,y1|x2,y2|..."
# Puntos: "x,y" (color del pixel) o regiones "x,y-ancho,alto" (color medio).
param([string]$Imagen, [string]$Puntos)

Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile($Imagen)
Write-Output ("imagen: {0}x{1}" -f $bmp.Width, $bmp.Height)

function Hex-Color($c) {
  return ("#{0:X2}{1:X2}{2:X2}" -f $c.R, $c.G, $c.B)
}

foreach ($p in ($Puntos -split '\|')) {
  if ($p -match '^(\d+),(\d+)-(\d+),(\d+)$') {
    $x0 = [int]$Matches[1]; $y0 = [int]$Matches[2]; $w = [int]$Matches[3]; $h = [int]$Matches[4]
    if ($w -lt 1) { $w = 1 }; if ($h -lt 1) { $h = 1 }
    $r = 0L; $g = 0L; $b = 0L; $n = 0L
    for ($xx = $x0; $xx -lt $x0 + $w; $xx += 4) {
      for ($yy = $y0; $yy -lt $y0 + $h; $yy += 4) {
        $c = $bmp.GetPixel($xx, $yy)
        $r += $c.R; $g += $c.G; $b += $c.B; $n++
      }
    }
    if ($n -gt 0) {
      $mr = [int]($r / $n); $mg = [int]($g / $n); $mb = [int]($b / $n)
      Write-Output ("region {0},{1}-{2},{3} => medio #{4:X2}{5:X2}{6:X2} (n={7})" -f $x0, $y0, $w, $h, $mr, $mg, $mb, $n)
    }
  } else {
    $xy = $p -split ','
    if ($xy.Count -eq 2) {
      $c = $bmp.GetPixel([int]$xy[0], [int]$xy[1])
      Write-Output ("punto {0},{1} => {2}" -f $xy[0], $xy[1], (Hex-Color $c))
    }
  }
}
$bmp.Dispose()