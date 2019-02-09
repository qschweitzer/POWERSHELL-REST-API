function Get_Process {
  param(
    $processname
  )
    Get-Process -Name ("*"+$processname+"*")
}