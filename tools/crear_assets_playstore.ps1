# Genera los assets oficiales de la ficha de Google Play:
#   - docs/store_assets/icono_512.png      (512x512, opaco, full-bleed)
#   - docs/store_assets/feature_graphic.png (1024x500, gradiente de marca)
# Re-ejecutable. No requiere cuentas ni red.
# Uso:  powershell -File tools/crear_assets_playstore.ps1

Add-Type -AssemblyName System.Drawing

$root   = Split-Path $PSScriptRoot -Parent
$icono  = Join-Path $root "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"
$outDir = Join-Path $root "docs\store_assets"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# ---------------------------------------------------------------- helpers
function New-RoundedRectPath {
    param([float]$x, [float]$y, [float]$w, [float]$h, [float]$r)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# ---------------------------------------------------------------- 1. icono 512
$src = [System.Drawing.Bitmap]::FromFile($icono)
$bmp = New-Object System.Drawing.Bitmap(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::White)
$g.DrawImage($src, 0, 0, 512, 512)
$icono512 = Join-Path $outDir "icono_512.png"
$bmp.Save($icono512, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

# ---------------------------------------------------------------- 2. feature graphic 1024x500
$gw = 1024; $gh = 500
$bmp2 = New-Object System.Drawing.Bitmap($gw, $gh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g2 = [System.Drawing.Graphics]::FromImage($bmp2)
$g2.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g2.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g2.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# fondo: gradiente vertical verde oscuro  #003824 -> #002113
$cTop = [System.Drawing.Color]::FromArgb(255, 0x00, 0x38, 0x24)
$cBot = [System.Drawing.Color]::FromArgb(255, 0x00, 0x21, 0x13)
$rect = New-Object System.Drawing.Rectangle(0, 0, $gw, $gh)
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $cTop, $cBot, 90)
$g2.FillRectangle($grad, $rect)
$grad.Dispose()

# decoración: dos círculos translúcidos de acento
$accent = [System.Drawing.Color]::FromArgb(255, 0x6F, 0xFB, 0xBE)
$brA = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(22, 0x6F, 0xFB, 0xBE))
$g2.FillEllipse($brA, [float]150, [float]360, [float]300, [float]300)
$brA.Dispose()
$penA = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(46, 0x6F, 0xFB, 0xBE), 3)
$g2.DrawEllipse($penA, [float]740, [float]30, [float]210, [float]210)
$penA.Dispose()

# tarjeta blanca con el icono dentro
$card = New-RoundedRectPath 448 76 128 128 26
$g2.FillPath([System.Drawing.Brushes]::White, $card)
$card.Dispose()
$g2.DrawImage($src, 466, 94, 92, 92)

# wordmark "FitPulse"
$fNegrita = New-Object System.Drawing.Font("Segoe UI", 84, [System.Drawing.FontStyle]::Bold)
$fmtC = New-Object System.Drawing.StringFormat
$fmtC.Alignment     = [System.Drawing.StringAlignment]::Center
$fmtC.LineAlignment = [System.Drawing.StringAlignment]::Center
$rWord = New-Object System.Drawing.RectangleF(0, 200, $gw, 150)
$g2.DrawString("FitPulse", $fNegrita, [System.Drawing.Brushes]::White, $rWord, $fmtC)

# barra de acento
$barra = New-RoundedRectPath 470 305 84 6 3
$g2.FillPath((New-Object System.Drawing.SolidBrush($accent)), $barra)
$barra.Dispose()

# tagline
$fTag = New-Object System.Drawing.Font("Segoe UI", 27, [System.Drawing.FontStyle]::Regular)
$cTag = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0xC9, 0xDE, 0xD1))
$rTag = New-Object System.Drawing.RectangleF(0, 322, $gw, 62)
$g2.DrawString("Tu entrenamiento, nutrición y hábitos en un solo lugar", $fTag, $cTag, $rTag, $fmtC)

$fg = Join-Path $outDir "feature_graphic.png"
$bmp2.Save($fg, [System.Drawing.Imaging.ImageFormat]::Png)

$g2.Dispose(); $bmp2.Dispose()
$fNegrita.Dispose(); $fTag.Dispose(); $fmtC.Dispose(); $cTag.Dispose(); $src.Dispose()

Write-Output "Generados:"
Write-Output "  $icono512"
Write-Output "  $fg"