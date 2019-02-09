function Get_ConnectedUsers {
  param(
    $Computer = $env:ComputerName
  )
  $result = get-wmiobject -Class Win32_Computersystem | select Username
  return $result
}