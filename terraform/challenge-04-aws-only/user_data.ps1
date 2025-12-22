<powershell>
# PowerShell script to configure Windows Server as Domain Controller
# This script runs during EC2 instance initialization

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Create log file
$LogFile = "C:\Windows\Temp\dc_setup.log"
Start-Transcript -Path $LogFile -Append

Write-Host "Starting Domain Controller setup for ${domain_name}" -ForegroundColor Green

try {
    # Install AD DS role and management tools
    Write-Host "Installing Active Directory Domain Services role..." -ForegroundColor Yellow
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Verbose

    # Install DNS Server role
    Write-Host "Installing DNS Server role..." -ForegroundColor Yellow
    Install-WindowsFeature -Name DNS -IncludeManagementTools -Verbose

    # Convert secure string password
    $SafeModePassword = ConvertTo-SecureString "${dc_admin_password}" -AsPlainText -Force

    # Promote server to Domain Controller
    Write-Host "Promoting server to Domain Controller for domain ${domain_name}..." -ForegroundColor Yellow
    Install-ADDSForest `
        -DomainName "${domain_name}" `
        -DomainNetbiosName "MEDICLOUDX" `
        -SafeModeAdministratorPassword $SafeModePassword `
        -InstallDns:$true `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true `
        -Verbose

    Write-Host "Domain Controller promotion initiated. Server will reboot automatically." -ForegroundColor Green

} catch {
    Write-Error "Error during initial setup: $_"
    $_ | Out-File -FilePath "C:\Windows\Temp\dc_setup_error.log" -Append
}

# Schedule post-reboot configuration
$PostRebootScript = @"
# Post-reboot configuration script
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
Start-Transcript -Path "C:\Windows\Temp\dc_post_reboot.log" -Append

Write-Host "Starting post-reboot configuration..." -ForegroundColor Green

try {
    # Wait for AD services to be ready
    Write-Host "Waiting for Active Directory services to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60

    # Import AD module
    Import-Module ActiveDirectory -Force

    # Create service account with weak password (intentional for CTF)
    Write-Host "Creating service account svc-flag..." -ForegroundColor Yellow
    `$UserPassword = ConvertTo-SecureString "${svc_flag_password}" -AsPlainText -Force
    
    New-ADUser -Name "svc-flag" `
               -UserPrincipalName "svc-flag@${domain_name}" `
               -SamAccountName "svc-flag" `
               -DisplayName "Service Flag Account" `
               -Description "Service account for CTF Challenge ${challenge_name}" `
               -AccountPassword `$UserPassword `
               -Enabled `$true `
               -PasswordNeverExpires `$true `
               -CannotChangePassword `$true `
               -Verbose

    # Add user to Domain Users (default)
    Write-Host "Service account svc-flag created successfully" -ForegroundColor Green

    # Create additional users for realism
    Write-Host "Creating additional domain users..." -ForegroundColor Yellow
    
    `$Users = @(
        @{Name="admin.user"; Password="AdminPass2025!"; Description="Domain Administrator"},
        @{Name="john.doe"; Password="Welcome123!"; Description="Regular User"},
        @{Name="jane.smith"; Password="Password2025!"; Description="Regular User"}
    )

    foreach (`$User in `$Users) {
        `$UserPass = ConvertTo-SecureString `$User.Password -AsPlainText -Force
        New-ADUser -Name `$User.Name `
                   -UserPrincipalName "`$(`$User.Name)@${domain_name}" `
                   -SamAccountName `$User.Name `
                   -DisplayName `$User.Name `
                   -Description `$User.Description `
                   -AccountPassword `$UserPass `
                   -Enabled `$true `
                   -PasswordNeverExpires `$true `
                   -Verbose
    }

    # Add admin.user to Domain Admins
    Add-ADGroupMember -Identity "Domain Admins" -Members "admin.user" -Verbose

    # Configure DNS forwarders
    Write-Host "Configuring DNS forwarders..." -ForegroundColor Yellow
    Add-DnsServerForwarder -IPAddress "8.8.8.8", "8.8.4.4" -Verbose

    # Enable RDP
    Write-Host "Enabling Remote Desktop..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    # Create completion marker
    Write-Host "Domain Controller setup completed successfully!" -ForegroundColor Green
    "DC Setup Completed: `$(Get-Date)" | Out-File -FilePath "C:\Windows\Temp\dc_setup_complete.txt"

} catch {
    Write-Error "Error during post-reboot configuration: `$_"
    `$_ | Out-File -FilePath "C:\Windows\Temp\dc_post_reboot_error.log" -Append
}

Stop-Transcript
"@

# Save post-reboot script
$PostRebootScript | Out-File -FilePath "C:\Windows\Temp\post_reboot_config.ps1" -Encoding UTF8

# Create scheduled task for post-reboot execution
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Windows\Temp\post_reboot_config.ps1"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "DCPostRebootConfig" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force

Write-Host "Scheduled task created for post-reboot configuration" -ForegroundColor Green

Stop-Transcript
</powershell>"
