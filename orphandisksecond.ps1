$report = @()
$arrUsedDisks = Get-View -ViewType VirtualMachine | % {$_.Layout} | % {$_.Disk} | % {$_.DiskFile}
$arrDS = Get-Datastore | Sort-Object -property Name
foreach ($strDatastore in $arrDS) {
    Write-Host $strDatastore.Name
    $ds = Get-Datastore -Name $strDatastore.Name | % {Get-View $_.Id}
    $fileQueryFlags = New-Object VMware.Vim.FileQueryFlags
    $fileQueryFlags.FileSize = $true
    $fileQueryFlags.FileType = $true
    $fileQueryFlags.Modification = $true
    $searchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
    $searchSpec.details = $fileQueryFlags
    $searchSpec.matchPattern = "*.vmdk"
    $searchSpec.sortFoldersFirst = $true
    $dsBrowser = Get-View $ds.browser
    $rootPath = "[" + $ds.Name + "]"
    $searchResult = $dsBrowser.SearchDatastoreSubFolders($rootPath, $searchSpec)

    foreach ($folder in $searchResult)
    {
        foreach ($fileResult in $folder.File)
        {
            if ($fileResult.Path)
            {
                if (-not ($arrUsedDisks -contains ($folder.FolderPath + $fileResult.Path))){
                    $row = "" | Select DS, Path, File, Size, ModDate
                    $row.DS = $strDatastore.Name
                    $row.Path = $folder.FolderPath
                    $row.File = $fileResult.Path
                    $row.Size = $fileResult.FileSize
                    $row.ModDate = $fileResult.Modification
                    $report += $row
                }
            }
        }
    }
}
