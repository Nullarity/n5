// Create common property and check if it comes to Common Properties register.
// Then uncheck Common and check if it leaves Common Properties register.

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
Click("#FormWrite");
Close();
#endregion

#region checkCommonPropertiesRegister
Commando("e1cib/list/InformationRegister.CommonProperties");
Assert(GotoRow(Get("#List"), "Property", commonProperty)).IsTrue();
Close();
#endregion

#region makePrivate
With("Items", true);
Click("#FormChange");
With();
Click("#OpenItemsUsage");
With();
Tree = Get ( "#Tree" );
search = new Map ();
search [ "Description" ] = commonProperty;
Tree.GotoRow ( search );
Activate ( "#FieldOptions" ); // FieldOptions
Get ( "#TreeCommon" ).SetCheck ();
Click ( "#FormOK" );
#endregion

#region checkCommonPropertiesEmptiness
With();
Close();
Commando("e1cib/list/InformationRegister.CommonProperties");
Assert(GotoRow(Get("#List"), "Property", commonProperty)).IsFalse();
#endregion
