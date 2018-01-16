$baseDir = $PSScriptRoot + '\..\'

$dirs = @(
	($baseDir + 'portableapps.com'),
	($baseDir + 'packages')
)

$ini = ''

$dirs |% {
	dir "$_\*.ini" |% {
		$ini += "[$($_.basename)]`r`n"
		$ini += [IO.File]::ReadAllText($_.fullname)
		$ini += "`r`n"
	}
}

$ini.trim() | out-file "$baseDir\packages.ini" -encoding ascii