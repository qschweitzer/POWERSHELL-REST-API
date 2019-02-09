# POSH_REST_API
A Very Simple REST API
Based on the idea and script of http://hkeylocalmachine.com/?p=518

**Don't use it in a production environment. It's a Proof Of Concept project, maybe after a lot of commit and improvment this idea will be really safe and usefull but it's not the case for now.**

## Concept
Based on the API concept, this project want to simplify the use of Powershell querying from another language, another plateform.
You should be able to make a dashboard with POSH queries without any Powershell line.
You are able to request some information to a server with Powershell command and have a JSON result if it works or a text result with the error description if it doesn't.

Start the POSH API script on a server or computer which can access to others devices with Powershell and run.
It also works with local computer/server.

## How to use

### Configure your custom actions
By default you have a Modules folder when downloading API.
In this Module dir, use the TPL_POSHAPI.ps1 to build your own custom actions.
You can change Modules location, just use -ModulesPath param when calling API's func.

Module's .ps1 name and function define action verb and query method (GET,POST,PUT,DELETE) and what this function will return to API.
You could create everything you want, just use the template to be sure that API will load your module. No need to restart API to test your function.

### Start API
Import-Module RESTapi.ps1
Use Invoke-PRCommand function and the API will be alive.
By default API will start from http://localhost:8000

You can change API port and API Modules location:
Invoke-PRCommand -APIPort <yourport> -ModulesPath "..\Modules"

### Use API
To use the API, simply do a query to http://localhost:8000/<actionverb>/param1/param2 for example.
The API will return a JSON formatted result. If error, there is a text result displayed.
You could use a web browser to query something or use other programming language to query.

Some functions are available in the Modules directory.

### Stop API
http://localhost:8000/kill
or kill the script process.
