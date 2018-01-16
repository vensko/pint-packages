. .\common.ps1

$targetDir = $baseDir + '\..\packages\ugmfree.it'
$spsDir = join-path $baseDir 'sps'
$spsFile = join-path $baseDir 'sps.zip'

[xml]$xml = $client.DownloadString('http://www.ugmfree.it/Services/SymenuSPS.asmx/GetSyMenuSuiteUrl')

$dbUrl = $xml.string.InnerText.trim()

md $spsDir -ea 0 | out-null

md $targetDir -ea 0 | out-null
del (join-path $targetDir '*.ini')

if (!(test-path $spsFile -pathtype leaf)) {
	$client.DownloadFile($dbUrl, $spsFile)
}

del (join-path $spsDir '*.sps')
unpack-zip $spsFile $spsDir

$db = @{}

dir "$spsDir\*.sps" |% {
	[xml]$xml = [IO.File]::ReadAllText($_.fullname)
	$app = $xml.SPSSchema
	$name = $app.ProgramName

	write-host $name.padright(50, ' ') ' ' -nonewline

	$arch = if ($name.contains('x64')) { '64' } else { '' }

	$id = $name -replace ' \(.+?\)',''
	$id = $id.ToLower().trim() -replace '[ ]+','-' -replace ' portable','' -replace '[^\w-]+',''

	$dist = $app.DownloadUrl

	if ($dist.contains('portableapps.com') -or $dist.contains('sourceforge.net/portableapps')) {
		# PortableApps.com is covered by another script
		write-host 'PortableApps.com' -f red
		return
	}

	try {
		$req = [Net.WebRequest]::Create($dist)

		if ($dist.startswith('ftp:')) {
			$req.Method = [Net.WebRequestMethods+Ftp]::GetFileSize
		} else {
			$req.Timeout = 50000
			$req.UserAgent = $userAgent
			$req.AllowAutoRedirect = $true
			$req.MaximumAutomaticRedirections = 5
		}

		$res = $req.GetResponse()
		$res.close()

		if ($res.Headers['Content-Type'].contains('text/html')) {
			write-host 'HTML page' -f red
			return
		}

		write-host 'OK' -f green
	} catch {
		write-host $_.Exception.InnerException.Message -f red
		return
	}

	if (!$db[$id]) {
		$db[$id] = @{}
	}

	$db[$id]["dist$arch"] = $app.DownloadUrl

	if ($app.UpdateNoCopyFiles) {
		$db[$id]["keep$arch"] = (($app.UpdateNoCopyFiles -split ';') |% trim) -join ', '
	}

	if ($app.CleanUpdate -eq 'false') {
		$db[$id]["purge$arch"] = 'false'
	}

	if ($app.FirstInstallCreateFiles) {
		$db[$id]["create$arch"] = (($app.FirstInstallCreateFiles -split ';') |% trim) -join ', '
	}
}

$db.keys |% {
	$id = $_
	$ini = $db[$id].keys |% { "$_ = $($db[$id][$_])" }
	$ini | out-file (join-path $targetDir "$_.ini") -encoding ascii
}

del -r -force $spsDir