# Fase 5B: prepara una imagen para `emulator -camera-front imagefile:<archivo>`.
#
# El emulador (37.2.12) no entrega la imagen tal cual: con un retrato vertical
# la amplía y recorta, y con un lienzo 4:3 la desplaza y la comprime en
# horizontal (aprox. 0,75), con lo que el rostro queda pequeño. Este script
# recorta opcionalmente la imagen de prueba (-Recorte "x,y,ancho,alto" en
# píxeles, por ejemplo cabeza y hombros) y la centra en un lienzo 4:3 gris,
# ocupando como mucho -Escala del alto o del ancho. Solo cambia el encuadre:
# no retoca la imagen.
#
# Uso (PowerShell):
#   powershell -ExecutionPolicy Bypass -File tools/fase5b_lienzo_camara.ps1 `
#     -Entrada <imagen.jpg> -Salida <lienzo.png> [-Recorte "150,20,300,310"] `
#     [-Ancho 1280] [-Alto 960] [-Escala 0.6]
param(
    [Parameter(Mandatory = $true)][string]$Entrada,
    [Parameter(Mandatory = $true)][string]$Salida,
    [int]$Ancho = 1280,
    [int]$Alto = 960,
    [double]$Escala = 0.6,
    [string]$Recorte = ""
)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile((Resolve-Path $Entrada))
try {
    if ($Recorte -ne "") {
        [int[]]$r = $Recorte -split ","
        $parte = New-Object System.Drawing.Bitmap -ArgumentList $r[2], $r[3]
        $gp = [System.Drawing.Graphics]::FromImage($parte)
        $destino = New-Object System.Drawing.Rectangle -ArgumentList 0, 0, $r[2], $r[3]
        $origen = New-Object System.Drawing.Rectangle -ArgumentList $r[0], $r[1], $r[2], $r[3]
        $gp.DrawImage($img, $destino, $origen, [System.Drawing.GraphicsUnit]::Pixel)
        $gp.Dispose()
        $img.Dispose()
        $img = $parte
    }
    $f = [Math]::Min($Ancho * $Escala / $img.Width, $Alto * $Escala / $img.Height)
    $w = [int]($img.Width * $f)
    $h = [int]($img.Height * $f)
    $lienzo = New-Object System.Drawing.Bitmap -ArgumentList $Ancho, $Alto
    $g = [System.Drawing.Graphics]::FromImage($lienzo)
    $g.Clear([System.Drawing.Color]::FromArgb(128, 128, 128))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, [int](($Ancho - $w) / 2), [int](($Alto - $h) / 2), $w, $h)
    $g.Dispose()
    $lienzo.Save($Salida, [System.Drawing.Imaging.ImageFormat]::Png)
    $lienzo.Dispose()
} finally {
    $img.Dispose()
}
Get-FileHash -Algorithm SHA256 $Salida
