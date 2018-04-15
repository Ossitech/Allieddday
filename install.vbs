Set fso=Wscript.CreateObject("Scripting.FileSystemObject")
Set shell=WScript.CreateObject("WScript.Shell")
Dim path
Dim test
path=shell.ExpandEnvironmentStrings("%userProfile%")&"\Documents\My Games\Gas Powered Games\Supreme Commander Forged Alliance"
selectedPath=SelectFolder(path, "Wähle den Forged Alliance Ordner aus!")
If test="1" Then
	MsgBox "Canceled!"
Else
	fso.CopyFolder "allieddday", selectedPath&"\Maps\allieddday"
    fso.CopyFolder "Custom Dialogs", selectedPath&"\Mods\Custom Dialogs"
    if not fso.FolderExists(selectedPath&"\movies") Then
        selectedPath=SelectFolder("", "Wähle den Forged Alliance Ordner aus!")
    End If
    fso.CopyFile "attacking.sfd", selectedPath&"\movies\"
    fso.CopyFile "intro.sfd", selectedPath&"\movies\"
    fso.CopyFile "usa.sfd", selectedPath&"\movies\"
End If
Function SelectFolder( myStartFolder, myHint)

    ' Standard housekeeping
    Dim objFolder, objItem, objShell
    
    ' Custom error handling
    On Error Resume Next
    SelectFolder = vbNull

    ' Create a dialog object
    Set objShell  = CreateObject( "Shell.Application" )
    Set objFolder = objShell.BrowseForFolder( 0, myHint, 0, myStartFolder )

    ' Return the path of the selected folder
    If IsObject( objfolder ) Then SelectFolder = objFolder.Self.Path

    ' Standard housekeeping
    Set objFolder = Nothing
    Set objshell  = Nothing
    On Error Goto 0
End Function