[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$baseDir = (Resolve-Path .\).Path

$userAgent = 'PintBot/1.0 (+https://github.com/vensko/pint)'
$httpTimeout = 50000

$client = (new-object Net.WebClient)
$client.Headers['User-Agent'] = $userAgent

function unpack-zip($file, $dir)
{
	$shell = new-object -com Shell.Application
	$zip = $shell.NameSpace($file)
	$shell.Namespace($dir).copyhere($zip.items(), 20)
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
		$req.KeepAlive = $false
		$req.MaximumAutomaticRedirections = 5
		$req.Accept = '*/*'
		if (!$url.contains('sourceforge.net')) {
			$req.Referer = $url
		}
		$req.GetResponse()
	} catch [Management.Automation.MethodInvocationException] {
		$e = $_.Exception.InnerException
		$headers = $e.Response.Headers

		if ($headers -and ([string]$headers['Location']).StartsWith('ftp:')) {
			return pint-make-ftp-request $headers['Location']
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