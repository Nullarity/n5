Function GetData ( Params ) export
	
	var schema;
	var composer;
	loadSchema ( Params, schema, composer );
	Reporter.ApplyFilters ( composer, Params );
	return putData ( Params.Report, Params.Variant, composer, schema, Params.Batch );
	
EndFunction

Procedure loadSchema ( Params, Schema, Composer )
	
	SetPrivilegedMode ( true );
	Schema = Reporter.GetSchema ( Params.Report );
	SetPrivilegedMode ( false );
	Composer = new DataCompositionSettingsComposer ();
	Composer.Initialize ( new DataCompositionAvailableSettingsSource ( Schema ) );
	Composer.LoadSettings ( schema.SettingVariants [ Params.Variant ].Settings );
	
EndProcedure 

Function putData ( Report, Variant, Composer, Schema, Batch )

	SetPrivilegedMode ( true );
	obj = prepareReport ( Report, Variant, Composer, Schema );
	p = obj.Params;
	events = p.Events;
	if ( events.OnCheck ) then
		cancel = false;
		obj.OnCheck ( cancel );
		if ( cancel ) then
			return undefined;
		endif; 
	endif; 
	applyChangedComposer ( p, Composer );
	if ( events.OnCompose ) then
		obj.OnCompose ();
	endif; 
	tcomposer = new DataCompositionTemplateComposer ();
	try
		template = tcomposer.Execute ( p.Schema, p.Settings, , ,
			Type ( "DataCompositionValueCollectionTemplateGenerator" ) );
	except
		Message ( BriefErrorDescription ( ErrorInfo () ) );
		return undefined;
	endtry;
	events = p.Events;
	if ( events.OnPrepare ) then
		obj.OnPrepare ( template );
	endif; 
	if ( Batch ) then
		q = prepareBatch ( template );
		p.Result = q.ExecuteBatch ();
		p.BatchQuery = q;
	else
		processor = new DataCompositionProcessor ();
		processor.Initialize ( template );
		builder = new DataCompositionResultValueCollectionOutputProcessor ();
		p.Result = new ValueTable ();
		builder.SetObject ( p.Result );
		builder.Output ( processor, false );
	endif; 
	if ( events.AfterOutput ) then
		obj.AfterOutput ();
	endif;
	return p.Result;
	
EndFunction

Function prepareReport ( Report, Variant, Composer, Schema )
 	
	obj = Reporter.Prepare ( Report );
	p = obj.Params;
	p.Variant = Variant;
	p.Schema = Schema;
	p.Composer = Composer;
	return obj;
	
EndFunction 

Procedure applyChangedComposer ( Params, Composer )
	
	Params.Settings = Composer.GetSettings ();
	
EndProcedure

Function prepareBatch ( Template )
	
	q = new Query ( template.DataSets [ 0 ].Query );
	SQL.DefineTempManager ( q );
	for each item in template.ParameterValues do
		q.SetParameter ( item.Name, item.Value );
	enddo; 
	CoreLibrary.AdjustQuery ( q );
	return q;
	
EndFunction 

Procedure StartProcess ( val Params, val Caller, ResultAddress ) export
	
	var schema;
	var composer;
	loadSchema ( Params, schema, composer );
	Reporter.ApplyFilters ( composer, Params );
	args = new Array ();
	args.Add ( Params.Report );
	args.Add ( Params.Variant );
	args.Add ( composer.GetSettings () );
	args.Add ( schema );
	ResultAddress = PutToTempStorage ( new ValueTable (), Caller );
	args.Add ( ResultAddress );
	args.Add ( Params.Batch );
	Jobs.Run ( "FillerSrv.Perform", args, Caller );
	
EndProcedure 

Procedure Perform ( Report, Variant, SettingsSource, Schema, ResultAddress, Batch ) export
	
	composer = getComposer ( SettingsSource, Schema );
	result = putData ( Report, Variant, composer, Schema, Batch );
	PutToTempStorage ( result, ResultAddress );
	
EndProcedure

Function getComposer ( SettingsSource, Schema )
	
	if ( TypeOf ( SettingsSource ) = Type ( "DataCompositionSettingsComposer" ) ) then
		return SettingsSource;
	else
		composer = new DataCompositionSettingsComposer ();
		composer.Initialize ( new DataCompositionAvailableSettingsSource ( Schema ) );
		composer.LoadSettings ( SettingsSource );
		return composer;
	endif;
	
EndFunction 
