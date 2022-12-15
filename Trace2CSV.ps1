<#
Turn a trace file into a csv for calculations
We need to copy the trace file first because Ivanti has the file in use and writes to it resulting in a file that is twice as big as the original Trace File
Then we set some variables and 'read' the file as text to fiddle with the first two lines.
#>

$TraceFile = Get-ItemPropertyValue 'HKLM:\SOFTWARE\WOW6432Node\RES\Workspace Manager' -Name TraceFile
$WorkArea = "\\BFD1\b20000\b20000PRIV\fit2rdk\Debug\TracePlace"
$TimeStamp = Get-Date -Format yyyyMMddHHmm
$TempTrace = "$WorkArea\Trace-$Timestamp.txt"

Write-Host "Step 1: Copy the Trace File"

Copy-Item -Path $TraceFile -Destination $TempTrace -Force -Verbose

Write-Host "Step 2: Capture the Trace File and prepare it for processing"

$Tekst = Get-Content -Path $TempTrace

# The Second line ($Tekst[1]) contains the Column headers but with "[]" around them. Not convenient, so we delete them.
$tekst[1] = (($tekst[1]).Replace("[","").Replace("]",""))

Write-Host "Step 3: Write back the altered file"

# The first line ($Tekst[0]) contains jibberish, we skip it when we write everything back to a text file.
$Tekst = $Tekst[1..($Tekst.count - 1)] | Out-File -FilePath $WorkArea\TraceFixed$TimeStamp.txt -Force -verbose

Write-Host "Step 4: Import the File as CSV for manipulation"

# Load the altered text file as CSV so the lines can become individual objects
$Source = Import-Csv -Path $WorkArea\TraceFixed$TimeStamp.txt -Delimiter `t -Verbose

# Delete the incomplete line Where the newest event has overwritten (part of) the oldest event
$Source = $Source | Where-Object -Property Time -Like "$((Get-Date).Year)*" 

Write-Host "Step 5: Write the final csv file"

# Add line numbers for more accurate sorting and a column for TimeTaken
$l = 0
$Source | ForEach-Object {$_ | Add-Member -NotePropertyName Line -NotePropertyValue $l -Force;
                          $_ | Add-Member -NotePropertyName TimeTaken -NotePropertyValue "Start" -Force; $l++}

# Calcualte the time taken
1..($Source.count-1)| ForEach-Object {
   $Source[$PSITEM].TimeTaken = (New-TimeSpan -Start $Source[$PSITEM-1].Time -End $Source[$PSITEM].Time).TotalSeconds
}


# Filter it on username, sort it by Time (and line number), only pick the relevant info, and write it to CSV 
$Source  | Where-Object -Property Username -ne 'SYSTEM' |
                 Sort-Object -Property Time,Line |
                         Select-Object -Property Time,TimeTaken,Executable,Info |
                                Export-Csv -path $WorkArea\Trace$TimeStamp.csv -Delimiter `t -Force -NoTypeInformation -Verbose

Write-Host "Step 6: Cleanup in aisle 6"

# Delete the temporary text files and csv files older than 14 days.
Remove-Item -Path $WorkArea\*$TimeStamp.txt -Verbose
Get-ChildItem $workarea\Trace*.csv | Where-Object {$_.LastWriteTime -le ((Get-Date).AddDays(-14)) } | Remove-Item -Verbose

# Because it takes quite a while to complete this script, I want to see how long it took.
$Now = get-date -Format yyyyMMddHHmm
Write-Host "Step 7: Done in $($Now-$TimeStamp) minutes"

