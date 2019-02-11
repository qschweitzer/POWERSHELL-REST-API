<#

.SYNOPSIS
  Start an API with custom actions and a JSON result returned.
.DESCRIPTION
  Configure custom actions (GET,POST,PUT,DELETE) with the TPL_POSHAPI.ps1 in the Modules directory.
  Start your API with custom or default port and custom or default Modules directory.
  Stop API by using /kill by default or with your custom StopAction in API url. You could do it in a browser like http://localhost:8000/kill
.PARAMETER APIPort
  Custom listenning API's port. This is the port on which API will listenning. Example: http://localhost:8000
.PARAMETER ModulesPath
  Define a custom directory where your modules are.
.PARAMETER StopAction
  Define a custom stop action to kill API process.
.NOTES
  Version:        1.2
  Author:         Quentin Schweitzer
  Creation Date:  2019-02-09
  Purpose/Change: Major update with new actions management system.
  
.EXAMPLE
  Invoke-PRCommand -APIPort 8000 -ModulesPath "C:\POSH_API\Modules"

#>

Function Start-PRListener {
    param(
        [parameter(Mandatory = $true)]
        $ScriptBlock,
        $ListeningPort,
        $StopAction
    )
    # Create a listener on port specified
    $URL = "http://localhost:$ListeningPort/"
    # Create HttpListener Object
    write-host "Listening on port $ListeningPort..."
    $SimpleServer = New-Object Net.HttpListener
    write-host "To Stop API Listner: $($URL)$($StopAction)"

    # Tell the HttpListener what port to listen on
    #    As long as we use localhost we don't need admin rights. To listen on externally accessible IP addresses we will need admin rights
    write-host "API Access: $URL"
    $SimpleServer.Prefixes.Add($URL)

    # Start up the server
    $SimpleServer.Start()

    while($SimpleServer.IsListening)
    {
        Write-Host "Listening for request"
        # Tell the server to wait for a request to come in on that port.
        $Context = $SimpleServer.GetContext()

        #Once a request has been captured the details of the request and the template for the response are created in our $context variable
        Write-Verbose "Context has been captured"

        # $Context.Request contains details about the request
        # $Context.Response is basically a template of what can be sent back to the browser
        # $Context.User contains information about the user who sent the request. This is useful in situations where authentication is necessary


        # Sometimes the browser will request the favicon.ico which we don't care about. We just drop that request and go to the next one.
        if($Context.Request.Url.LocalPath -eq "/favicon.ico")
        {
            do
            {

                    $Context.Response.Close()
                    $Context = $SimpleServer.GetContext()

            }while($Context.Request.Url.LocalPath -eq "/favicon.ico")
        }

        [string]$URLActive = $Context.Request.Url

        # Creating a friendly way to shutdown the server
        if($Context.Request.Url.LocalPath -eq "/$($StopAction)")
        {

                    $Context.Response.Close()
                    $SimpleServer.Stop()
                    break

        }
        elseif($URLActive.split("/").count -le 3){
            $result = "Error: No parameters after base URL. Please specify which computer you want to connect to and what action have to be done."
        }
        else{
            $result = try {
                .$ScriptBlock
            } catch {
                $_.Exception.Message
            }
        }
    
        #$Context.request

        if($result) {
            if($result -is [string]){
                
                Write-Host "A [string] object was returned. Writing it directly to the response stream."

            } else {

                Write-Host "Converting PS Objects into JSON objects"
                $result = $result | ConvertTo-Json
                
            }
        }else{
            $result = "No result found"
        }
        
        Write-Host "Sending response of Result"

        # We convert the result to bytes from ASCII encoded text
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($Result)

        # We need to let the browser know how many bytes we are going to be sending
        $context.Response.ContentLength64 = $buffer.Length

        # We send the response back to the browser
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)

        # We close the response to let the browser know we are done sending the response
        $Context.Response.Close()

        #$Context.Response
    }
}
Function Invoke-PRCommand {
    param(
        # Parameter help description
        [Parameter (Mandatory=$False)]
        [String]
        $APIPort = 8000,
        $ModulesPath = "$(Get-Location)\Modules",
        $StopAction = "kill"
    )

    Start-PRListener -ListeningPort $APIPort -StopAction $StopAction -ScriptBlock {

        [string]$URL = ($Context.Request.URL)
        $split=$URL.split("/")
        [string]$Verb = $split[3]
        $Params = ""
        # URL splitted, index start after the Verb
        for ($index=4; $index -le $split.count; $index++) { $Params += $split[$index] + " " }

        $ActionVerbs = @()

        #Load Modules
        Get-ChildItem -Path $ModulesPath -Filter "*_*.ps1" -File | ForEach-Object {
            $_Verb = New-Object -TypeName psobject
            $_Verb | Add-Member -MemberType NoteProperty -Name "Type" -Value ($_.Name).Split("_")[0]
            $_Verb | Add-Member -MemberType NoteProperty -Name "Verb" -Value ($_.Name).Split("_")[1].replace(".ps1","")
            $ActionVerbs += $_Verb
            Import-Module $_.FullName -force
        }

        # Get method of last request
        $Method = $Context.Request.HttpMethod
        try {
            # Find which function the calling URL wants and invoke the command
            if (($ActionVerbs | Where-Object {$_.Type -eq "$Method"}).Verb -contains $Verb){
                $func = ($Method+"_"+$verb)
                $Result = Invoke-Expression ($func + ' ' + $params)
            }
            else {
                $Result = "Error: Not a knew action verb"
            }
        }
        catch {
            # Build error reply
            $Result = ("Error: " + $_.Exception.Message)
        }
        
        return $Result
    }
}