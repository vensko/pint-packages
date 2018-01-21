. .\common.ps1

$siteUrl = 'https://www.sordum.org/'
$baseUrl = 'https://www.sordum.org/8098/some-small-tools/';
$content = $client.DownloadString($baseUrl) -replace '<!--(.+?)-->',''
$matches = [regex]::Matches($content, 'href="([^"]+?)">(.+?)</a><span title="Number of downloads"> - \d+</span>')
$targetDir = $PSScriptRoot + '\..\packages\sordum.org'

ni $targetDir -type directory -ea 0 | out-null
del (join-path $targetDir '*.ini')

foreach ($match in $matches) {

	$id = $match.groups[2].value.ToLower().trim() -replace '[ -]+','-' -replace '[^\w-]+','' -replace 'sordum-',''
	$id = 'sordum-' + $id

	$url = $match.groups[1].value

	write-host $id.padright(35, ' ') ' ' -nonewline

	try {
		$appContent = $client.DownloadString($url);

		$link = [regex]::Matches($appContent, '(?:/downloads/|downloads\.php)\?([^"]+)') | select -first 1

		if (!$link) {
		    write-host 'LINK NOT FOUND' -f red
		    continue
		}

		$link = 'https://www.sordum.org/files/downloads.php?' + $link.groups[1].value

		try {
			$res = pint-make-request $link

			if ($res.ContentType.contains('text/html')) {
				$res.close()
				write-host 'HTML page' $link -f red
				continue
			}

			$link = $res.ResponseUri
			$res.close()

			write-host 'OK' -f green
		} catch {
			$msg = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { $_.Exception.Message }

			if ($msg.contains('timed out')) {
				write-host $msg $dist -f yellow
			} else {
				write-host $msg $dist -f red
				continue
			}
		}

		"dist = $link" | out-file (join-path $targetDir "$id.ini") -encoding ascii

	} catch {
		write-host $_.Exception.Message -f red
	}
}