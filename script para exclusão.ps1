#caminho do registro
$profileListPath = "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList"

$accountSIDs = Get-ChildItem -Path $profileListPath | ForEach-Object { $_.PSChildName }

$domainToCheck = "seu_dominio" 

$lista_usuarios= @()
$usuarios_inativos= @()
$limite_dias_sem_modificacao = 180


#Verifica quais os usuários são de rede
foreach ($sid in $accountSIDs) {
    $account = New-Object System.Security.Principal.SecurityIdentifier($sid)
    $accountInfo = $account.Translate([System.Security.Principal.NTAccount])
    
    if ($accountInfo.Value -match '\\') {
        $domain, $username = $accountInfo.Value -split '\\'
        
        if ($domain -eq $domainToCheck) {
            Write-Host "$username pertence ao domínio $domain"
	    $lista_usuarios += $username
        }
    }
}

#verifica a ultima modificação em cada pasta de usuário de rede e registra na lista se for maior que 180 
foreach ($usuario in $lista_usuarios){

#caminho da pasta do usuario a ser verificado
    $directory = 'C:\Users\'+ $usuario

    $lastWrite = Get-Item $directory | ForEach-Object { $_.LastWriteTime }

    $days = ((Get-Date) - $lastWrite).Days

    Write-Output "A pasta $directory foi modificada pela ultima vez ha $days dias."
    if($days -gt $limite_dias_sem_modificacao){
        $usuarios_inativos = $usuario
    }

}


#exclui a pasta e o registro dos usuários inativos
foreach ($usuario_inativo in $usuarios_inativos){
	write-Output $usuario_inativo
	
    $directory = 'C:\Users\' + $usuario_inativo

    rm -PATH $directory -Force -Recurse

    $path = "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList"

    $usuario_procurado = $usuario_inativo

    $keys = Get-ChildItem -Path $path

    foreach ($key in $keys) {
        $profileImagePath = Get-ItemProperty -Path $key.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue

        if ($null -ne $profileImagePath -and $profileImagePath.ProfileImagePath -like "*$usuario_procurado*") {
            Remove-Item -Path $key.PSPath -Confirm:$false
        }
    }

}
