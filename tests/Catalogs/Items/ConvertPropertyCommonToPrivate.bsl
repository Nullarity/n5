// Create two folders and a common property attached to them
// Try to make that property private and check if error occurs.
// The reason for error is that we can't make common property uncommon (private)
// until it is used as a common property in other objects

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.GetID" );

#region createFolder1
Commando("e1cib/list/Catalog.Items");
Click("#FormCreateFolder");
With ();
Set("#Description", "Folder1 " + id);
Set("#ItemsUsage", "Current Object Settings");
Click("#FormWrite");
#endregion

#region folder1Properties
Click("#OpenItemsUsage");
With();
Tree = Get ( "#Tree" );
Click ( "#TreeAdd" );
commonProperty = "Common Property" + id;
Set ( "#TreeName", commonProperty, Tree );
Pick ( "#TreeType", "Property Values" );
Click("#TreeCommon");
Click ( "#FormOK" );
With();
Click("#FormWriteAndClose");
#endregion

#region createFolder1
Commando("e1cib/list/Catalog.Items");
Click("#FormCreateFolder");
With ();
Set("#Description", "Folder2 " + id);
Set("#ItemsUsage", "Current Object Settings");
Click("#FormWrite");
#endregion

#region folder2Properties
Click("#OpenItemsUsage");
With();
Tree = Get ( "#Tree" );
Click ( "#TreeAddCommon" );
With();
List = Get ( "#List" );
search = new Map ();
search [ "Description" ] = commonProperty;
List.GotoRow ( search );
Click("#FormChoose");
With();
Click("#TreeCommon");
IgnoreErrors = true;
Click ( "#FormOK" );
try
	CheckErrors ();
	Stop ( "Error message about problem with common field should occur!" );
except
	With ();
	Close ();
	IgnoreErrors = false;
endtry;
#endregion
