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

$index = @{}

$dirs |% {

	$dir = gi $_

	$ini = ''
	dir "$_\*.ini" |% {
		$id = $_.basename
		$config = [IO.File]::ReadAllText($_.fullname).trim()

		$section = ''
		$section += "[$id]`r`n"
		$section += $config
		$section += "`r`n`r`n"

		$ini += $section
		$index[$id] = $section
	}

	$file = "$baseDir\packages-$($dir.basename).ini"

	$ini | out-file $file -encoding ascii
}

$index.values -join '' | out-file $packagesIni -encoding ascii
