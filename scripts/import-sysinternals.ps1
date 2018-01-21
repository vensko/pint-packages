. .\common.ps1

$baseUrl = 'https://docs.microsoft.com/en-us/sysinternals/downloads/';
$content = $client.DownloadString($baseUrl) -replace '<!--(.+?)-->',''
$matches = [regex]::Matches($content, 'href="(.+?)" data-linktype="relative-path"')
$targetDir = $PSScriptRoot + '\..\packages\sysinternals'

ni $targetDir -type directory -ea 0 | out-null
del (join-path $targetDir '*.ini')

"dist = https://download.sysinternals.com/files/SysinternalsSuite.zip" | out-file (join-path $targetDir "sysinternals.ini") -encoding ascii

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
			$res = pint-make-request $link

			if (([string]$res.ContentType).contains('text/html')) {
				write-host 'HTML page' $link -f red
				continue
			}

			$res.close()

			write-host 'OK' -f green
		} catch {
			$msg = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { $_.Exception.Message }

			if ($msg.contains('timed out')) {
				write-host $msg $link -f yellow
			} else {
				write-host $msg $link -f red
				continue
			}
		}

		"dist = $link" | out-file (join-path $targetDir "$id.ini") -encoding ascii

	} catch {
		write-host $_.Exception.Message -f red
	}
}