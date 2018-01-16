[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$baseDir = (Resolve-Path .\).Path

$userAgent = 'PintBot/1.0 (+https://github.com/vensko/pint)'

$client = (new-object Net.WebClient)
$client.Headers['User-Agent'] = $userAgent

function unpack-zip($file, $dir)
{
	$shell = new-object -com Shell.Application
	$zip = $shell.NameSpace($file)
	$shell.Namespace($dir).copyhere($zip.items(), 20)
}