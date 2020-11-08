#=========================================================================================================
#ここからタスクトレイに入れるためのパーツよくわからんから変えない
#@Powershell -NoP -W Hidden -C "$PSCP='%~f0';$PSSR='%~dp0'.TrimEnd('\');&([ScriptBlock]::Create((gc '%~f0'|?{$_.ReadCount -gt 1}|Out-String)))" %* & exit/b
# by earthdiver1  V1.05
if ($PSCommandPath) {
    $PSCP = $PSCommandPath
    $PSSR = $PSScriptRoot
    $code = '[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd,int nCmdShow);'
    $type = Add-Type -MemberDefinition $code -Name Win32ShowWindowAsync -PassThru
    [void]$type::ShowWindowAsync((Get-Process -PID $PID).MainWindowHandle,0) }
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$menuItem = New-Object System.Windows.Forms.MenuItem "Exit"
$menuItem.add_Click({$notifyIcon.Visible=$False;while(-not $status.IsCompleted){Start-Sleep 1};$appContext.ExitThread()})
$contextMenu = New-Object System.Windows.Forms.ContextMenu
$contextMenu.MenuItems.AddRange($menuItem)
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.ContextMenu = $contextMenu
$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSCP)
$notifyIcon.Text = (Get-ChildItem $PSCP).BaseName
$notifyIcon.Visible = $True
$_syncHash = [hashtable]::Synchronized(@{})
$_syncHash.NI   = $notifyIcon
$_syncHash.PSCP = $PSCP
$_syncHash.PSSR = $PSSR
$runspace = [RunspaceFactory]::CreateRunspace()
$runspace.ApartmentState = "STA"
$runspace.ThreadOptions  = "ReuseThread"
$runspace.Open()
$runspace.SessionStateProxy.SetVariable("_syncHash",$_syncHash)
$scriptBlock = Get-Content $PSCP | ?{ $on -or $_[1] -eq "!" }| %{ $on=1; $_ } | Out-String
$action=[ScriptBlock]::Create(@'
#   param($Param1, $Param2)
    Start-Transcript -LiteralPath ($_syncHash.PSCP -Replace '\..*?$',".log") -Append
    Function Start-Sleep { [CmdletBinding(DefaultParameterSetName="S")]
        param([parameter(Position=0,ParameterSetName="M")][Int]$Milliseconds,
              [parameter(Position=0,ParameterSetName="S")][Int]$Seconds,[Switch]$NoExit)
        if ($PsCmdlet.ParameterSetName -eq "S") {
            $int = 5
            for ($i = 0; $i -lt $Seconds; $i += $int) {
                if (-not($NoExit -or $_syncHash.NI.Visible)) { exit }
                Microsoft.PowerShell.Utility\Start-Sleep -Seconds $int }
        } else {
            $int = 100
            for ($i = 0; $i -lt $Milliseconds; $i += $int) {
                if (-not($NoExit -or $_syncHash.NI.Visible)) { exit }
                Microsoft.PowerShell.Utility\Start-Sleep -Milliseconds $int }}}
    $script:PSCommandPath = $_syncHash.PSCP
    $script:PSScriptRoot  = $_syncHash.PSSR
'@ + $scriptBlock)
$PS = [PowerShell]::Create().AddScript($action) #.AddArgument($Param1).AddArgument($Param2)
$PS.Runspace = $runspace
$status = $PS.BeginInvoke()
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)
exit
#! ---------- ScriptBlock (Line No. 28) begins here ---------- DO NOT REMOVE THIS LINE
#=========================================================================================================
#ここからタスクトレイで一生まわすやつかく
while ($True) {


#サンプルでメモリ使用率監視ぐるぐる
#ここから notepad.exe の監視を始める。スクリプトファイルと同一ディレクトリにlog.txtできる
#ここはすきなのかけばOK
$FileName = "log.txt"
$ProcessName = "notepad"

"Time,Working set(MB)" | Out-File -Append $FileName
while($TRUE){
    $d = Get-Date -Format "yyyy-MM-dd HH:mm:ss.ff"
    $p = Get-Process -Name $ProcessName | Select-Object WS
    $p | ForEach-Object {$mem = 0} {$mem += $_.WS}
    $mem = ($mem/1024/1024).ToString()
    $d+', '+$mem+'MB' | Out-File -Append $FileName
    Start-Sleep -Seconds 1
}



}
#ここまでwhileのかっこ
#=========================================================================================================



