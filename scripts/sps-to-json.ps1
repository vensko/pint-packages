param (
    [string]$destFile
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

$baseDir = split-path $myinvocation.mycommand.path

$spsDir = join-path $baseDir 'sps'
$spsFile = join-path $baseDir 'sps.zip'
$spsJson = join-path $baseDir 'sps.json'

$client = new-object Net.WebClient
$client.Headers['User-Agent'] = 'PintBot/1.0 (+https://github.com/vensko/pint)'

[xml]$xml = $client.DownloadString('http://www.ugmfree.it/Services/SymenuSPS.asmx/GetSyMenuSuiteUrl')
$dbUrl = $xml.string.InnerText.trim()
$client.DownloadFile($dbUrl, $spsFile)

ni $spsDir -type directory -ea 0 | out-null
del (join-path $spsDir '*.sps')

Expand-Archive -LiteralPath $spsFile -DestinationPath $spsDir

php -r "error_reporting(0); echo json_encode(array_values(array_filter(array_map('simplexml_load_file', glob('sps/*.sps')))), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);" | out-file $spsJson -encoding ascii