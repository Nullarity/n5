Function CheckParameter ( CommandParameter, FolderNotSuppored, DeletionMarkNotSuppoted ) export
	
	data = getData ( CommandParameter, FolderNotSuppored, DeletionMarkNotSuppoted );
	if ( FolderNotSuppored and data.IsFolder ) then
		Output.CommandForFolderNotSupported ();
		return false;
	elsif ( DeletionMarkNotSuppoted and data.DeletionMark ) then
		Output.CommandForDeletionMarkNotSupported ();
		return false;
	endif; 
	return true;
	
EndFunction 

Function getData ( CommandParameter, FolderNotSuppored, DeletionMarkNotSuppoted )
	
	fields = "";
	if ( FolderNotSuppored ) then
		fields = fields + ", IsFolder";
	endif; 
	if ( DeletionMarkNotSuppoted ) then
		fields = fields + ", DeletionMark";
	endif; 
	return DF.Values ( CommandParameter, Mid ( fields, 3 ) );
	
EndFunction 
