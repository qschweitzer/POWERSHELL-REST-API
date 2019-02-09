<#
Function Name: <METHOD>_<ActionVerb>
Example: Function Get_Disk --> Return a Get-Partition command results

ps1 Name: Name of your function
Example: Get_Disk.ps1

param(): All Params you need. No restriction. API will parse all params in the URL and use them when calling this func.
Exemple:
  param(
    $Letter,
    $OperationnalStatus
  )

Function container:
Everything you wish. One rule: Never forget the <return> at the end.

##################
Sample:

Function xxxx_xxxx {
  param(

  )

  return <result>
}

##################
#>