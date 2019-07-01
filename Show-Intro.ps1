# Functions
function Stop-Script {
	[cmdletbinding()]
	param([string]$Message = "")

	Write-Warning $Message
	Read-Host "Execution have terminated! Press Enter to close the window"
	exit
}

Write-Host "Preparing patches..."

# Patches to apply
$Patches = @(
	[PSCustomObject]@{
		File = '.\assets\js\game.compiled.js'
		Changes = @(
			[PSCustomObject]@{
				Original = 'this.introGui.start();this.bgGui.doStateTransition("HIDDEN",true);this.doStateTransition(e,true)'
				Patched = 'this._introDone();this.doStateTransition(e, true);'
			}
		)
		Content = $null
	}
)

Write-Host "Verifying files..."

# Pre-patch checks...
ForEach ($Patch in $Patches)
{
	If((Test-Path -Path $Patch.File) -eq $false)
	{
		Stop-Script "One or more of the required files were not. Verify that the script is being run in the game folder."
	} else {
		
		Write-Host "Reading file contents..."
		$Patch.Content = Get-Content -Path $Patch.File -Raw

		if($Patch.Content)
		{
			ForEach ($Change in $Patch.Changes)
			{
				$MatchesFound = ($Patch.Content -split $Change.Patched, 0, "simplematch" | Measure-Object | Select-Object -Exp Count) - 1
				if($MatchesFound -ne 1)
				{
					Stop-Script "Expected 1 match but found $MatchesFound, in file '$($Patch.File)', for line:
					$($Change.Patched)"
				}
			}
		} else {
			Stop-Script "The file was empty."
		}
	}
}

# Everything looks fine, let's patch the files!
ForEach ($Patch in $Patches)
{
	Write-Host "Applying patches to " $Patch.File "..."

	ForEach ($Change in $Patch.Changes)
	{
		$Patch.Content = $Patch.Content -replace [regex]::escape($Change.Patched), $Change.Original
	}
	
	$Patch.Content | Set-Content -Path $Patch.File
}

Write-Host "Patching finished. Press Enter to exit the script."
Read-Host
