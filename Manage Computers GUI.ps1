#Written by:  morelanl
#
#
#Purpose:
#This script runs a GUI that allows you to check the auto logon, restart a remote computer, set auto logon info
#
#How to use:
#Run the GUI, type the name of a computer, and choose your option
#
#


Add-Type -AssemblyName presentationframework, presentationcore


function getDrives {
    
    Get-PSDrive | Where-Object {$_.Free -gt 0}
}

function EditRegistry{

   param(

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Name,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Value

   )

    $Path = '\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    set-location -Path HKLM:
    $tb = Get-Item -Path $Path
       
    If($null -eq $tb.GetValue($Name)) {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType string
    } else {
        
        Set-ItemProperty -Path $Path -Name $Name -Value $Value
      }

}

Function Get-AutoLogon{

[CmdletBinding()]
    # This param() block indicates the start of parameters declaration
    param (
        <# 
            This parameter accepts the name of the target computer.
            It is also set to mandatory so that the function does not execute without specifying the value.
        #>
        [Parameter(Mandatory)]
        [string]$Computer
    )


$LogonInfo = Invoke-Command -ComputerName $Computer -ScriptBlock {

set-location -path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

$username = Get-ItemPropertyValue -name defaultusername
$password = Get-ItemPropertyValue -name defaultpassword
$Logon = Get-ItemPropertyValue -name autoadminlogon
 
"Username: $username`n"
"Password: $password`n"
"Auto Logon: $Logon`n"
}
"Computer Name: $computer`n"
$LogonInfo
}

#
#This is the GUI that runs the code. It gets rid of the requirement to have an XAML file associated with the .ps1 file
#

$GUI = {

    <Window x:Name ="TestWindow" x:Class="PoshGUI_sample.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:local="clr-namespace:PoshGUI_sample"
    mc:Ignorable="d"
    Title="Manage Computers" Height="499.013" Width="422.223">
<Grid>
    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="83*"/>
        <ColumnDefinition Width="124*"/>
    </Grid.ColumnDefinitions>
    <Grid.RowDefinitions>
        <RowDefinition Height="498*"/>
        <RowDefinition Height="5*"/>
    </Grid.RowDefinitions>
    <Label Content="Computer Name:" HorizontalAlignment="Left" Margin="10,12,0,0" VerticalAlignment="Top"/>
    <TextBox Name="txtComputer" HorizontalAlignment="Left" Height="23" Margin="125,14,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="261" Grid.ColumnSpan="2"/>
    <Button Name="btnQuery" Content="Auto Logon Info" HorizontalAlignment="Left" Margin="132.572,111,0,0" VerticalAlignment="Top" Width="98" Grid.Column="1"/>
    <TextBox Name="txtResults" HorizontalAlignment="Left" Height="186" Margin="20,257,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="366" Grid.ColumnSpan="2"/>
    <Button Name="btnRestart" Content="Restart" HorizontalAlignment="Left" Margin="155.572,84,0,0" VerticalAlignment="Top" Width="75" Grid.Column="1"/>
    <TextBox Name="txtUsername" HorizontalAlignment="Left" Height="23" Margin="132,79,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="120" Grid.ColumnSpan="2"/>
    <TextBlock Name="blkUsername" HorizontalAlignment="Left" Margin="20,82,0,0" TextWrapping="Wrap" Text="Username" VerticalAlignment="Top"/>
    <TextBox Name="txtPassword" HorizontalAlignment="Left" Height="23" Margin="132,109,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="120" Grid.ColumnSpan="2"/>
    <TextBlock Name="blkPassword" HorizontalAlignment="Left" Margin="20,113,0,0" TextWrapping="Wrap" Text="Password" VerticalAlignment="Top"/>
    <TextBox Name="txtAutoAdmin" HorizontalAlignment="Left" Height="23" Margin="132,139,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="120" Grid.ColumnSpan="2"/>
    <TextBlock HorizontalAlignment="Left" Margin="20,142,0,0" TextWrapping="Wrap" Text="Auto Admin Logon" VerticalAlignment="Top" Width="107"/>
    <TextBlock HorizontalAlignment="Left" Margin="20,54,0,0" TextWrapping="Wrap" Text="Set Auto Logon" VerticalAlignment="Top" FontSize="14"/>
    <TextBox Name="txtDomain" HorizontalAlignment="Left" Height="23" Margin="132,170,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="120" Grid.ColumnSpan="2"/>
    <TextBlock HorizontalAlignment="Left" Margin="20,173,0,0" TextWrapping="Wrap" Text="Default Domain" VerticalAlignment="Top"/>
    <Button Name="btnAutoLogon" Content="Set Auto Logon" HorizontalAlignment="Left" Margin="21,210,0,0" VerticalAlignment="Top" Width="97"/>
    <Button Name="btnSerial" Content="Get Serial Number" HorizontalAlignment="Left" Margin="123.572,56,0,0" VerticalAlignment="Top" Width="107" Grid.Column="1"/>
    <Button Name="btnDrive" Content="Get Drives" HorizontalAlignment="Left" Margin="155.572,138,0,0" VerticalAlignment="Top" Width="75" Grid.Column="1"/>

</Grid>
</Window>

}


