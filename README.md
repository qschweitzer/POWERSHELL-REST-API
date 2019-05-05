# POWERSHELL REST API
A Very Simple REST API
Based on the idea and script of http://hkeylocalmachine.com/?p=518

**Don't use it in a production environment. It's a Proof Of Concept project, maybe after a lot of commit and improvment this idea will be really safe and usefull but it's not the case for now.**

## Concept
Based on the API concept, the goal project is to simplify the use of Powershell querying from any language.
You should be able to make a dashboard with POSH queries without any Powershell line.
You are able to request some information to a server with Powershell command and have a JSON result if it works or a text result with the error description if it doesn't.

Start the POSH API script on a server or computer which can access to others devices with Powershell and run.
It also works with local computer/server.

![API Illustration](https://rawcdn.githack.com/qschweitzer/POWERSHELL-REST-API/51e234a035b392e3f8be4fde897c4f4ef047d101/DOCS/API_illustrate.png)
## How to use

### Configure your custom actions
By default you have a Modules folder when downloading API.
In this Module dir, use the TPL_POSHAPI.ps1 to build your own custom actions.
You can change Modules location, just use -ModulesPath param when calling API's func.

Module's .ps1 name and function define **action verb** and **query method** (GET,POST,PUT,DELETE) and what this function will return to API.
You could create everything you want, just use the template to be sure that API will load your module. No need to restart API to test your function.

![API Function Sample](https://rawcdn.githack.com/qschweitzer/POWERSHELL-REST-API/51e234a035b392e3f8be4fde897c4f4ef047d101/DOCS/POSH API FUNC SAMPLE.png)


### Start API
> Import-Module .\RESTapi.ps1

> Invoke-PRCommand

Use **Invoke-PRCommand** function and the API will be alive.
By default API will start from http://localhost:8000

You can change API port, API Modules location and custom stop action to kill it:

> Invoke-PRCommand -APIPort \<yourport> -ModulesPath "..\Modules" -StopAction kill

### Use API
To use the API, simply do a query to http://localhost:8000/<actionverb>/param1/param2 for example.
The API will return a JSON formatted result. If error, there is a text result displayed.
You could use a web browser to query something or use other programming language to query.

Some functions are available in the Modules directory.

### Stop API
By default you could use /kill action verb:
> http://localhost:8000/kill

You could define your own custom stop action:
> Invoke-PRCommand -APIPort 8000 -ModulesPath "C:\POSH_API\Modules" -StopAction stop

## Samples
### Get Process with a given name
* Web Browser: http://localhost:8000/process/chrome
* Powershell:
> $test = Invoke-RestMethod -Method GET -Uri http://localhost:8000/process/chrome

> $test | select id,name,StartTime

![Sample Process Chrome](https://rawcdn.githack.com/qschweitzer/POWERSHELL-REST-API/51e234a035b392e3f8be4fde897c4f4ef047d101/DOCS/samples/process_chrome/1.png)
### Get Service with a given name
http://localhost:8000/service/update
### Get disk with a given letter
http://localhost:8000/disk/C
### Get disk **without** a given letter (get all disks)
http://localhost:8000/disk
### Get connected users
http://localhost:8000/connectedusers
