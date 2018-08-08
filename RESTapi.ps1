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
Function Invoke-PRCommand {
param(
    [parameter(Mandatory=$true)]
    $RequestType,
    [parameter(Mandatory=$true)]
    $URL
)
    $Noresult = "There is something wrong with your query or the result."
    switch($RequestType)
    {
        "POST" {
            try{
                # Build command
                $Request = $URL.split("/")[3]
                
                if($Request -like "Create-*" -OR $Request -like "New-*" -OR $Request -like "Invoke-*"){
                    # Invoke command on the local computer
                    $Result = Invoke-Expression -Command $Request -ErrorAction Stop
                }
                else{
                    $Result = "Error: Not a Create or New or Invoke verb invoked"
                }
            }catch{
                # Build response
                $Result = ("Error: " + $_.Exception.Message)
            }
        }
        "GET" {
            try{
                # Build command
                write-host $URL
                $Request = $URL.split("/")[3]
                
                if($Request -like "Get-*"){
                    # Invoke command on the local computer
                    $Result = Invoke-Expression -Command $Request -ErrorAction Stop
                }
                else{
                    $Result = "Error: Not a Get verb invoked"
                }
            }catch{
                # Build response
                $Result = ("Error: " + $_.Exception.Message)
            }
        }
        "PUT" {
            try{
                # Build command
                $Request = $URL.split("/")[3]
                
                if($Request -like "Set-*"){
                    # Invoke command on the local computer
                    $Result = Invoke-Expression -Command $Request -ErrorAction Stop
                }
                else{
                    $Result = "Error: Not a Set verb invoked"
                }
            }catch{
                # Build response
                $Result = ("Error: " + $_.Exception.Message)
            }
        }
        "DELETE" {
            try{
                # Build command
                $Request = $URL.split("/")[3]
                
                if($Request -like "Remove-*"){
                    # Invoke command on the local computer
                    $Result = Invoke-Expression -Command $Request -ErrorAction Stop
                }
                else{
                    $Result = "Error: Not a Remove verb invoked"
                }
            }catch{
                # Build response
                $Result = ("Error: " + $_.Exception.Message)
            }
        }
    }
    return $Result
}

Function Start-PRListener {

    param(
        [parameter(Mandatory=$true)]
        $ListingPort
    )
    # Create a listener on port specified
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$ListingPort/") 
    $listener.Start()
    write-host "Listening on port $ListingPort..."
    write-host "API Access: http://localhost:$ListingPort/"
    write-host "To Stop API Listner: http://localhost:$ListingPort/kill"

    # Run until you send a GET request to /end
    while ($true) {

        $context = $listener.GetContext() 

        # Capture the details about the request
        $request = $context.Request

        # Setup a place to deliver a response
        $IPR_Response = $context.Response
    
        # Break from loop if GET request sent to /end
        if ($request.Url -match '/kill') { 
            break 
        }else{

            # Split request URL to get command and options
            $requestvars = ([String]$request.Url).split("/")
            if($requestvars.Count -le "3"){
                $IPR_Return = "Your request is not correct. Please look at the help of the API."
                $IPR_Response.ContentType = 'text/html'
                break
            }
            else{
                # Start the function Invoke-PRCommand with parameters
                $IPR_Return = Invoke-PRCommand -RequestType $context.Request.HttpMethod -URL ([String]$request.Url)
                $IPR_Return.gettype()
                if($IPR_Return -like "Error:*"){
                    $IPR_Response.ContentType = 'text/html'
                }else{
                    # Convert the returned data to JSON and set the HTTP content type to JSON
                    $IPR_Response.ContentType = 'application/json'
                }
            }
                # Convert the data to UTF8 bytes
                [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($IPR_Return)
                
                # Set length of response
                $IPR_Response.ContentLength64 = $buffer.length
                
                # Write response out and close
                $output = $IPR_Response.OutputStream
                $output.Write($buffer, 0, $buffer.length)
                $output.Close()
        }
    }
    
    #Terminate the listener
    $listener.Stop()
}

# Listenning port
Do {
    [int]$PRPort = Read-Host -Prompt "Which port should I use ?"
}Until($PRPort -ne $null)

Start-PRListener -ListingPort $PRPort