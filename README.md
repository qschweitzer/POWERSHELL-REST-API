# POSH_REST_API
A Very Simple REST API
Based on the idea and script of http://hkeylocalmachine.com/?p=518
**Don't use it in a production environnent. It's a Proof Of Concept project, maybe after a lot of commit and improvment this idea will be really safe and usefull but it's not the case for now.**

## Concept
Based on the API concept, this project want to simplify the use of Powershell querying from another language, another plateform.
You should be able to make a dashboard with POSH queries without any Powershell line.
You are able to request some information to a server with Powershell command and have a JSON result if it works or a text result with the error description if it doesn't.

## How to use
### Create Token
You have to create a token manually on a file called token.csv: C:\Windows\Temp\Posh_Restful_api\token.csv
The file is formatted like: UserName;Token
Separator: **;**
/!\ If you use comma to split each column the reading of the token file will fail and you won't be able to use the API.

### Start API
Start the .ps1 file ans the API will be alive.
start from http://localhost:8000

### Use API
#### GET
To use the API, simply do a GET query to http://localhost:8000/token=yourtoken/(optional:computer=targetcomputer)/get/command=get-help
for example.
The API will return a JSON formatted result. If error, there is a text result displayed.
You could use a web browser to query something or use other programming language to query.
#### WMI
There is a WMI query type but it's actually limited.
http://localhost:8000/token=yourtoken/(optional:computer=targetcomputer)/wmi/query

### Stop API
http://localhost:8000/kill
or kill the script process.
