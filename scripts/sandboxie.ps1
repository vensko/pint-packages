$id, $exe, $exeargs = $args

. .\common.ps1

function get-exe($dir)
{
	$files = dir $dir -filter *.exe -exclude *portable.exe,uninst*.exe -ea 0
	if (!$files) { $files = dir $dir -r -filter *.exe -exclude *portable.exe,uninst*.exe -ea 1 }
	$files | sort length -desc | select -first 1
}

$pint = "d:\Dropbox\Total Commander\CLI\pint\pint.cmd"
$sandboxie = "c:\Program Files\Sandboxie\Start.exe"
$createbox = "c:\Program Files\Sandboxie\SbieIni.exe"

$sandboxieDir = $baseDir + '\sandboxie'
$boxDir = $sandboxieDir + '\boxes'
$env:PINT_APP_DIR = $sandboxieDir + '\apps'
$env:PINT_DIST_DIR = $sandboxieDir + '\dist'

$appDir = join-path $env:PINT_APP_DIR $id

if (!(dir $appDir -n -ea 0)) {
	& $pint install $id | out-null
}

if (!$exe) {
	$exe = get-exe $appDir
}

$box = 'pint' + ($id -replace '[^\w]+','')

& $createbox set $box Enabled y
& $createbox set $box FileRootPath "$boxDir\$box"
& cmd /d /c "start `"`" /wait `"$sandboxie`" /nosbiectrl /wait /box:$box `"$exe`" $exeargs"

$appBoxDir = "$boxDir\$box\drive\" + $appDir.replace(':','')

if (!(dir $appBoxDir -n -ea 0)) {
	write-host "No filesystem changes." -f red
	exit
}

write-host "Filesystem changes:" -f yellow
(dir $appBoxDir -n) -join ', '
