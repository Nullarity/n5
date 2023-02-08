// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	MasterNode = ( ExchangePlans.MasterNode () = undefined );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|List show filled ( TenantFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	setEnableCommands ();
	
EndProcedure

&AtClient
Procedure setEnableCommands ()
	
	if ( Items.List.CurrentData = undefined ) then
		value = false;
	else
		value = not Items.List.CurrentData.ThisNode;
	endif;
	Items.UnloadHandle.Enabled = value;
	Items.UnloadJob.Enabled = value;
	Items.LoadHandle.Enabled = value;
	Items.LoadJob.Enabled = value;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure EditSettings ( Command )
	
	OpenForm ( "Catalog.Exchange.Form.EditSettings" );
	
EndProcedure

&AtClient
Procedure runProcess ( Command )
	
	if ( Items.List.CurrentData = undefined ) then
		return;
	endif;
	if ( MasterNode ) then
		webService = checkOperationType ( Items.List.CurrentRow );
		if ( webService ) then
			Output.MasterNode ();
			return;
		endif;
	endif; 
	p = new Structure ( "ProcessName, Node", Command.Name, Items.List.CurrentRow ); 
	runProcessServer ( p );	
	
EndProcedure

&AtServerNoContext
function checkOperationType ( Ref )
	
	return  ( Ref.OperationType = Enums.ExchangeTypes.WebService );  

endfunction 

&AtServerNoContext 
Procedure runProcessServer ( Params )
	
	Catalogs.Exchange.RunProcess ( Params );	
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure TenantFilterOnChange ( Item )
	
	applyTenant ();
	
EndProcedure

&AtServer
Procedure applyTenant ()
	
	activateTenant ();
	Appearance.Apply ( ThisObject, "TenantFilter" );
	Items.List.Refresh ();
	if ( not TenantFilter.IsEmpty () ) then
		update ();	
	endif; 

EndProcedure 

&AtServer
Procedure activateTenant ()
	
	if ( TenantFilter = SessionParameters.Tenant ) then
		return;
	endif;
	SessionParameters.Tenant = TenantFilter;
	SessionParameters.TenantUse = not TenantFilter.IsEmpty ();
	
EndProcedure 

&AtServer
Procedure update ()
	
	s = "
	|select top 1 Catalog.Ref as CatalogItem, Catalog.Node as Node, Catalog.FileMessage as FileMessage
	|from Catalog.Exchange as Catalog
	|where Catalog.Node = &MasterNode
	|";
	query = new Query ( s );
	query.SetParameter ( "MasterNode", ExchangePlans.MasterNode () );
	table = query.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return;
	endif;
	data = table [ 0 ];
	if ( data.FileMessage = "" ) then
		return;
	endif;
	id = "";
	try
		fileXML = new File ( data.FileMessage );
		id = Left ( Right ( fileXML.Path, 37 ), 36 );
	except
		return;
	endtry;
	Output.ExchangeLoadingAgain ( new Structure ( "Node, ID", data.Node, id ) );
	p = new Structure ( "Node, StartUp, Update, ID", data.CatalogItem, false, true, id );
	DataProcessors.ExchangeData.Load ( p );
	
EndProcedure

&AtClient
Procedure ListOnActivateRow ( Item )
	
	setEnableCommands ();	
	
EndProcedure
