. .\common.ps1

$pahost = 'https://portableapps.com/';
$url = $pahost + 'apps'
$content = $client.DownloadString($url) -replace '<!--(.+?)-->',''
$matches = [regex]::Matches($content, 'apps/\w+/([\w_-]+?)[_-]portable', 'IgnoreCase')
$targetDir = $PSScriptRoot + '\..\portableapps.com'

md $targetDir -ea 0 | out-null
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

	try {
		$appContent = $client.DownloadString($url);

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

		$req = [Net.WebRequest]::Create($link)
		$req.Timeout = 50000
		$req.UserAgent = $userAgent
		$res = $req.GetResponse()
		$res.close()

		if ($res.Headers['Content-Type'].contains('text/html')) {
			write-host 'HTML page' -f red
			continue
		}

		write-host 'OK' -f green

		$ini = @"
dist = $url
link = .paf.exe
keep = data
"@

		$ini | out-file (join-path $targetDir "$id.ini") -append -encoding ascii

		$done += @($id)

	} catch {
		write-host $_.Exception.InnerException.Message -f red
	}
}