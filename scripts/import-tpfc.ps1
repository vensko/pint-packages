. .\common.ps1

$targetDir = $PSScriptRoot + '\tpfc'
ni $targetDir -type directory -ea 0 | out-null

$siteUrl = 'https://www.portablefreeware.com'
$categoriesUrl = 'https://www.portablefreeware.com/all.php'

$content = $client.DownloadString($categoriesUrl) -replace '<!--(.+?)-->',''
$categoryIds = [regex]::Matches($content, 'index.php\?sc=(\d+)') |% { $_.groups[1].value } | get-unique

$apps = @{}

$categoryIds |% {
	# No paging needed until at least one category grows to 100 items

	$url = $siteUrl + '/index.php?sc=' + $_ + '&s=100'

	write-host $url
	$content = $client.DownloadString($url)

	$matches = [regex]::Matches($content, 'index.php\?id=(\d+)" class="appName">(.+?)</a>')

	$matches |% {
		$tpfcId = $_.groups[1].value
		$name = $_.groups[2].value
		$appid = name-to-id $name

		$targetFile = join-path $targetDir "$appid.ini"

		if (test-path $targetFile -type leaf) {
			write-host "Skipping $appid"
			return
		}

		$dist = if ($content.contains('download.php?dd=' + $tpfcId + '"')) { $siteUrl + '/download.php?dd=' + $tpfcId } else { '' }
		$dist64 = if ($content.contains('download.php?dd64=' + $tpfcId + '"')) { $siteUrl + '/download.php?dd64=' + $tpfcId } else { '' }

		if (!$dist -and !$dist64) {
			write-host "No download links in $appid"
			return
		}

		$app = @{}

		if ($dist) {
			try {
				$res = pint-make-request $dist

				if (!$res.ContentType.contains('text/html')) {
					write-host $res.ResponseUri -f green
					$app.dist = $res.ResponseUri
				} else {
					write-host 'HTML page' $res.ResponseUri -f red
				}

				$res.close()
			} catch {
				write-host $_ $dist -f red
			}
		}

		if ($dist64) {
			try {
				write-host $dist64
				$res = pint-make-request $dist64

				if (!$res.ContentType.contains('text/html')) {
					write-host $res.ResponseUri -f green
					$app.dist64 = $res.ResponseUri
				} else {
					write-host 'HTML page' $res.ResponseUri -f red
				}

				$res.close()
			} catch {
				write-host $_
			}
		}

		if (!$app.dist -and !$app.dist64) {
			return
		}

		$ini = ''
		$ini += "name = $name`r`n"

		if ($app.dist) {
			$ini += "dist = $($app.dist)`r`n"
		}

		if ($app.dist64) {
			$ini += "dist64 = $($app.dist64)`r`n"
		}

		$ini += "tpfc = $tpfcId"

		$ini | out-file $targetFile -encoding ascii
	}
}
