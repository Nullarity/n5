#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Unload ( Params ) export
	
	processor ().Unload ( Params );
	
EndProcedure

Procedure Load ( Params ) export
	
	processor ().Load ( Params );
	
EndProcedure

Function processor ()
	
	return DataProcessors.ExchangeData.Create ();
	
EndFunction

Procedure RereadData () export
	
	Output.StartReReadData ();
	str = "
	|select top 1 Catalog.Ref as CatalogItem, Catalog.Node as Node, Catalog.FileMessage as FileMessage
	|from Catalog.Exchange as Catalog
	|where Catalog.Node = &MasterNode
	|";
	query = new Query ( str );
	query.SetParameter ( "MasterNode", ExchangePlans.MasterNode () );
	result = query.Execute ();
	if ( result.IsEmpty () ) then
		// ...
	else
		selection = result.Select ();
		selection.Next ();
		if ( selection.FileMessage <> "" ) then
			id = "";
			try
				fileXML = new File ( selection.FileMessage );
				id = Left ( Right ( fileXML.Path, 37 ), 36 );
			except
				return;
			endtry;
			Output.ExchangeLoadingAgain ( new Structure ( "Node, ID", selection.Node, id ) );
			p = new Structure ();
			p.Insert ( "Node", selection.CatalogItem );
			p.Insert ( "StartUp", false );
			p.Insert ( "Update", true );
			p.Insert ( "ID", id );
			Output.ReReadLoad ();
			Load ( p );
			Output.ReReadUnLoad ();
			UnLoad ( p );	
		endif;
	endif;
	Output.CloseCurrentSession ();
	Connections.DisconnectMe ();
	
EndProcedure

#endif