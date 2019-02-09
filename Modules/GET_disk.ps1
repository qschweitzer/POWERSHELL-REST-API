function Get_disk {
  param(
    $Letter
  )

  if($Letter){
    return Get-Partition -DriveLetter $Letter
  }else{
    return Get-Partition
  }
}