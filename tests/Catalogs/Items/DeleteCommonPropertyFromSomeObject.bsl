// Create two folders and a common property attached to them
// Delete property from the second folder and check if that property
// is not being marked for deletion (common properties should never be
// marked for deletion automatically)

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
Click ( "#TreeAddCommon" );
With();
List = Get ( "#List" );
search = new Map ();
search [ "Description" ] = commonProperty;
List.GotoRow ( search );
Click("#FormChoose");
With();
Click ( "#FormOK" );
#endregion

#region delete
With();
Click("#OpenItemsUsage");
With();
Tree = Get ( "#Tree" );
search = new Map ();
search [ "Description" ] = commonProperty;
Assert(Tree.GotoRow ( search )).IsTrue();
Click("#TreeDelete");
Click("#FormOK");
#endregion

#region openAgainAndCheck
With();
Click("#OpenItemsUsage");
With();
Tree = Get ( "#Tree" );
search = new Map ();
search [ "Description" ] = commonProperty;
Assert(Tree.GotoRow ( search )).IsFalse();
Click ( "#TreeAddCommon" );
With();
List = Get ( "#List" );
search = new Map ();
search [ "Description" ] = commonProperty;
Assert(List.GotoRow ( search )).IsTrue();
#endregion
