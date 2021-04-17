env = _;
date = Env.Date;
writeOffAssets ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Document.AssetsCalculation" );
list = With ( "Assets Calculations" );
Click ( "#FormListSettings" );
form = With ( "List Options" );
table = Activate ( "#SettingsComposerUserSettingsItem0Filter" );

count = Call ( "Table.Count", table );
for i = 1 to count - 1 do
	table.GotoLastRow ();
	Click ( "#" + table.Name + "Delete" );
enddo;

With ( form );

Click ( "#FormEndEdit" );

With ( list );
Click ( "#FormListSettings" );
form = With ( "List Options" );

table = Get ( "#SettingsComposerUserSettingsItem0Filter" );

Click ( "#SettingsComposerUserSettingsItem0FilterAddFilterItem" );

Put ( "Field", "Posted", table );
Put ( "Value", "Yes", table );

Click ( "#SettingsComposerUserSettingsItem0FilterAddFilterItem" );
Put ( "Field", "Date", table );
Put ( "Date", Format ( EndOfMonth ( date ), "DLF=DT" ), table );

Click ( "#FormEndEdit" );

With ( list );
table = Activate ( "#List" );
if ( Call ( "Table.Count", table ) = 0 ) then
	Click ( "#FormCreate" );
else
	Click ( "#FormChange" );	
endif;	

With ( "Assets Calculation *" );
Put ( "#Date", Format ( env.Date, "DLF=DT" ) );
Click ( "#FormPost" );
Run ( "Movements" + Month ( date ) );

// *************************
// Procedures
// *************************

Procedure writeOffAssets ( Env )

	p = Call ( "Documents.AssetsWriteOff.WriteOffAllAssets.Params" );	
	p.Date = EndOfMonth ( Env.Date );
	p.ExceptAssets = Env.FixedAssets;
	Call ( "Documents.AssetsWriteOff.WriteOffAllAssets", p );
	p.ExceptAssets = Env.IntangibleAssets;
	Call ( "Documents.IntangibleAssetsWriteOff.WriteOffAllAssets", p );

EndProcedure


