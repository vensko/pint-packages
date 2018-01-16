. .\common.ps1

$req = [Net.WebRequest]::Create('ftp://ftp.sac.sk/pub/sac/sound/mp3dc223.exe')
$req.Method = [System.Net.WebRequestMethods+FTP]::GetFileSize
$req.UseBinary = $true            
$req.KeepAlive = $false
$res = $req.GetResponse()
$res.close()

$res