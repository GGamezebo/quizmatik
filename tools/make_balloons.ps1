Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class BalloonAtlas
{
    // Soft chroma key on green screen (~R23 G191 B6): alpha from G - max(R,B), plus despill.
    public static Bitmap KeyOut(Bitmap src, double dLow, double dHigh)
    {
        int w = src.Width, h = src.Height;
        Bitmap outBmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        BitmapData sd = src.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        BitmapData dd = outBmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        byte[] sbuf = new byte[sd.Stride * h];
        byte[] dbuf = new byte[dd.Stride * h];
        Marshal.Copy(sd.Scan0, sbuf, 0, sbuf.Length);

        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                int i = y * sd.Stride + x * 4;
                double b = sbuf[i], g = sbuf[i + 1], r = sbuf[i + 2];
                double maxRB = Math.Max(r, b);
                double d = g - maxRB;
                double alpha;
                if (d <= dLow) alpha = 1.0;
                else if (d >= dHigh) alpha = 0.0;
                else alpha = 1.0 - (d - dLow) / (dHigh - dLow);

                double gOut = g;
                if (d > dLow) gOut = maxRB + dLow;  // despill green fringe

                int j = y * dd.Stride + x * 4;
                dbuf[j] = (byte)b;
                dbuf[j + 1] = (byte)Math.Min(255.0, gOut);
                dbuf[j + 2] = (byte)r;
                dbuf[j + 3] = (byte)Math.Round(alpha * 255.0);
            }
        }

        Marshal.Copy(dbuf, 0, dd.Scan0, dbuf.Length);
        src.UnlockBits(sd);
        outBmp.UnlockBits(dd);
        return outBmp;
    }

    public static Rectangle ContentBox(Bitmap bmp, Rectangle cell, int alphaMin)
    {
        int minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1;
        for (int y = cell.Top; y < cell.Bottom; y++)
            for (int x = cell.Left; x < cell.Right; x++)
            {
                if (bmp.GetPixel(x, y).A > alphaMin)
                {
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        if (maxX < 0) return Rectangle.Empty;
        return Rectangle.FromLTRB(minX, minY, maxX + 1, maxY + 1);
    }
}
"@ -ReferencedAssemblies System.Drawing

Add-Type -AssemblyName System.Drawing

$src = "C:\Users\IYuBe\.cursor\projects\d-i-belov-GProjects-MyProject-quizmatik\assets\c__Users_IYuBe_AppData_Roaming_Cursor_User_workspaceStorage_5cb6abd271110454be5d74296801fc77_images_Gemini_Generated_Image_3ihy5t3ihy5t3ihy-e78ecc1b-ee3d-4f28-a624-61efa872dd91.png"
$dst = "d:\i_belov\GProjects\MyProject\quizmatik\src\features\answer\balloons_atlas.png"

$raw = New-Object System.Drawing.Bitmap $src
$srcBmp = New-Object System.Drawing.Bitmap($raw.Width, $raw.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g0 = [System.Drawing.Graphics]::FromImage($srcBmp)
$g0.DrawImage($raw, 0, 0, $raw.Width, $raw.Height)
$g0.Dispose()
$raw.Dispose()

$keyed = [BalloonAtlas]::KeyOut($srcBmp, 30.0, 100.0)
$srcBmp.Dispose()

$cellW = 256
$cellH = 240
$atlas = New-Object System.Drawing.Bitmap((5 * $cellW), (3 * $cellH), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($atlas)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy

$heights = @()
for ($i = 0; $i -lt 15; $i++) {
    $srcCol = $i % 4
    $srcRow = [math]::Floor($i / 4)
    $sy = [int][math]::Round($srcRow * 959.0 / 4.0)
    $sh = [math]::Min($cellH, $keyed.Height - $sy)
    $srcRect = New-Object System.Drawing.Rectangle(($srcCol * $cellW), $sy, $cellW, $sh)

    $dstCol = $i % 5
    $dstRow = [math]::Floor($i / 5)
    $dstRect = New-Object System.Drawing.Rectangle(($dstCol * $cellW), ($dstRow * $cellH), $cellW, $sh)
    $g.DrawImage($keyed, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

    $box = [BalloonAtlas]::ContentBox($keyed, $srcRect, 32)
    $heights += $box.Height
    Write-Host "frame $i src($srcCol,$srcRow) content $($box.Width)x$($box.Height)"
}

$g.Dispose()
$keyed.Dispose()
$atlas.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$atlas.Dispose()

$avg = ($heights | Measure-Object -Average).Average
$min = ($heights | Measure-Object -Minimum).Minimum
$max = ($heights | Measure-Object -Maximum).Maximum
Write-Host "Atlas saved: $dst ($([math]::Round((Get-Item $dst).Length/1KB,1)) KB)"
Write-Host "Balloon heights: avg=$([math]::Round($avg,1)) min=$min max=$max"
