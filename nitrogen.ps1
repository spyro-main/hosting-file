# ============================================
# GDI-STYLE VISUAL EFFECT
# PowerShell 5.1
#
# Exit: ESC, F12, or mouse click
# ============================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================
# SCREEN
# ============================================

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

$width  = $screen.Width
$height = $screen.Height

# ============================================
# CURSOR API
# ============================================

$cursorTypeName = "CursorAPI_GDI_" + ([guid]::NewGuid().ToString("N"))

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class $cursorTypeName
{
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT p);

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT
    {
        public int X;
        public int Y;
    }
}
"@

$CursorAPI = $cursorTypeName -as [type]

# ============================================
# REMEMBER ORIGINAL CURSOR POSITION
# ============================================

$p = New-Object "$cursorTypeName+POINT"

$CursorAPI::GetCursorPos([ref]$p) | Out-Null

$originalX = $p.X
$originalY = $p.Y

# ============================================
# FORM
# ============================================

$form = New-Object System.Windows.Forms.Form

$form.FormBorderStyle = 'None'
$form.StartPosition = 'Manual'

$form.Location = New-Object System.Drawing.Point(
    $screen.X,
    $screen.Y
)

$form.Size = New-Object System.Drawing.Size(
    $width,
    $height
)

$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.KeyPreview = $true

$form.BackColor = [System.Drawing.Color]::Black

# Black is transparent
$form.TransparencyKey = [System.Drawing.Color]::Black

# ============================================
# ENABLE DOUBLE BUFFERING
# ============================================

$doubleBufferedProperty = $form.GetType().GetProperty(
    "DoubleBuffered",
    [System.Reflection.BindingFlags]::Instance -bor
    [System.Reflection.BindingFlags]::NonPublic
)

if ($doubleBufferedProperty)
{
    $doubleBufferedProperty.SetValue(
        $form,
        $true,
        $null
    )
}

# ============================================
# RANDOM
# ============================================

$rand = [System.Random]::new()

$errorIcon = [System.Drawing.SystemIcons]::Error

# ============================================
# FLOATING ERROR ICONS
# ============================================

$icons = New-Object System.Collections.Generic.List[object]

for ($i = 0; $i -lt 24; $i++)
{
    $icons.Add(
        [PSCustomObject]@{
            X = [double]$rand.Next(
                0,
                [Math]::Max(1, $width - 48)
            )

            Y = [double]$rand.Next(
                0,
                [Math]::Max(1, $height - 48)
            )

            VX = [double]$rand.Next(-8, 9)
            VY = [double]$rand.Next(-8, 9)

            Size = [double]$rand.Next(24, 72)

            Life = $rand.Next(20, 180)
        }
    )
}

# ============================================
# BALL
# ============================================

$ball = [PSCustomObject]@{
    X = [double]($width / 2)
    Y = [double]($height / 2)

    # Fast movement
    VX = 11.0
    VY = 7.5

    # Ball size
    Radius = 42.0

    # Rainbow hue
    Hue = 0.0
}

# ============================================
# BALL TRAIL
# ============================================

$trail = New-Object System.Collections.Generic.List[object]

$trailLength = 32

# ============================================
# HSV -> RGB
# ============================================

function Get-HSVColor
{
    param(
        [double]$Hue,
        [double]$Saturation = 1.0,
        [double]$Value = 1.0
    )

    $Hue = $Hue % 360

    if ($Hue -lt 0)
    {
        $Hue += 360
    }

    $h = $Hue / 60.0

    $c = $Value * $Saturation

    $x = $c * (
        1 - [Math]::Abs(
            ($h % 2) - 1
        )
    )

    $m = $Value - $c

    if ($h -lt 1)
    {
        $r = $c
        $g = $x
        $b = 0
    }
    elseif ($h -lt 2)
    {
        $r = $x
        $g = $c
        $b = 0
    }
    elseif ($h -lt 3)
    {
        $r = 0
        $g = $c
        $b = $x
    }
    elseif ($h -lt 4)
    {
        $r = 0
        $g = $x
        $b = $c
    }
    elseif ($h -lt 5)
    {
        $r = $x
        $g = 0
        $b = $c
    }
    else
    {
        $r = $c
        $g = 0
        $b = $x
    }

    return [System.Drawing.Color]::FromArgb(
        255,
        [int](($r + $m) * 255),
        [int](($g + $m) * 255),
        [int](($b + $m) * 255)
    )
}

# ============================================
# PAINT
# ============================================

