# Resizes the Android emulator window so the whole phone fits the screen height,
# and puts it at the right side of the screen. Called by start-app.bat.
# If anything goes wrong it just does nothing: the emulator keeps its own size.

Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class FitWin {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int x, int y, int w, int h, bool repaint);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
}
"@

# Work in real screen pixels, so laptops with 125% or 150% scaling come out right.
[FitWin]::SetProcessDPIAware() | Out-Null

# Wait up to 20 seconds for the emulator window ("Android Emulator - <phone>").
$window = $null
for ($i = 0; $i -lt 20 -and -not $window; $i++) {
    $window = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -like 'Android Emulator*' } |
        Select-Object -First 1
    if (-not $window) { Start-Sleep -Seconds 1 }
}
if (-not $window) { exit 0 }

$handle = $window.MainWindowHandle
[FitWin]::ShowWindow($handle, 9) | Out-Null   # 9 = restore if it was minimized
Start-Sleep -Milliseconds 500

$rect = New-Object FitWin+RECT
if (-not [FitWin]::GetWindowRect($handle, [ref]$rect)) { exit 0 }
$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
if ($width -le 0 -or $height -le 0) { exit 0 }

# The screen area without the taskbar.
$area = [System.Windows.Forms.Screen]::FromHandle($handle).WorkingArea
$gap = [int]($area.Height * 0.02)

# As tall as the screen allows, keeping the phone's shape.
$newHeight = $area.Height - 2 * $gap
$newWidth = [int]($width * $newHeight / $height)

# Right side of the screen, leaving room for the emulator's button bar.
$toolbar = [int]($newHeight * 0.09)
$x = $area.Right - $newWidth - $toolbar - $gap
$y = $area.Top + $gap
[FitWin]::MoveWindow($handle, $x, $y, $newWidth, $newHeight, $true) | Out-Null
