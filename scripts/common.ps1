[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback = $null

$baseDir = (Resolve-Path .\).Path

$userAgent = 'PintBot/1.0 (+https://github.com/vensko/pint)'
$httpTimeout = 50000

$client = (new-object Net.WebClient)
$client.Headers['User-Agent'] = $userAgent

function unpack-zip($file, $dir)
{
	try {
		unzip $file $dir
	} catch {
		$shell = new-object -com Shell.Application
		$zip = $shell.NameSpace($file)
		$shell.Namespace($dir).copyhere($zip.items(), 20)
	}
}

function user-agent($url)
{
	if ($url -match '(dropbox\.com|osdn\.)') {
		return 'curl/7.55.0'
	}
	$userAgent
}

function pint-make-ftp-request([string]$url)
{
	$req = [Net.WebRequest]::Create($url)
	$req.Timeout = $httpTimeout
	$req.KeepAlive = $false
	$req.Method = [Net.WebRequestMethods+Ftp]::GetFileSize
	$req.GetResponse()
}

function pint-make-http-request([string]$url)
{
	try {
		$req = [Net.WebRequest]::Create($url)
		$req.Timeout = $httpTimeout
		$req.userAgent = user-agent $url
		$req.AllowAutoRedirect = $true
		$req.KeepAlive = $true
		$req.MaximumAutomaticRedirections = 5
		$req.Accept = '*/*'
		if (!$url.contains('sourceforge.net') -and !$url.contains('downloads.portableapps.com')) {
			$req.Referer = $url
		}
		$req.GetResponse()
	} catch [Management.Automation.MethodInvocationException] {
		$e = $_.Exception.InnerException
		$headers = $e.Response.Headers

		if ($headers) {
			[string]$location = if ($headers['location']) { $headers['location'] } else { $headers['Location'] }

			if ($location) {
				if ($location.StartsWith('ftp:')) {
					return pint-make-ftp-request $headers['Location']
				}
				return pint-make-http-request $location
			}
		}

		throw $e
	}
}

function pint-make-request([string]$url)
{
	if ($url.StartsWith('ftp:')) {
		$res = pint-make-ftp-request $url
	} else {
		$res = pint-make-http-request $url
	}

	return $res
}

function unzip($zipfile, $outdir)
{
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipfile)
    foreach ($entry in $archive.Entries)
    {
        $entryTargetFilePath = [System.IO.Path]::Combine($outdir, $entry.FullName)
        $entryDir = [System.IO.Path]::GetDirectoryName($entryTargetFilePath)
        
        #Ensure the directory of the archive entry exists
        if(!(Test-Path $entryDir )){
            New-Item -ItemType Directory -Path $entryDir | Out-Null 
        }
        
        #If the entry is not a directory entry, then extract entry
        if(!$entryTargetFilePath.EndsWith("\")){
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $entryTargetFilePath, $true);
        }
    }
}