$wpf = @{ }
$inputXML = $GUI
$inputXMLClean = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace 'x:Class=".*?"','' -replace 'd:DesignHeight="\d*?"','' -replace 'd:DesignWidth="\d*?"',''
[xml]$xaml = $inputXMLClean
$reader = New-Object System.Xml.XmlNodeReader $xaml
$tempform = [Windows.Markup.XamlReader]::Load($reader)
$namedNodes = $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")
$namedNodes | ForEach-Object {$wpf.Add($_.Name, $tempform.FindName($_.Name))}

#
#Sets the auto logon info
#

$wpf.btnAutoLogon.Add_Click( {
    #clear the result box
    $wpf.txtResults.Text = ""
    $computer = $wpf.txtComputer.Text

    if (Test-Connection $wpf.txtComputer.Text -quiet){

            Invoke-Command -ComputerName $computer -ScriptBlock $Function:EditRegistry -ArgumentList "defaultusername", $wpf.txtUsername.Text
            Invoke-Command -ComputerName $computer -ScriptBlock $Function:EditRegistry -ArgumentList "defaultpassword", $wpf.txtPassword.Text
            Invoke-Command -ComputerName $computer -ScriptBlock $Function:EditRegistry -ArgumentList "autoadminlogon", $wpf.txtAutoAdmin.Text
            Invoke-Command -ComputerName $computer -ScriptBlock $Function:EditRegistry -ArgumentList "defaultdomainname", $wpf.txtDomain.Text

            $wpf.txtResults.Text = "Auto Logon has been set on:" + $wpf.txtComputer.Text
        }
    else{
            $wpf.txtResults.Text = "Computer is not online: " + $wpf.txtComputer.Text
        }
})


#
#Finds Auto Logon Information
#

$wpf.btnQuery.Add_Click( {
#clear the result box
   $wpf.txtResults.Text = ""

   if (Test-Connection $wpf.txtComputer.Text -quiet){
    $wpf.txtResults.Text = Get-autologon -Computer $wpf.txtComputer.Text
    }
    else{
    $wpf.txtResults.Text = "Computer is not online: " + $wpf.txtComputer.Text
    }

})

#
#Restarts the computer
#
$wpf.btnRestart.Add_Click( {
    #clear the result box
    $wpf.txtResults.Text = ""

    $computer = $wpf.txtComputer.Text

    if (test-connection $computer -quiet) {

        invoke-command -computername $computer -scriptblock {
            
            Restart-Computer -Force  
            
        }
        $wpf.txtResults.Text = "Computer has rebooted : $computer"
            
    }
    else {
	    $wpf.txtResults.Text = "$computer is not online"
    }
})

#
#Finds all local drives and space available
#

$wpf.btnDrive.Add_Click( {
    #clear the result box
    $wpf.txtResults.Text = ""

    if (Test-Connection $wpf.txtComputer.Text -quiet){
        $wpf.txtResults.Text = Invoke-Command -ComputerName $wpf.txtComputer.Text -ScriptBlock $Function:getDrives
        
    }
    else{
        $wpf.txtResults.Text = "Computer is not online: " + $wpf.txtComputer.Text
    }

})



$wpf.TestWindow.ShowDialog() | Out-Null
