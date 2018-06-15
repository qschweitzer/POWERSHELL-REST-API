Function Invoke-PRCommand {
param(
    [parameter(Mandatory=$true)]
    $RequestType,
    [parameter(Mandatory=$true)]
    $Request,
    $Computer
)
    $Noresult = "There is something wrong with your query or the result."
    switch($RequestType)
    {
        "get" {
            try{
                # Build command
                $Request = $Request.split("=")[1]
                if($computer){
                    # Invoke command on the target computer
                    $Result = Invoke-Command -ComputerName $Computer -ScriptBlock {$Request} -ErrorAction Stop
                }else{
                    # Invoke command on the local computer
                    $Result = Invoke-Expression -Command $Request -ErrorAction Stop
                }
            }catch{
                # Build response
                $Result = ("Error: " + $_.Exception.Message)
            }
        }
        "wmi" {
            try{
                # Build command
                $Request = $Request.split("=")[1]
                if($computer){
                    # Invoke command on the target computer
                    $Result = Get-WMIObject $Request -Computer $Computer -ErrorAction Stop | ConvertTo-Json
                }else{
                    # Invoke command on the local computer
                    $Result = Get-WMIObject $Request -ErrorAction Stop | ConvertTo-Json
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
        $ListingPort,
        [parameter(Mandatory=$true)]
        $TokenList
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
                # If the request contains a token from the internal token list
                if($TokenList.Token -contains ($requestvars[3].split("="))[1]){
                    if($requestvars[4] -like "computer=*"){
                        $computer = $requestvars[4].split("=")[1]
                        $requesttype = $requestvars[5]
                        $iurl = 6
                    }else{
                        $requesttype = $requestvars[4]
                        $iurl = 5
                    }

                    # If a request is sent to http://:$ListingPort/
                    # The switch may help to select the action type requested
                    Switch($requesttype){
                        
                        "wmi" {
                    
                            # Start the function Invoke-PRCommand with parameters
                            $IPR_Return = Invoke-PRCommand -requesttype Wmi -request $requestvars[$iurl] -Computer $computer
                            $IPR_Return.gettype()
                            if($IPR_Return -like "Error:*"){
                                $IPR_Response.ContentType = 'text/html'
                            }else{
                                # Convert the returned data to JSON and set the HTTP content type to JSON
                                $IPR_Response.ContentType = 'application/json'
                            }
                        }

                        "get" {
                            # Start the function Invoke-PRCommand with parameters
                            $IPR_Return = Invoke-PRCommand -requesttype Get -request $requestvars[$iurl] -Computer $computer
                            
                            if($IPR_Return -like "Error:*"){
                                $IPR_Response.ContentType = 'text/html'
                            }else{
                                # Convert the returned data to JSON and set the HTTP content type to JSON
                                $IPR_Return = $IPR_Return | ConvertTo-Json
                                $IPR_Response.ContentType = 'application/json'
                            }
                        }

                        Default {
                            # If no matching subdirectory/route is found generate a 404 message
                            $IPR_Return = "This is not the page you're looking for."
                            $IPR_Response.ContentType = 'text/html'
                        }
                    }
                }else{
                    $IPR_Return = "Wonderful ! You are on your POSH API! You don't have token yet, please read the doc to continue."
                    $IPR_Response.ContentType = 'text/html'
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
    }
    
    #Terminate the listener
    $listener.Stop()

}

# Path to the CSV
Do {
    $PRCSVToken = Read-Host -Prompt "Path to your CSV Token File"
}Until(Test-Path $PRCSVToken -include "*.csv")

# Listenning port
Do {
    [int]$PRPort = Read-Host -Prompt "Which port should I use ?"
}Until($PRPort -ne $null)

# CSV Token file format: UserName;Token
#$CSVToken = "C:\Windows\Temp\POSH_Restful_API\token.csv"

#Import TOKENS
$TokenList = Import-CSV -Path $PRCSVToken -Delimiter ";" -Encoding UTF8

Start-PRListener -ListingPort $PRPort -TokenList $TokenList