function Get_service {
  param(
    $Name,
    $Status
  )

  if($Status){
    return Get-Service -Name ("*$Name*") | where-object { $_.Status -match $Status}
  }else{
    return Get-Service -Name ("*$Name*")
  }
}