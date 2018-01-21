. .\common.ps1

$pahost = 'https://portableapps.com/';
$url = $pahost + 'apps'
$content = $client.DownloadString($url) -replace "`n",'' -replace '<!--(.+?)-->',''
$matches = [regex]::Matches($content, 'apps/\w+/([\w_-]+?)[_-]portable', 'IgnoreCase')
$targetDir = $PSScriptRoot + '\..\packages\portableapps.com'

ni $targetDir -type directory -ea 0 | out-null
del (join-path $targetDir '*.ini')

$done = @()

foreach ($match in $matches) {

	$id = $match.groups[1].value.replace('_', '-') + '-pa'
	$uri = $match.groups[0].value
	$url = $pahost + $uri

	if ($done -contains $id) {
		continue
	}

	write-host $uri.padright(50, ' ') ' ' -nonewline

	$appContent = $client.DownloadString($url) -replace "`n",'' -replace '<!--(.+?)-->',''

	if ($appContent -match '[\d\.]+\+[\d\.]+\w+ download' -or $appContent -like '*online installer*') {
	    write-host 'ONLINE INSTALLER' -f red
	    continue
	}

	$link = [regex]::Matches($appContent, '[^"]+?\.paf\.exe') |% { $_.groups[0].value } | select -first 1

	if (!$link) {
	    write-host 'LINK NOT FOUND' -f red
	    continue
	}

	if ($link.startswith('/')) {
		$link = $pahost.trim('/') + $link
	}

	try {
		$res = pint-make-request $link
	} catch {
		$msg = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { $_.Exception.Message }

		if ($msg.contains('timed out')) {
			write-host $msg $link -f yellow
		} else {
			write-host $msg $link -f red
			continue
		}
	}

	if (([string]$res.ContentType).contains('text/html')) {
		$res.close()
		write-host 'HTML page' $link -f red
		continue
	}

	if (([string]$res.ResponseUri).contains('./')) {
		$res.close()
		write-host 'LINK CONTAINS ./ (POWERSHELL BUG)' -f red
		continue
	}

	$res.close()

	write-host 'OK' -f green

	$ini = @()
	$ini += "dist = $url"
	$ini += "link = .paf.exe"
	$ini += "keep = data"
	$ini = $ini -join "`r`n"

	$ini | out-file (join-path $targetDir "$id.ini") -encoding ascii

	$done += @($id)
}