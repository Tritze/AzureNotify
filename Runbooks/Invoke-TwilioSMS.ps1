<#
    .SYNOPSIS
    This script triggers a notification via a azure automation webhook.

    .DESCRIPTION


    .NOTES


    .LINK 
    https://github.com/Tritze/AzureNotify

#>

param(
    [object]$WebhookData
)

# Check if runbook was started by webhook
if ($WebhookData -ne $null){

    # Collect properties of WebhookData
    $WebhookHeaders =   $WebhookData.RequestHeader
    $WebhookBody    =   $WebhookData.RequestBody

    $WebhookBodyJson = ConvertFrom-Json -InputObject $WebhookBody

    $SMSMessage = $WebhookBodyJson.Message
    $RecieverPhoneNumber = $WebhookBodyJson.RecieverNumber
    if ($WebhookBodyJson.WebhookPassword -eq (Get-AutomationVariable -Name 'WebhookPassword') ) {
        $TwilioAccountSid = Get-AutomationVariable -Name 'TwilioAccountSid'
        $TwilioAuthToken = Get-AutomationVariable -Name 'TwilioAuthToken'
        $TwilioPhoneNumber = Get-AutomationVariable -Name 'TwilioPhoneNumber'

        # Build URI with Account Sid
        $URI = "https://api.twilio.com/2010-04-01/Accounts/$TwilioAccountSid/SMS/Messages.json"
        # Build data to post
        $MessageData = "From=$TwilioPhoneNumber&To=$RecieverPhoneNumber&Body=$SMSMessage"
        # Build authorization for header
        $SecureAuthToken = ConvertTo-SecureString $TwilioAuthToken -AsPlainText -Force
        $AuthCredentials = New-Object System.Management.Automation.PSCredential($TwilioAccountSid,$SecureAuthToken) 

        # Send mrequest
        $msg = Invoke-RestMethod -Uri $URI -Body $MessageData -Credential $AuthCredentials -Method "POST" -ContentType "application/x-www-form-urlencoded" 
    }
    else {
        Write-Error "Wrong password provided!"
    }
}
else{
    Write-Output "Do not trigger this manual, only by webhook ;-)"
}