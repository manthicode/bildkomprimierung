@echo off
setlocal

set "PS1=%TEMP%\bild_verkleinerer_temp.ps1"

(
echo Add-Type -AssemblyName System.Windows.Forms
echo Add-Type -AssemblyName System.Drawing

echo.
echo $form = New-Object System.Windows.Forms.Form
echo $form.Text = 'Bild-Komprimierung'
echo $form.Size = New-Object System.Drawing.Size(460, 420^)
echo $form.StartPosition = 'CenterScreen'
echo $form.FormBorderStyle = 'FixedDialog'
echo $form.MaximizeBox = $false
echo.
echo # --- Ordner ---
echo $lblOrdner = New-Object System.Windows.Forms.Label
echo $lblOrdner.Text = 'Ordner:'
echo $lblOrdner.Location = New-Object System.Drawing.Point(20, 22^)
echo $lblOrdner.Size = New-Object System.Drawing.Size(55, 20^)
echo $form.Controls.Add($lblOrdner^)
echo $txtOrdner = New-Object System.Windows.Forms.TextBox
echo $txtOrdner.Location = New-Object System.Drawing.Point(78, 20^)
echo $txtOrdner.Size = New-Object System.Drawing.Size(240, 20^)
echo $form.Controls.Add($txtOrdner^)
echo $btnOrdner = New-Object System.Windows.Forms.Button
echo $btnOrdner.Text = 'Waehlen...'
echo $btnOrdner.Location = New-Object System.Drawing.Point(328, 18^)
echo $btnOrdner.Size = New-Object System.Drawing.Size(100, 24^)
echo $form.Controls.Add($btnOrdner^)
echo.
echo # --- JPEG Qualitaet ---
echo $lblQ = New-Object System.Windows.Forms.Label
echo $lblQ.Text = 'JPEG Qualitaet: 75%%  (niedriger = kleinere Datei^)'
echo $lblQ.Location = New-Object System.Drawing.Point(20, 62^)
echo $lblQ.Size = New-Object System.Drawing.Size(380, 20^)
echo $form.Controls.Add($lblQ^)
echo $sliderQ = New-Object System.Windows.Forms.TrackBar
echo $sliderQ.Minimum = 10
echo $sliderQ.Maximum = 95
echo $sliderQ.Value = 75
echo $sliderQ.TickFrequency = 10
echo $sliderQ.Location = New-Object System.Drawing.Point(20, 84^)
echo $sliderQ.Size = New-Object System.Drawing.Size(410, 40^)
echo $form.Controls.Add($sliderQ^)
echo.
echo # --- Pixelgroesse ---
echo $chkResize = New-Object System.Windows.Forms.CheckBox
echo $chkResize.Text = 'Pixelgroesse zusaetzlich reduzieren auf:'
echo $chkResize.Location = New-Object System.Drawing.Point(20, 132^)
echo $chkResize.Size = New-Object System.Drawing.Size(260, 20^)
echo $chkResize.Checked = $false
echo $form.Controls.Add($chkResize^)
echo $lblR = New-Object System.Windows.Forms.Label
echo $lblR.Text = '50%%'
echo $lblR.Location = New-Object System.Drawing.Point(390, 132^)
echo $lblR.Size = New-Object System.Drawing.Size(40, 20^)
echo $form.Controls.Add($lblR^)
echo $sliderR = New-Object System.Windows.Forms.TrackBar
echo $sliderR.Minimum = 10
echo $sliderR.Maximum = 90
echo $sliderR.Value = 50
echo $sliderR.TickFrequency = 10
echo $sliderR.Enabled = $false
echo $sliderR.Location = New-Object System.Drawing.Point(20, 152^)
echo $sliderR.Size = New-Object System.Drawing.Size(410, 40^)
echo $form.Controls.Add($sliderR^)
echo.
echo # --- Log ---
echo $txtLog = New-Object System.Windows.Forms.TextBox
echo $txtLog.Location = New-Object System.Drawing.Point(20, 205^)
echo $txtLog.Size = New-Object System.Drawing.Size(410, 130^)
echo $txtLog.Multiline = $true
echo $txtLog.ScrollBars = 'Vertical'
echo $txtLog.ReadOnly = $true
echo $form.Controls.Add($txtLog^)
echo.
echo # --- Button ---
echo $btnStart = New-Object System.Windows.Forms.Button
echo $btnStart.Text = 'Jetzt komprimieren'
echo $btnStart.Location = New-Object System.Drawing.Point(150, 350^)
echo $btnStart.Size = New-Object System.Drawing.Size(150, 30^)
echo $form.Controls.Add($btnStart^)
echo.
echo # --- Events ---
echo $sliderQ.Add_ValueChanged({ $lblQ.Text = 'JPEG Qualitaet: ' + $sliderQ.Value + '%% (niedriger = kleinere Datei^)' }^)
echo $sliderR.Add_ValueChanged({ $lblR.Text = $sliderR.Value.ToString(^) + '%%' }^)
echo $chkResize.Add_CheckedChanged({ $sliderR.Enabled = $chkResize.Checked }^)
echo.
echo $btnOrdner.Add_Click({
echo     $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
echo     if ($dlg.ShowDialog(^) -eq 'OK'^) { $txtOrdner.Text = $dlg.SelectedPath }
echo }^)
echo.
echo $btnStart.Add_Click({
echo     $ordner = $txtOrdner.Text
echo     if (-not (Test-Path $ordner^)^) { [System.Windows.Forms.MessageBox]::Show('Bitte Ordner waehlen.','Fehler'^); return }
echo     $ext = @('.jpg','.jpeg','.png','.tiff','.tif','.gif'^)
echo     $bilder = Get-ChildItem -Path $ordner -File ^| Where-Object { $ext -contains $_.Extension.ToLower(^) }
echo     if ($bilder.Count -eq 0^) { [System.Windows.Forms.MessageBox]::Show('Keine Bilder gefunden.','Hinweis'^); return }
echo     $msg = $bilder.Count.ToString(^) + ' Bild(er^) werden komprimiert und ersetzt. Fortfahren?'
echo     $antwort = [System.Windows.Forms.MessageBox]::Show($msg,'Bestaetigung',[System.Windows.Forms.MessageBoxButtons]::YesNo^)
echo     if ($antwort -ne 'Yes'^) { return }
echo     $txtLog.Clear(^)
echo     $quality = $sliderQ.Value
echo     $doResize = $chkResize.Checked
echo     $resizeFactor = $sliderR.Value / 100.0
echo     $ok = 0; $fehler = 0; $sparung = 0
echo.
echo     # JPEG Encoder holen
echo     $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders(^) ^| Where-Object { $_.MimeType -eq 'image/jpeg' } ^| Select-Object -First 1
echo     $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1^)
echo     $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality^)
echo.
echo     foreach ($datei in $bilder^) {
echo         try {
echo             $vorher = (Get-Item $datei.FullName^).Length
echo             $img = [System.Drawing.Image]::FromFile($datei.FullName^)
echo             $w = $img.Width; $h = $img.Height
echo             if ($doResize^) { $w = [int]($w * $resizeFactor^); $h = [int]($h * $resizeFactor^) }
echo             $bmp = New-Object System.Drawing.Bitmap($w, $h^)
echo             $g = [System.Drawing.Graphics]::FromImage($bmp^)
echo             $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
echo             $g.DrawImage($img, 0, 0, $w, $h^)
echo             $g.Dispose(^); $img.Dispose(^)
echo             $tmpFile = $datei.FullName + '.tmp'
echo             $extLow = $datei.Extension.ToLower(^)
echo             if ($extLow -eq '.jpg' -or $extLow -eq '.jpeg'^) {
echo                 $bmp.Save($tmpFile, $jpegCodec, $encoderParams^)
echo             } elseif ($extLow -eq '.png'^) {
echo                 $bmp.Save($tmpFile, [System.Drawing.Imaging.ImageFormat]::Png^)
echo             } elseif ($extLow -eq '.tiff' -or $extLow -eq '.tif'^) {
echo                 $bmp.Save($tmpFile, [System.Drawing.Imaging.ImageFormat]::Tiff^)
echo             } else {
echo                 $bmp.Save($tmpFile, [System.Drawing.Imaging.ImageFormat]::Gif^)
echo             }
echo             $bmp.Dispose(^)
echo             Remove-Item $datei.FullName -Force
echo             Rename-Item $tmpFile $datei.FullName
echo             $nachher = (Get-Item $datei.FullName^).Length
echo             $diff = $vorher - $nachher
echo             $sparung += $diff
echo             $pct = if ($vorher -gt 0^) { [int](($diff / $vorher^) * 100^) } else { 0 }
echo             $txtLog.AppendText('OK: ' + $datei.Name + '  -' + $pct + '%% (' + [math]::Round($diff/1KB,1^) + ' KB gespart^)' + [Environment]::NewLine^)
echo             $ok++
echo         } catch {
echo             $txtLog.AppendText('FEHLER: ' + $datei.Name + ' >> ' + $_.Exception.Message + [Environment]::NewLine^)
echo             $fehler++
echo         }
echo     }
echo     $gesamtKB = [math]::Round($sparung / 1KB, 1^)
echo     $gesamtMB = [math]::Round($sparung / 1MB, 2^)
echo     $summary = 'Gesamt gespart: ' + $gesamtKB + ' KB (' + $gesamtMB + ' MB^)'
echo     $txtLog.AppendText([Environment]::NewLine + $summary^)
echo     [System.Windows.Forms.MessageBox]::Show('Fertig!  OK: ' + $ok + '  Fehler: ' + $fehler + [Environment]::NewLine + $summary,'Ergebnis'^)
echo }^)
echo.
echo [void]$form.ShowDialog(^)
) > "%PS1%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"

if errorlevel 1 (
    echo.
    echo FEHLER beim Ausfuehren. Details stehen oben.
)

del "%PS1%" 2>nul
endlocal
