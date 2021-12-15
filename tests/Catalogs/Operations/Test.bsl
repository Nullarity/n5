// Create operation and check fields visibility

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Catalog.Operations.Create");

#region test1
Put ( "#AccountDr", "2211" );
Put ( "#AccountCr", "0" );
CheckState ( "#DimDr1", "Enable" );
CheckState ( "#DimDr2", "Enable" );
CheckState ( "#DimDr3", "Enable", false );

CheckState ( "#DimCr1", "Enable", false );
CheckState ( "#DimCr2", "Enable", false );
CheckState ( "#DimCr3", "Enable", false );
#endregion

#region test2
Put ( "#AccountDr", "0" );
Put ( "#AccountCr", "2211" );

CheckState ( "#DimDr1", "Enable", false );
CheckState ( "#DimDr2", "Enable", false );
CheckState ( "#DimDr3", "Enable", false );

CheckState ( "#DimCr1", "Enable" );
CheckState ( "#DimCr2", "Enable" );
CheckState ( "#DimCr3", "Enable", false );
#endregion

Set ("#Description", "Operation " + Call("Common.GetID"));
Click("#FormWrite");
Click("#FormReread");