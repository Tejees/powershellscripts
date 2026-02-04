Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsLogOnTask.txt -Append
Write-Host "Logon-task-started" 

# Clone lab files
cd C:\LabFiles
git clone --branch prod "https://github.com/CloudLabsAI-Azure/pg-sk-agents-lab.git" | Tee-Object -Variable gitCloneOutput

$commonscriptpath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.*\Downloads\0\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

# Install VS Code extensions
choco install vscode-code-runner
choco install vscode-csharp

code --install-extension ms-ossdata.vscode-pgsql --force
code --install-extension ms-python.debugpy --force
code --install-extension ms-python.python --force
code --install-extension ms-python.vscode-pylance --force
code --install-extension ms-toolsai.jupyter --force
code --install-extension ms-toolsai.jupyter-keymap --force
code --install-extension ms-toolsai.jupyter-renderers --force
code --install-extension ms-toolsai.vscode-jupyter-cell-tags --force
code --install-extension ms-toolsai.vscode-jupyter-slideshow --force

# Install Python packages
pip install python-dotenv
pip install python-dotenv semantic-kernel
pip install streamlit
pip install fastapi uvicorn
pip install azure-search-documents
pip install --upgrade pip
pip install psycopg psycopg-binary psycopg-pool pydantic openai semantic-kernel nest_asyncio ipykernel requests
pip install notebook
pip install --upgrade semantic-kernel

# Extract file
New-Item -ItemType directory -Path C:\Allfiles
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/Azure-AI-Foundry-Agents-GitHub/Day-1/contoso-rag.zip","C:\Allfiles\contoso-rag.zip")
#unziping folder
function Expand-ZIPFile($file, $destination)
{
$shell = new-object -com shell.application
$zip = $shell.NameSpace($file)
foreach($item in $zip.items())
{
$shell.Namespace($destination).copyhere($item)
}
}
Expand-ZIPFile -File "C:\Allfiles\contoso-rag.zip" -Destination "C:\AllFiles\"
Function DisableServerMgrNetworkPopup
{
    cd HKLM:\
    New-Item -Path HKLM:\System\CurrentControlSet\Control\Network -Name NewNetworkWindowOff -Force 

    Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
}
DisableServerMgrNetworkPopup

# Download and install PostgreSQL silently
$pgInstallerUrl = "https://get.enterprisedb.com/postgresql/postgresql-16.3-1-windows-x64.exe"
$installerPath = "$env:TEMP\postgresql-installer.exe"
Invoke-WebRequest -Uri $pgInstallerUrl -OutFile $installerPath -TimeoutSec 300

Start-Process -FilePath $installerPath -ArgumentList "--mode unattended --unattendedmodeui none --superpassword postgres" -Wait

# Define bin path
$pgBinPath = "C:\Program Files\PostgreSQL\16\bin"
Start-Sleep -Seconds 5

if (Test-Path "$pgBinPath\psql.exe") {
    $existingPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    if ($existingPath -notlike "*$pgBinPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$existingPath;$pgBinPath", [EnvironmentVariableTarget]::Machine)
        Write-Host "PostgreSQL bin path added to system PATH."
    } else {
        Write-Host "PostgreSQL bin path already present in system PATH."
    }
    & "$pgBinPath\psql.exe" --version
} else {
    Write-Host "PostgreSQL installation failed or psql.exe not found."
}
Remove-Item $installerPath -Force


#$ValidStatus="Succeeded"
$ValidMessage="Environment is validated and the deployment is successful"
SetDeploymentStatus $ValidStatus $ValidMessage

#Start the cloudlabs agent service 
CloudlabsManualAgent Start
#
Unregister-ScheduledTask -TaskName "logontask" -Confirm:$false

Stop-Transcript
