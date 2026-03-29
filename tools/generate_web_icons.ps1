$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

function New-RoundedRectPath {
  param(
    [System.Drawing.RectangleF]$Rect,
    [float]$Radius
  )

  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $diameter = 2 * $Radius
  $arc = New-Object System.Drawing.RectangleF($Rect.X, $Rect.Y, $diameter, $diameter)

  $path.AddArc($arc, 180, 90)
  $arc.X = $Rect.Right - $diameter
  $path.AddArc($arc, 270, 90)
  $arc.Y = $Rect.Bottom - $diameter
  $path.AddArc($arc, 0, 90)
  $arc.X = $Rect.X
  $path.AddArc($arc, 90, 90)
  $path.CloseFigure() | Out-Null

  return $path
}

function Draw-CartiqoIcon {
  param(
    [int]$Size,
    [string]$OutPath,
    [bool]$Maskable = $false
  )

  $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)

  $rect = New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)

  $cornerRadius = [float]($Size * 0.22)
  if ($Maskable) { $cornerRadius = [float]($Size * 0.12) }

  $bgPath = New-RoundedRectPath -Rect $rect -Radius $cornerRadius
  $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.Color]::FromArgb(255, 11, 94, 215),
    [System.Drawing.Color]::FromArgb(255, 18, 184, 134),
    [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
  )
  $g.FillPath($bgBrush, $bgPath)
  $bgBrush.Dispose()
  $bgPath.Dispose()

  $pad = [float]($Size * 0.16)
  if ($Maskable) { $pad = [float]($Size * 0.20) }

  $white = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
  $yellow = [System.Drawing.Color]::FromArgb(255, 255, 200, 61)

  # Cart body
  $cartX = $pad
  $cartY = [float]($Size * 0.36)
  $cartW = [float]($Size - 2 * $pad)
  $cartH = [float]($Size * 0.26)
  $cartRect = New-Object System.Drawing.RectangleF($cartX, $cartY, $cartW, $cartH)
  $cartPath = New-RoundedRectPath -Rect $cartRect -Radius ([float]($Size * 0.06))
  $g.FillPath((New-Object System.Drawing.SolidBrush($white)), $cartPath)
  $cartPath.Dispose()

  # Handle
  $handlePen = New-Object System.Drawing.Pen($white, [float]($Size * 0.06))
  $handlePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $handlePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $handlePath = New-Object System.Drawing.Drawing2D.GraphicsPath
  $handlePath.AddBezier(
    [System.Drawing.PointF]::new($cartX + [float]($cartW * 0.08), $cartY),
    [System.Drawing.PointF]::new($cartX + [float]($cartW * 0.22), $cartY - [float]($Size * 0.18)),
    [System.Drawing.PointF]::new($cartX + [float]($cartW * 0.40), $cartY - [float]($Size * 0.12)),
    [System.Drawing.PointF]::new($cartX + [float]($cartW * 0.52), $cartY + [float]($cartH * 0.02))
  )
  $g.DrawPath($handlePen, $handlePath)
  $handlePen.Dispose()
  $handlePath.Dispose()

  # Wheels
  $wheelBrush = New-Object System.Drawing.SolidBrush($white)
  $wheelR = [float]($Size * 0.06)
  $wheelY = [float]($Size * 0.72)
  $g.FillEllipse($wheelBrush, $cartX + [float]($cartW * 0.22) - $wheelR, $wheelY - $wheelR, $wheelR * 2, $wheelR * 2)
  $g.FillEllipse($wheelBrush, $cartX + [float]($cartW * 0.78) - $wheelR, $wheelY - $wheelR, $wheelR * 2, $wheelR * 2)
  $wheelBrush.Dispose()

  # Lightning bolt
  $bolt = New-Object System.Drawing.Drawing2D.GraphicsPath
  $boltPts = @(
    [System.Drawing.PointF]::new([float]($Size * 0.60), [float]($Size * 0.18)),
    [System.Drawing.PointF]::new([float]($Size * 0.46), [float]($Size * 0.44)),
    [System.Drawing.PointF]::new([float]($Size * 0.58), [float]($Size * 0.44)),
    [System.Drawing.PointF]::new([float]($Size * 0.50), [float]($Size * 0.68)),
    [System.Drawing.PointF]::new([float]($Size * 0.72), [float]($Size * 0.38)),
    [System.Drawing.PointF]::new([float]($Size * 0.58), [float]($Size * 0.38))
  )
  $bolt.AddPolygon($boltPts)
  $g.FillPath((New-Object System.Drawing.SolidBrush($yellow)), $bolt)
  $bolt.Dispose()

  $g.Dispose()
  $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

$webIcons = Join-Path (Get-Location) 'web/icons'
if (-not (Test-Path $webIcons)) {
  New-Item -ItemType Directory -Path $webIcons | Out-Null
}

Draw-CartiqoIcon -Size 512 -OutPath (Join-Path $webIcons 'Icon-512.png') -Maskable:$false
Draw-CartiqoIcon -Size 192 -OutPath (Join-Path $webIcons 'Icon-192.png') -Maskable:$false
Draw-CartiqoIcon -Size 512 -OutPath (Join-Path $webIcons 'Icon-maskable-512.png') -Maskable:$true
Draw-CartiqoIcon -Size 192 -OutPath (Join-Path $webIcons 'Icon-maskable-192.png') -Maskable:$true
Draw-CartiqoIcon -Size 32 -OutPath (Join-Path (Get-Location) 'web/favicon.png') -Maskable:$false

Write-Host 'Generated Cartiqo web icons.'
