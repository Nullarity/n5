&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	CurrentTenant = SessionParameters.Tenant;
	if ( CurrentTenant.IsEmpty () ) then
		Items.List.ReadOnly = true;
		return;
	endif;
	CurrentID = DF.Pick ( SessionParameters.Tenant, "Code" );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|#s FormCreate show filled ( CurrentTenant );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	forceActivation ();
	
EndProcedure

&AtClient
Procedure forceActivation ()
	
	if ( Parameters.ForceActivation ) then
		Restart = true;
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ActivateTenant ( Command )
	
	startActivation ();
	
EndProcedure

&AtClient
Procedure startActivation ()

	id = TableRow.Code;
	connection = InfoBaseConnectionString ();
	#if ( WebClient ) then
		address = StrReplace ( connection, CurrentID, id );
		prefix = 5;
		address = Mid ( address, prefix, StrLen ( address ) - prefix );
		GotoURL ( address );
		Close ();
	#elsif ( not MobileClient ) then
		parameter = "/Z" + id;
		showAccessDialog = NewUser or Parameters.ForceActivation or ( TableRow.Ref = CurrentTenant ); 
		if ( showAccessDialog ) then
			parameter = parameter + " /N";
		endif;
		if ( Restart ) then
			Exit ( , true, parameter );
		else
			RunSystem ( parameter );
			Close ();
		endif;
	#endif

EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListOnActivateRow ( Item )

	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	StandardProcessing = false;
	startActivation ();
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	OpenForm ( "Catalog.Tenants.Form.New", , ThisObject );
	
EndProcedure
