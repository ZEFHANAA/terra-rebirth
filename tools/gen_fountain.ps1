Add-Type -AssemblyName System.Drawing

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path (Get-Location) 'tools' }
$out = Join-Path $scriptDir '../assets/sprites/props/fountain.png'
$bitmap = [System.Drawing.Bitmap]::new(96, 128, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

$outline = [System.Drawing.Color]::FromArgb(255, 38, 48, 57)
$stoneDark = [System.Drawing.Color]::FromArgb(255, 65, 79, 89)
$stone = [System.Drawing.Color]::FromArgb(255, 104, 126, 139)
$stoneLight = [System.Drawing.Color]::FromArgb(255, 157, 177, 186)
$stoneGlint = [System.Drawing.Color]::FromArgb(255, 204, 218, 222)
$waterDark = [System.Drawing.Color]::FromArgb(255, 24, 91, 128)
$water = [System.Drawing.Color]::FromArgb(255, 48, 151, 187)
$waterLight = [System.Drawing.Color]::FromArgb(255, 132, 213, 226)

function Brush($color) { return [System.Drawing.SolidBrush]::new($color) }
function Pen($color, $width = 1) { return [System.Drawing.Pen]::new($color, $width) }
function Poly($points) { return [System.Drawing.Point[]]@($points | ForEach-Object { [System.Drawing.Point]::new($_[0], $_[1]) }) }

$bOutline = Brush $outline
$bStoneDark = Brush $stoneDark
$bStone = Brush $stone
$bStoneLight = Brush $stoneLight
$bStoneGlint = Brush $stoneGlint
$bWaterDark = Brush $waterDark
$bWater = Brush $water
$bWaterLight = Brush $waterLight

# Contact shadow and stepped stone foot.
$graphics.FillEllipse([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(78, 18, 24, 28)), 13, 112, 70, 13)
$graphics.FillPolygon($bOutline, (Poly @(@(20,101),@(76,101),@(82,111),@(72,118),@(24,118),@(14,111))))
$graphics.FillPolygon($bStone, (Poly @(@(24,103),@(72,103),@(76,110),@(69,114),@(27,114),@(20,110))))
$graphics.DrawLine((Pen $stoneGlint 2), 25, 105, 70, 105)
$graphics.FillRectangle($bOutline, 35, 94, 26, 9)
$graphics.FillRectangle($bStoneLight, 38, 94, 20, 6)

# Main pedestal and lower basin.
$graphics.FillPolygon($bOutline, (Poly @(@(39,62),@(57,62),@(60,96),@(36,96))))
$graphics.FillPolygon($bStone, (Poly @(@(43,64),@(54,64),@(56,92),@(40,92))))
$graphics.DrawLine((Pen $stoneGlint 2), 45, 67, 45, 88)
$graphics.FillPolygon($bOutline, (Poly @(@(22,56),@(74,56),@(68,79),@(28,79))))
$graphics.FillPolygon($bStoneDark, (Poly @(@(26,59),@(70,59),@(65,75),@(31,75))))
$graphics.FillEllipse($bOutline, 12, 47, 72, 21)
$graphics.FillEllipse($bStoneLight, 16, 49, 64, 15)
$graphics.FillEllipse($bWaterDark, 21, 52, 54, 10)
$graphics.DrawArc((Pen $waterLight 2), 23, 52, 49, 9, 195, 145)
$graphics.DrawLine((Pen $stoneGlint 2), 18, 56, 25, 58)
$graphics.DrawLine((Pen $stone 2), 71, 58, 78, 56)

# Upper tier and visible water jet.
$graphics.FillPolygon($bOutline, (Poly @(@(43,39),@(53,39),@(58,55),@(38,55))))
$graphics.FillPolygon($bStoneLight, (Poly @(@(46,41),@(51,41),@(54,52),@(42,52))))
$graphics.FillEllipse($bOutline, 27, 29, 42, 16)
$graphics.FillEllipse($bStone, 31, 31, 34, 10)
$graphics.FillEllipse($bWater, 35, 32, 26, 7)
$graphics.DrawArc((Pen $waterLight 2), 36, 32, 24, 6, 195, 145)
$graphics.FillRectangle($bOutline, 44, 19, 8, 12)
$graphics.FillRectangle($bWaterLight, 47, 20, 3, 9)
$graphics.FillRectangle($bWaterLight, 46, 12, 4, 6)
$graphics.FillRectangle($bWater, 38, 16, 4, 3)
$graphics.FillRectangle($bWater, 54, 15, 4, 3)
$graphics.FillRectangle($bStoneGlint, 39, 14, 1, 1)
$graphics.FillRectangle($bStoneGlint, 58, 12, 1, 1)

$graphics.Dispose()
$bitmap.Save([System.IO.Path]::GetFullPath($out), [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()
Write-Output "Generated $([System.IO.Path]::GetFullPath($out))"
