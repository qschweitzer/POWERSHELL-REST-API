
$CSVToken = "C:\Windows\Temp\POSH_Restful_API\token.csv"

#Import TOKENS
$TokenList = Import-CSV -Path $CSVToken -Delimiter ";" -Encoding UTF8
# CSV Token file is formatted like: UserName;Token

# Create a listener on port 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8000/') 
$listener.Start()
write-host 'Listening ...'

# Run until you send a GET request to /end
while ($true) {

    $context = $listener.GetContext() 

    # Capture the details about the request
    $request = $context.Request

    # Setup a place to deliver a response
    $response = $context.Response
   
    # Break from loop if GET request sent to /end
    if ($request.Url -match '/kill') { 
        break 
    } else {

        # Split request URL to get command and options
        $requestvars = ([String]$request.Url).split("/")
        if($requestvars.Count -le "3"){
            $message = "Your request is not correct. Please look at the help of the API."
            $response.ContentType = 'text/html'
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

                # If a request is sent to http:// :8000/wmi
                Switch($requesttype){
                    
                    "wmi" {
                
                        # Get the class name and server name from the URL and run get-WMIObject
                        $result = get-WMIObject $requestvars[$iurl] -computer $computer

                        # Convert the returned data to JSON and set the HTTP content type to JSON
                        $message = $result | ConvertTo-Json
                        $response.ContentType = 'application/json'

                    }

                    "get" {
                        if($requestvars[$iurl] -like "command=*"){
                            # Build command
                            $command = $requestvars[$iurl].split("=")[1]
                            if($computer){
                                $result = Invoke-Expression -Command $command -computer $computer -ErrorAction SilentlyContinue -ErrorVariable InvokeError
                            }
                            else{
                                $result = Invoke-Expression -Command $command -ErrorAction SilentlyContinue -ErrorVariable InvokeError
                            }
                        }else{
                            # Build response
                            $InvokeError = "There is something wrong with your query or the result."
                        }
                        
                        if($InvokeError){
                            $message = "There is something wrong with your query or the result."
                            $response.ContentType = 'text/html'
                        }else{
                            # Convert the returned data to JSON and set the HTTP content type to JSON
                            $message = $result | ConvertTo-Json
                            $response.ContentType = 'application/json'
                        }
                    }

                    Default {
                        # If no matching subdirectory/route is found generate a 404 message
                        $message = "This is not the page you're looking for."
                        $response.ContentType = 'text/html'
                    }
                }
            }else{
                $message = "You don't have a valid token"
                $response.ContentType = 'text/html'
            }
            # Convert the data to UTF8 bytes
            [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
            
            # Set length of response
            $response.ContentLength64 = $buffer.length
            
            # Write response out and close
            $output = $response.OutputStream
            $output.Write($buffer, 0, $buffer.length)
            $output.Close()
        }
   }    
}
 
#Terminate the listener
$listener.Stop()
