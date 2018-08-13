<#

CODES STATUS

200 OK Tout s'est bien passé

201 Created La création de la ressource s'est bien passée (il n’est pas rare que les attributs de la nouvelle ressource soient aussi renvoyées dans la réponse. Dans ce cas, l’URL de cette ressource nouvellement créée est ajouté via un header Location )

204 No content Même principe que pour la 201, sauf que cette fois-ci, le contenu de la ressource nouvellement créée ou modifiée n'est pas renvoyée en réponse

304 Not modified Le contenu n'a pas été modifié depuis la dernière fois qu'elle a été mise en cache

400 Bad request La demande n'a pas pu être traitée correctement

401 Unauthorized L'authentification a échoué

403 Forbidden L'accès à cette ressource n'est pas autorisé

404 Not found La ressource n'existe pas

405 Method not allowed La méthode HTTP utilisée n'est pas traitable par l'API

406 Not acceptable L’API est dans l’incapacité de fournir le format demandé par les en têtes Accept. Par exemple, le client demande un format (XML par exemple) et l'API n'est pas prévue pour générer du XML

500 Server error Le serveur a rencontré un problème.

#>
Function Start-PRListener {
    param(
        [parameter(Mandatory = $true)]
        $ScriptBlock,
        $ListeningPort
    )
    # Create a listener on port specified
    $URL = "http://localhost:$ListeningPort/"
    # Create HttpListener Object
    write-host "Listening on port $ListeningPort..."
    $SimpleServer = New-Object Net.HttpListener
    write-host "To Stop API Listner: $($URL)kill"

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
        if($Context.Request.Url.LocalPath -eq "/kill")
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
    
        $Context.request

        if($result -ne $null) {
            if($result -is [string]){
                
                Write-Verbose "A [string] object was returned. Writing it directly to the response stream."

            } else {

                Write-Verbose "Converting PS Objects into JSON objects"
                $result = $result | ConvertTo-Json
                
            }
        }

        Write-Host "Sending response of $Result"

        # We convert the result to bytes from ASCII encoded text
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($Result)

        # We need to let the browser know how many bytes we are going to be sending
        $context.Response.ContentLength64 = $buffer.Length

        # We send the response back to the browser
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)

        # We close the response to let the browser know we are done sending the response
        $Context.Response.Close()

        $Context.Response
    }
}
Function Invoke-PRCommand {

    $Noresult = "There is something wrong with your query or the result."
    # Listenning port
    Do {
        [int]$PRPort = Read-Host -Prompt "Which port should I use ?"
    }Until($PRPort -ne $null)

    Start-PRListener -ListeningPort $PRPort -ScriptBlock {

        [string]$URL = ($Context.Request.URL)

        switch ($Context.Request.HttpMethod) {
            "POST" {
                try {
                    # Build command
                    #write-host ("URLfull= " + $URL)
                    [string]$Verb = $URL.split("/")[3]
                    
                    if ($Verb -eq "CREATE" -OR $Verb -eq "NEW" -OR $Verb -eq "INVOKE") {
                        #write-host ("Verb= " + $Verb)
                        [string]$What2Do = $URL.split("/")[4]
                        #write-host ("What2Do= " + $What2Do)
                        [string]$Arguments = ""
                    
                        if ($URL.split("/").count -gt 5) {
                            $Arguments = ($URL.split("/")[5]).replace("&","-").replace("="," ")
                        }
                        
                        # Invoke command on the local computer
                        [string]$Command = "$Verb-$What2Do $Arguments"
                        Write-Host ("Command= " + $command )
                        $Result = Invoke-Expression $Command -ErrorAction Stop
                    }
                    else {
                        $Result = "Error: Not a Create or New or Invoke verb invoked"
                    }
                }
                catch {
                    # Build response
                    $Result = ("Error: " + $_.Exception.Message)
                }
            }
            "GET" {
                try {
                    # Build command
                    #write-host ("URLfull= " + $URL)
                    [string]$Verb = $URL.split("/")[3]

                    if ($Verb -eq "GET"){
                        #write-host ("Verb= " + $Verb)
                        [string]$What2Do = $URL.split("/")[4]
                        #write-host ("What2Do= " + $What2Do)
                        [string]$Arguments = ""
                    
                        if ($URL.split("/").count -gt 5) {
                            $Arguments = ($URL.split("/")[5]).replace("&","-").replace("="," ")
                        }
                        
                        # Invoke command on the local computer
                        [string]$Command = "$Verb-$What2Do $Arguments"
                        Write-Host ("Command= " + $command )
                        $Result = Invoke-Expression $Command -ErrorAction Stop
                    }
                    else {
                        $Result = "Error: Not a Create or New or Invoke verb invoked"
                    }
                }
                catch {
                    # Build response
                    $Result = ("Error: " + $_.Exception.Message + " " + $error)
                }
            }
            "PUT" {
                try {
                    # Build command
                    #write-host ("URLfull= " + $URL)
                    [string]$Verb = $URL.split("/")[3]
                    
                    if ($Verb -eq "SET") {
                        #write-host ("Verb= " + $Verb)
                        [string]$What2Do = $URL.split("/")[4]
                        #write-host ("What2Do= " + $What2Do)
                        [string]$Arguments = ""
                    
                        if ($URL.split("/").count -gt 5) {
                            $Arguments = ($URL.split("/")[5]).replace("&","-").replace("="," ")
                        }
                        
                        # Invoke command on the local computer
                        [string]$Command = "$Verb-$What2Do $Arguments"
                        Write-Host ("Command= " + $command )
                        $Result = Invoke-Expression $Command -ErrorAction Stop
                    }
                    else {
                        $Result = "Error: Not a Create or New or Invoke verb invoked"
                    }
                }
                catch {
                    # Build response
                    $Result = ("Error: " + $_.Exception.Message)
                }
            }
            "DELETE" {
                try {
                    # Build command
                    #write-host ("URLfull= " + $URL)
                    [string]$Verb = $URL.split("/")[3]
                    
                    if ($Verb -eq "REMOVE") {
                        #write-host ("Verb= " + $Verb)
                        [string]$What2Do = $URL.split("/")[4]
                        #write-host ("What2Do= " + $What2Do)
                        [string]$Arguments = ""
                    
                        if ($URL.split("/").count -gt 5) {
                            $Arguments = ($URL.split("/")[5]).replace("&","-").replace("="," ")
                        }
                        
                        # Invoke command on the local computer
                        [string]$Command = "$Verb-$What2Do $Arguments"
                        Write-Host ("Command= " + $command )
                        $Result = Invoke-Expression $Command -ErrorAction Stop
                    }
                    else {
                        $Result = "Error: Not a Create or New or Invoke verb invoked"
                    }
                }
                catch {
                    # Build response
                    $Result = ("Error: " + $_.Exception.Message)
                }
            }
        }
        return $Result
    }
}

Invoke-PRCommand