#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	if ( isMaster ( Parameters ) ) then
		SelectedForm = Metadata.Catalogs.Reports.Forms.Master;
		StandardProcessing = false;
	endif; 
	
EndProcedure

Function isMaster ( Parameters )
	
	if ( Parameters.Property ( "IsFolder" )
		and Parameters.IsFolder ) then
		return false;
	endif; 
	master =
	( Parameters.Property ( "FillingValues" )
		and Parameters.FillingValues.Property ( "Master" )
		and Parameters.FillingValues.Master )
	or ( Parameters.Property ( "Key" )
		and DF.Pick ( Parameters.Key, "Master" ) )
	or ( Parameters.Property ( "CopyingValue" )
		and DF.Pick ( Parameters.CopyingValue, "Master" ) );
	return master;
	
EndFunction 

Procedure CopyInternals ( Source, Destination ) export
	
	Destination.Program = new ValueStorage ( Source.Program.Get () );
	Destination.Template = new ValueStorage ( Source.Template.Get () );
	Destination.Exporter = new ValueStorage ( Source.Exporter.Get () );
	
EndProcedure 

Procedure CopyFields ( Source, Destination ) export
	
	from = InformationRegisters.FieldsDependency.Select ( new Structure ( "Report", Source ) );
	set = InformationRegisters.FieldsDependency.CreateRecordSet ();
	set.Filter.Report.Set ( Destination );
	while ( from.Next () ) do
		r = set.Add ();
		r.Report = Destination;
		r.Field = from.Field;
		r.DependentReport = Destination;
		r.DependentField = from.DependentField;
	enddo; 
	set.Write ();
	
EndProcedure 

#endif