Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore
[bool] $testMode = $false

#Sets Date
$date = Get-Date -UFormat "%m-%d-%Y"

#consoleTranscript
$consoleTranscriptName = "Console Transcript For $date "
New-Item -Path $PSScriptRoot\consoleTranscript -Name "$consoleTranscriptname.txt" -ItemType "file" 
cls
Start-Transcript -Path $PSScriptRoot\consoleTranscript\$consoleTranscriptname.txt


Write-Output "--------------------------------------------Start------------------------------------------"
write-output "Welcome to the Clean Up Tool.
             `nThis application clears excess data automatically from the directory within the specified path.
             `nIf you'd like to input a new path, press R, otherwise, the program will automatically begin in 10 seconds."

#Timed Entry Function
Function TimedPrompt($prompt,$secondsToWait,$testMode){
	$secondsCounter = 0
	$subCounter = 0
	While ($count -lt $secondsToWait){
		start-sleep -m 10
		$subCounter = $subCounter + 10
		if($subCounter -eq 1000)
		{
			$secondsCounter++
			$subCounter = 0
			Write-Host -NoNewline "."
		}		
		if ($secondsCounter -eq $secondsToWait) {
			return $false;
		}
        if([Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::r)){
        Clear-Content "$PSScriptRoot\chosenDirectoryPath.txt" 
        $newPath =  Read-Host -Prompt "`nInput new path"
        Set-Content -Path $PSScriptRoot\chosenDirectoryPath.txt -Value $newPath
        break
        }
        if([Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::t)){
        break
        }
	}
}
$val = TimedPrompt "`n" 10 $testMode

write-output "`nIf you'd like to run test mode, press T, otherwise, the program will automatically begin in 10 seconds."

$val = TimedPrompt "`n" 10 $testMode
Write-Host $val

if([Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::t)){
$testMode = $true
}

#Ask for path
$chosenDirectoryPath = get-content $PSScriptRoot\chosenDirectoryPath.txt 
#test Path
$testPath = Test-Path -Path $chosenDirectoryPath -PathType Leaf
         if($chosenDirectoryPath -eq $false){
            $errorLog.Add("$chosenDirectoryPath coudld not be found`n")
         }

#Creating List
$deletedFileLog = New-Object Collections.Generic.List[String]
$errorLog = New-Object Collections.Generic.List[String]
$oimFileList =  Get-ChildItem -Path $chosenDirectoryPath\*oim -Recurse
$oscFileList =  Get-ChildItem -Path $chosenDirectoryPath\*osc -Recurse
$txtFileList =  Get-ChildItem -Path $chosenDirectoryPath\*txt -Recurse | Where-Object { $_ -notlike '*-*' }
$txtFileList_NEW =  Get-ChildItem -Path $chosenDirectoryPath\*txt -Recurse | Where-Object { $_ -like '*-*' }



#Duplicate-finding algorithm for OSC files

#Sorts Through List1
$OSCfileJob= Start-Job -ScriptBlock{
    for($i=0;$i -lt $oimFileList.Count; $i++){
        #Sorts Through List2
        for($z=0;$z -lt $oscFileList.Count; $z++){
            #Checks For Same Name
            If(($oimFileList[$i]).BaseName -eq ($oscFileList[$z]).BaseName)
            {
             #Gives Temp short name
             $tempName = ($oscFileList[$z]).Name
             #Test Path/ error check
             $testPath = Test-Path -Path $chosenDirectoryPath\$tempName -PathType Leaf
             if($testPath -eq $false){   
                $errorLog.Add("$tempName coudld not be found`n")
             }
             #Logs Duplicate
             $deletedFileLog.Add("$tempName`n")
             #Deletes File off of directory and list
             if([bool]$testMode -eq $false){
             Remove-Item $oscFileList[$z]
             }
            }
        }                  
    }
}

Receive-Job $OSCfileJob

#Duplicate-finding algorithm for -NEW files

#Sorts through "-NEW"
$NEWFileJob= Start-Job -ScriptBlock{
    for($i=0;$i -lt $txtFileList_NEW.Count; $i++){
        #Sorts through no "-NEW"
        for($z=0;$z -lt $txtFileList.Count; $z++){
            #Checks for matching name
            if((($txtFileList_NEW[$i]).BaseName).Trim("N""E""W""-") -eq ($txtFileList[$z]).BaseName){
             #Gives Temp short name
             $tempName = ($txtFileList[$z]).Name
             #Test Path/ error check
             $testPath = Test-Path -Path $chosenDirectoryPath\$tempName -PathType Leaf 
             if($testPath -eq $false){
                 $errorLog.Add("$tempName coudld not be found`n")
             }
             #Logs Duplicate
             $deletedFileLog.Add("$tempName`n")
             #Removes Duplicate
             if([bool]$testMode -eq $false){
             Remove-Item $txtFileList[$z] 
             } 
            }     
        }
    }
}

Receive-Job $NEWFileJob

#files Deleted Log
$deletedFileLogName = "Files Deleted On $date "
New-Item -Path $PSScriptRoot\deletedFileLogs -Name "$deletedFileLogName.txt" -ItemType "file" -Value $deletedFileLog

#Creates Error Log Name
$errorLogName = "Missing File Log For $date"

#if no errors
if($errorLog.count -le 0){
 $errorLog.Add("No Missing Files`n")
}

#Creates Error Log
New-Item -Path $PSScriptRoot\missingFileLogs -Name "$errorLogName.txt" -ItemType "file" -Value $errorLog


#End Of script
Write-Output "`nDone"