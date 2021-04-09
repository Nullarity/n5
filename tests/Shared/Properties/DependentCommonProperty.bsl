// Create folder Boots with private property Brand
// Create a common property Size with dependency of Brand
// Check how it works

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.GetID" );

#region createFolder
Commando("e1cib/list/Catalog." + _.Name);
Click("#FormCreateFolder");
With ();
Set("#Description", "Boots " + id);
Set("#ItemsUsage", "Current Object Settings");
Click("#FormWrite");
#endregion

#region createProperties
Click("#OpenItemsUsage");
With();
Tree = Get ( "#Tree" );
Click ( "#TreeAdd" );
Set ( "#TreeName", "Brand", Tree );
Pick ( "#TreeType", "Property Values" );
Click ( "#TreeAdd" );
Set ( "#TreeName", "Size", Tree );
Pick ( "#TreeType", "Property Values" );
Pick ( "#TreeHost", "Brand (Boots " + id + ")" );
Click("#TreeCommon");
Next ();
Click ( "#FormOK" );
With();
Click("#FormWriteAndClose");
#endregion

#region createItemSony
With();
Get ( "#List").Choose ();
Click("#FormCreate");
With();
field = Get("Brand");
field.OpenDropList ();
field.Create ();
With();
Set("#Description", "Sony");
Click("#FormWrite");
With();
Click("#FormWriteAndClose");
With();
Activate("Size").Create ();
With();
Set("#Description", "Big");
Click("#FormWriteAndClose");
With();
Check("#Description", "Sony, Big");
Click("#FormWriteAndClose");
#endregion

#region createItemPanasonic
With();
Click("#FormCreate");
With();
field = Get("Brand");
field.OpenDropList ();
field.Create ();
With();
Set("#Description", "Panasonic");
Click("#FormWrite");
With();
Click("#FormWriteAndClose");
With();
Choose ("Size");
With();
// We should not have any other sizes here
Assert(Call("Table.Count", Get("#List"))).Equal(0);
Click("#FormCreate");
With();
Set("#Description", "Small");
Click("#FormWriteAndClose");
With();
Click("#FormChoose");
With();
Check("#Description", "Panasonic, Small");
Click("#FormWrite");
#endregion

#region selectSize
Choose("Size");
With();
Assert(Call("Table.Count", Get("#List"))).Equal(1);
#endregion