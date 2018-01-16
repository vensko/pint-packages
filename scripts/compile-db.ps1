$baseDir = $PSScriptRoot + '\..\'
$packagesIni = $baseDir + 'packages.ini'

$dirs = @(
	($baseDir + 'packages\portableapps.com'),
	($baseDir + 'packages\ugmfree.it'),
	($baseDir + 'packages\nirsoft.net'),
	($baseDir + 'packages\sysinternals'),
	($baseDir + 'packages\pint')
)

clear-content $packagesIni

$dirs |% {

	$dir = gi $_

	$ini = ''
	dir "$_\*.ini" |% {
		$ini += "[$($_.basename)]`r`n"
		$ini += [IO.File]::ReadAllText($_.fullname).trim()
		$ini += "`r`n`r`n"
	}

	$file = "$baseDir\packages-$($dir.basename).ini"

	$ini | out-file $file -encoding ascii
	$ini | out-file $packagesIni -append -encoding ascii
}
