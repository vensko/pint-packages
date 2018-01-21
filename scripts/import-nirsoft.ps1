. .\common.ps1

$siteUrl = 'https://www.nirsoft.net'
$baseUrl = $siteUrl + '/utils/';
$content = $client.DownloadString($baseUrl) -replace '<!--(.+?)-->',''
$matches = [regex]::Matches($content, '<a class="filetitle" href="(.+?)"')
$targetDir = $PSScriptRoot + '\..\packages\nirsoft.net'

ni $targetDir -type directory -ea 0 | out-null
del (join-path $targetDir '*.ini')

foreach ($match in $matches) {

	$id = 'nirsoft-' + [IO.Path]::GetFileNameWithoutExtension($match.groups[1].value)
	$id = $id.replace('_', '-')

	$uri = $match.groups[1].value
	$url = $baseUrl + $uri

	write-host $id.padright(35, ' ') ' ' -nonewline

	try {
		$appContent = $client.DownloadString($url);

		$link = [regex]::Matches($appContent, 'class="downloadline" href="(((?!x64)[^"])+\.zip)"') | select -first 1
		$link64 = [regex]::Matches($appContent, 'class="downloadline" href="([^"]+-x64\.zip)"') | select -first 1

		if (!$link -and !$link64) {
		    write-host 'LINK NOT FOUND' -f red
		    continue
		}

		if ($link) {
			$link = $link.groups[1].value
			$link = if ($link[0] -eq '/') { $siteUrl + $link } else { $url + '/../' + $link } # relarive paths hack

			try {
				$res = pint-make-request $link

				if ($res.ContentType.contains('text/html')) {
					write-host 'HTML page' $link -f red
					$link = ''
				} else {
					$link = $res.ResponseUri
				}
			} catch {
				write-host $_.Exception.InnerException.Message $link -f red
				$link = ''
			} finally {
				if ($res) { $res.close() }
			}
		}

		if ($link64) {
			$link64 = $link64.groups[1].value
			$link64 = if ($link64[0] -eq '/') { $siteUrl + $link64 } else { $baseUrl + $link64 }

			try {
				$res = pint-make-request $link64

				if ($res.ContentType.contains('text/html')) {
					write-host 'HTML page' $link64 -f red
					$link64 = ''
				} else {
					$link64 = $res.ResponseUri
				}
			} catch {
				write-host $_.Exception.InnerException.Message $link64 -f red
				$link64 = ''
			} finally {
				if ($res) { $res.close() }
			}
		}

		if (!$link -and !$link64) {
			continue
		}

		write-host 'OK' -f green

		$ini = @()
		if ($link) { $ini += "dist = $link" }
		if ($link64) { $ini += "dist64 = $link64" }
		$ini += "keep = *.cfg"

		$ini -join "`r`n" | out-file (join-path $targetDir "$id.ini") -append -encoding ascii

	} catch {
		write-host $_.Exception.InnerException.Message -f red
	}
}