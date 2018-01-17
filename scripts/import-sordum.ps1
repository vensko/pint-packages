. .\common.ps1

$siteUrl = 'https://www.sordum.org/'
$baseUrl = 'https://www.sordum.org/8098/some-small-tools/';
$content = $client.DownloadString($baseUrl) -replace '<!--(.+?)-->',''
$matches = [regex]::Matches($content, 'href="([^"]+?)">(.+?)</a><span title="Number of downloads"> - \d+</span>')
$targetDir = $PSScriptRoot + '\..\packages\sordum.org'

md $targetDir -ea 0 | out-null
del (join-path $targetDir '*.ini')

foreach ($match in $matches) {

	$id = $match.groups[2].value.ToLower().trim() -replace '[ -]+','-' -replace '[^\w-]+','' -replace 'sordum-',''
	$id = 'sordum-' + $id

	$url = $match.groups[1].value

	write-host $id.padright(35, ' ') ' ' -nonewline

	try {
		$appContent = $client.DownloadString($url);

		$link = [regex]::Matches($appContent, '(?:/downloads/|downloads\.php)\?([^"]+)') | select -first 1
		$link = 'https://www.sordum.org/files/downloads.php?' + $link.groups[1].value

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

			$link = $res.ResponseUri
		} catch {
			write-host $_.Exception.InnerException.Message $link -f red
			continue
		}

		write-host 'OK' -f green

		"dist = $link" | out-file (join-path $targetDir "$id.ini") -append -encoding ascii

	} catch {
		write-host $_.Exception.Message -f red
	}
}