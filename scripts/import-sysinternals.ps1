. .\common.ps1

$baseUrl = 'https://docs.microsoft.com/en-us/sysinternals/downloads/';
$content = $client.DownloadString($baseUrl) -replace '<!--(.+?)-->',''
$matches = [regex]::Matches($content, 'href="(.+?)" data-linktype="relative-path"')
$targetDir = $PSScriptRoot + '\..\packages\sysinternals'

md $targetDir -ea 0 | out-null
del (join-path $targetDir '*.ini')

"dist = https://download.sysinternals.com/files/SysinternalsSuite.zip" | out-file (join-path $targetDir "sysinternals.ini") -append -encoding ascii

foreach ($match in $matches) {

	$id = 'sysinternals-' + $match.groups[1].value
	$uri = $match.groups[1].value
	$url = $baseUrl + $uri

	write-host $id.padright(35, ' ') ' ' -nonewline

	try {
		$appContent = $client.DownloadString($url);

		[string]$link = [regex]::Matches($appContent, '[^"]+\.zip') | select -first 1

		if (!$link) {
		    write-host 'LINK NOT FOUND' -f red
		    continue
		}

		try {
			$req = [Net.WebRequest]::Create($link)
			$req.Timeout = 50000
			$req.UserAgent = $userAgent
			$req.Referer = $link
			$res = $req.GetResponse()
			$res.close()

			if ($res.Headers['Content-Type'].contains('text/html')) {
				write-host 'HTML page' $link -f red
				continue
			}
		} catch {
			write-host $_.Exception.InnerException.Message $link -f red
			continue
		}

		write-host 'OK' -f green

		"dist = $link" | out-file (join-path $targetDir "$id.ini") -append -encoding ascii

	} catch {
		write-host $_.Exception.InnerException.Message -f red
	}
}