$form.Add_Paint({

    param($sender, $e)

    $g = $e.Graphics

    $g.SmoothingMode =
        [System.Drawing.Drawing2D.SmoothingMode]::HighSpeed

    $g.InterpolationMode =
        [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor

    $g.PixelOffsetMode =
        [System.Drawing.Drawing2D.PixelOffsetMode]::HighSpeed

    # ========================================
    # RANDOM COLORED RECTANGLES
    # ========================================

    for ($i = 0; $i -lt 90; $i++)
    {
        $x = $rand.Next(0, $width)
        $y = $rand.Next(0, $height)

        $w = $rand.Next(2, 220)
        $h = $rand.Next(2, 90)

        $colors = @(
            [System.Drawing.Color]::Red
            [System.Drawing.Color]::Lime
            [System.Drawing.Color]::Blue
            [System.Drawing.Color]::Magenta
            [System.Drawing.Color]::Cyan
            [System.Drawing.Color]::Yellow
            [System.Drawing.Color]::White
        )

        $c = $colors[
            $rand.Next($colors.Count)
        ]

        $brush = New-Object System.Drawing.SolidBrush(
            [System.Drawing.Color]::FromArgb(
                $rand.Next(30, 190),
                $c.R,
                $c.G,
                $c.B
            )
        )

        $g.FillRectangle(
            $brush,
            $x,
            $y,
            $w,
            $h
        )

        $brush.Dispose()
    }

    # ========================================
    # CORRUPTION BARS
    # ========================================

    for ($i = 0; $i -lt 35; $i++)
    {
        $y = $rand.Next($height)
        $h = $rand.Next(1, 18)

        $pen = New-Object System.Drawing.Pen(
            [System.Drawing.Color]::FromArgb(
                $rand.Next(80, 255),
                $rand.Next(256),
                $rand.Next(256),
                $rand.Next(256)
            ),
            $h
        )

        $g.DrawLine(
            $pen,
            0,
            $y,
            $width,
            $y + $rand.Next(-15, 16)
        )

        $pen.Dispose()
    }

    # ========================================
    # ERROR ICONS
    # ========================================

    foreach ($icon in $icons)
    {
        $rect = New-Object System.Drawing.Rectangle(
            [int]$icon.X,
            [int]$icon.Y,
            [int]$icon.Size,
            [int]$icon.Size
        )

        $g.DrawIcon(
            $errorIcon,
            $rect
        )
    }

    # ========================================
    # FAKE DIAGNOSTIC TEXT
    # ========================================

    $font = New-Object System.Drawing.Font(
        'Consolas',
        14,
        [System.Drawing.FontStyle]::Bold
    )

    $texts = @(
        'GDI_EXCEPTION'
        'WINDOW_CORRUPTED'
        'INVALID_HANDLE'
        '0xDEADFACE'
        'DRAW_ERROR'
        'MEMORY_REGION'
        '!!!'
        'ERROR'
    )

    for ($i = 0; $i -lt 15; $i++)
    {
        $text = $texts[
            $rand.Next($texts.Count)
        ]

        $brush = New-Object System.Drawing.SolidBrush(
            [System.Drawing.Color]::FromArgb(
                $rand.Next(100, 255),
                255,
                $rand.Next(0, 120),
                $rand.Next(0, 120)
            )
        )

        $g.DrawString(
            $text,
            $font,
            $brush,
            $rand.Next(0, $width),
            $rand.Next(0, $height)
        )

        $brush.Dispose()
    }

    $font.Dispose()

    # ========================================
    # BALL TRAIL
    # ========================================

    for ($i = $trail.Count - 1; $i -ge 0; $i--)
    {
        $t = $trail[$i]

        # Older trail = smaller and more transparent
        $progress = 1.0 - (
            $i /
            [Math]::Max(1, $trail.Count)
        )

        $alpha = [int](
            20 + (150 * $progress)
        )

        $trailRadius = $t.Radius * (
            0.35 + (0.65 * $progress)
        )

        $trailColor = Get-HSVColor `
            -Hue $t.Hue `
            -Saturation 0.95 `
            -Value 1.0

        # Filled colored trail circle
        $trailBrush = New-Object System.Drawing.SolidBrush(
            [System.Drawing.Color]::FromArgb(
                $alpha,
                $trailColor.R,
                $trailColor.G,
                $trailColor.B
            )
        )

        $g.FillEllipse(
            $trailBrush,
            [int]($t.X - $trailRadius),
            [int]($t.Y - $trailRadius),
            [int]($trailRadius * 2),
            [int]($trailRadius * 2)
        )

        $trailBrush.Dispose()
    }

    # ========================================
    # MAIN BALL COLOR
    # ========================================

    $ballColor = Get-HSVColor `
        -Hue $ball.Hue `
        -Saturation 0.95 `
        -Value 1.0

    # ========================================
    # MAIN FILLED BALL
    # ========================================

    $ballBrush = New-Object System.Drawing.SolidBrush(
        $ballColor
    )

    $g.FillEllipse(
        $ballBrush,
        [int]($ball.X - $ball.Radius),
        [int]($ball.Y - $ball.Radius),
        [int]($ball.Radius * 2),
        [int]($ball.Radius * 2)
    )

    $ballBrush.Dispose()

    # ========================================
    # BLACK OUTLINE
    # ========================================

    $outlinePen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::Black,
        6
    )

    $g.DrawEllipse(
        $outlinePen,
        [int]($ball.X - $ball.Radius),
        [int]($ball.Y - $ball.Radius),
        [int]($ball.Radius * 2),
        [int]($ball.Radius * 2)
    )

    $outlinePen.Dispose()

    # ========================================
    # SMALL WHITE HIGHLIGHT
    # ========================================

    $highlightRadius = $ball.Radius * 0.23

    $highlightBrush = New-Object System.Drawing.SolidBrush(
        [System.Drawing.Color]::FromArgb(
            140,
            255,
            255,
            255
        )
    )

    $g.FillEllipse(
        $highlightBrush,
        [int](
            $ball.X -
            ($ball.Radius * 0.55) -
            $highlightRadius
        ),
        [int](
            $ball.Y -
            ($ball.Radius * 0.55) -
            $highlightRadius
        ),
        [int]($highlightRadius * 2),
        [int]($highlightRadius * 2)
    )

    $highlightBrush.Dispose()
})

# ============================================
# TIMER
# ============================================

$timer = New-Object System.Windows.Forms.Timer

# ~60 FPS
$timer.Interval = 16

$timer.Add_Tick({

    # ========================================
    # MOVE ERROR ICONS
    # ========================================

    foreach ($icon in $icons)
    {
        $icon.X += $icon.VX
        $icon.Y += $icon.VY

        if ($icon.X -gt $width)
        {
            $icon.X = -$icon.Size
        }

        if ($icon.X -lt -$icon.Size)
        {
            $icon.X = $width
        }

        if ($icon.Y -gt $height)
        {
            $icon.Y = -$icon.Size
        }

        if ($icon.Y -lt -$icon.Size)
        {
            $icon.Y = $height
        }

        $icon.Life--

        if ($icon.Life -le 0)
        {
            $icon.X = $rand.Next($width)
            $icon.Y = $rand.Next($height)

            $icon.VX = $rand.Next(-8, 9)
            $icon.VY = $rand.Next(-8, 9)

            $icon.Size = $rand.Next(24, 72)
            $icon.Life = $rand.Next(20, 180)
        }
    }

    # ========================================
    # CONTINUOUS RAINBOW
    # ========================================

    $ball.Hue += 2.5

    if ($ball.Hue -ge 360)
    {
        $ball.Hue -= 360
    }

    # ========================================
    # SAVE BALL POSITION
    # ========================================

    $trail.Insert(
        0,
        [PSCustomObject]@{
            X = $ball.X
            Y = $ball.Y
            Hue = $ball.Hue
            Radius = $ball.Radius
        }
    )

    # Limit trail length
    while ($trail.Count -gt $trailLength)
    {
        $trail.RemoveAt(
            $trail.Count - 1
        )
    }

    # ========================================
    # FAST BALL MOVEMENT
    # ========================================

    $ball.X += $ball.VX
    $ball.Y += $ball.VY

    # ========================================
    # BOUNCE LEFT
    # ========================================

    if ($ball.X - $ball.Radius -le 0)
    {
        $ball.X = $ball.Radius
        $ball.VX = [Math]::Abs($ball.VX)
    }

    # ========================================
    # BOUNCE RIGHT
    # ========================================

    if ($ball.X + $ball.Radius -ge $width)
    {
        $ball.X = $width - $ball.Radius
        $ball.VX = -[Math]::Abs($ball.VX)
    }

    # ========================================
    # BOUNCE TOP
    # ========================================

    if ($ball.Y - $ball.Radius -le 0)
    {
        $ball.Y = $ball.Radius
        $ball.VY = [Math]::Abs($ball.VY)
    }

    # ========================================
    # BOUNCE BOTTOM
    # ========================================

    if ($ball.Y + $ball.Radius -ge $height)
    {
        $ball.Y = $height - $ball.Radius
        $ball.VY = -[Math]::Abs($ball.VY)
    }

    # ========================================
    # CURSOR JITTER
    # ========================================

    $jitterX = $rand.Next(-12, 13)
    $jitterY = $rand.Next(-12, 13)

    $CursorAPI::SetCursorPos(
        $originalX + $jitterX,
        $originalY + $jitterY
    ) | Out-Null

    # Redraw
    $form.Invalidate()
})

# ============================================
# ESC / F12 EXIT
# ============================================

$form.Add_KeyDown({

    param($sender, $e)

    if (
        $e.KeyCode -eq [System.Windows.Forms.Keys]::Escape -or
        $e.KeyCode -eq [System.Windows.Forms.Keys]::F12
    )
    {
        $timer.Stop()

        $CursorAPI::SetCursorPos(
            $originalX,
            $originalY
        ) | Out-Null

        $form.Close()
    }
})

# ============================================
# MOUSE CLICK EXIT
# ============================================

$form.Add_MouseClick({

    $timer.Stop()

    $CursorAPI::SetCursorPos(
        $originalX,
        $originalY
    ) | Out-Null

    $form.Close()
})

# ============================================
# START
# ============================================

$timer.Start()

try
{
    [void]$form.ShowDialog()
}
finally
{
    $timer.Stop()
    $timer.Dispose()

    if ($form -ne $null)
    {
        $form.Dispose()
    }

    # Always restore cursor
    $CursorAPI::SetCursorPos(
        $originalX,
        $originalY
    ) | Out-Null
}
