
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	Output.LoadMetadata ( ThisObject );
	
EndProcedure

&AtClient
Procedure LoadMetadata ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		loadData ();
		NotifyChanged ( Type ( "CatalogRef.Metadata" ) );
		Output.MetadataLoadSuccessfully ();
	endif; 
	
EndProcedure 

&AtServer
Procedure loadData ()
	
	markAllMetadataNotFound ();
	loadMetadataObjects ();
	
EndProcedure

&AtServer
Procedure markAllMetadataNotFound ()
	
	BeginTransaction ();
	selection = Catalogs.Metadata.Select ();
	while ( selection.Next () ) do
		if ( selection.IsFolder ) then
			continue;
		endif; 
		obj = selection.GetObject ();
		obj.NotFound = true;
		obj.Write ();
	enddo; 
	CommitTransaction ();
	
EndProcedure
 
&AtServer
Procedure loadMetadataObjects ()
	
	classes = new Array ();
	classes.Add ( Metadata.ExchangePlans );
	classes.Add ( Metadata.Catalogs );
	classes.Add ( Metadata.Documents );
	classes.Add ( Metadata.Reports );
	classes.Add ( Metadata.DataProcessors );
	classes.Add ( Metadata.ChartsOfCharacteristicTypes );
	classes.Add ( Metadata.ChartsOfAccounts );
	classes.Add ( Metadata.BusinessProcesses );
	classes.Add ( Metadata.Tasks );
	classes.Add ( Metadata.Enums );
	classes.Add ( Metadata.InformationRegisters );
	classes.Add ( Metadata.AccumulationRegisters );
	classes.Add ( Metadata.AccountingRegisters );
	classes.Add ( Metadata.CalculationRegisters );
	classes.Add ( Metadata.DocumentJournals );
	classes.Add ( Metadata.Subsystems );
	BeginTransaction ();
	for each class in classes do
		for each element in class do
			Catalogs.Metadata.Ref ( element.FullName (), true );
		enddo; 
	enddo; 
	CommitTransaction ();
	
EndProcedure
