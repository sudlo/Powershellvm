# Purpose : List all orphaned vmdk on all datastores in all VC's
# Version: 1.0


#Main

$arrayVC = "YourVirtualCenter"
$OutputFile = "C:\OrphanedVMDK.txt"

Foreach ($strVC in $arrayVC)
{
	Connect-VIServer $strVC 
	$arrUsedDisks = Get-VM | Get-HardDisk | %{$_.filename}
	$arrDS = Get-Datastore
	Foreach ($strDatastore in $arrDS)
	{
	   $strDatastoreName = $strDatastore.name
	   Write-Host $strDatastoreName
	   $ds = Get-Datastore -Name $strDatastoreName | %{Get-View $_.Id}
	   $fileQueryFlags = New-Object VMware.Vim.FileQueryFlags
	   $fileQueryFlags.FileSize = $true
	   $fileQueryFlags.FileType = $true
	   $fileQueryFlags.Modification = $true
	   $searchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
	   $searchSpec.details = $fileQueryFlags
	   $searchSpec.sortFoldersFirst = $true
	   $dsBrowser = Get-View $ds.browser
	   $rootPath = "["+$ds.summary.Name+"]"
	   $searchResult = $dsBrowser.SearchDatastoreSubFolders($rootPath, $searchSpec)
	   $myCol = @()
	   foreach ($folder in $searchResult)
	   {
	      foreach ($fileResult in $folder.File)
	      {
             $file = "" | select Name, FullPath			
		     $file.Name = $fileResult.Path
		     $strFilename = $file.Name
		     IF ($strFilename)
		     {
		     IF ($strFilename.Contains(".vmdk")) 
		     {
		     IF (!$strFilename.Contains("-flat.vmdk"))
		     {
		     IF (!$strFilename.Contains("delta.vmdk"))		  
		     {
		        $strCheckfile = "*"+$file.Name+"*"
			 IF ($arrUsedDisks -Like $strCheckfile){}
	         ELSE 
			 {			 
			 $strOutput = $strDatastoreName + " Orphaned VMDK Found: " + $strFilename
			 $strOutput | Out-File $Outputfile -width 150 -Append
			 }	         
		     }
		     }		  
		     }
		     }
	      }
	   }       
   }	
}