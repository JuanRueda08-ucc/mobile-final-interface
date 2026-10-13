# Fase 5B: compone dos recortes de una imagen de prueba, uno encima de otro,
# en un lienzo vertical gris, para `emulator -camera-front imagefile:`.
#
# La cámara emulada (emulador 37.2.12) solo deja ver una franja vertical
# estrecha de la imagen: dos rostros lado a lado no caben a la vez. Apilados,
# sí. Es una composición de prueba (dos recortes sin retocar de la misma
# foto), no una foto original.
#
# Uso (PowerShell):
#   powershell -ExecutionPolicy Bypass -File tools/fase5b_apilar_rostros.ps1 `
#     -Entrada <imagen.jpg> -Salida <lienzo.png> -Arriba "x,y,ancho,alto" -Abajo "x,y,ancho,alto"
param(
    [Parameter(Mandatory = $true)][string]$Entrada,
    [Parameter(Mandatory = $true)][string]$Salida,
    [Parameter(Mandatory = $true)][string]$Arriba,
    [Parameter(Mandatory = $true)][string]$Abajo,
    [int]$Ancho = 960,
    [int]$Alto = 1280
)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile((Resolve-Path $Entrada))
try {
    $lienzo = New-Object System.Drawing.Bitmap -ArgumentList $Ancho, $Alto
    $g = [System.Drawing.Graphics]::FromImage($lienzo)
    $g.Clear([System.Drawing.Color]::FromArgb(128, 128, 128))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $mitad = [int]($Alto / 2)
    $i = 0
    foreach ($spec in @($Arriba, $Abajo)) {
        [int[]]$r = $spec -split ","
        $f = [Math]::Min($Ancho * 0.9 / $r[2], $mitad * 0.9 / $r[3])
        $w = [int]($r[2] * $f)
        $h = [int]($r[3] * $f)
        $destino = New-Object System.Drawing.Rectangle -ArgumentList ([int](($Ancho - $w) / 2)), ([int]($i * $mitad + ($mitad - $h) / 2)), $w, $h
        $origen = New-Object System.Drawing.Rectangle -ArgumentList $r[0], $r[1], $r[2], $r[3]
        $g.DrawImage($img, $destino, $origen, [System.Drawing.GraphicsUnit]::Pixel)
        $i++
    }
    $g.Dispose()
    $lienzo.Save($Salida, [System.Drawing.Imaging.ImageFormat]::Png)
    $lienzo.Dispose()
} finally {
    $img.Dispose()
}
Get-FileHash -Algorithm SHA256 $Salida
