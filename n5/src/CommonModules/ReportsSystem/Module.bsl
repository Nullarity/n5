Procedure Form ( Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing ) export
	
	#if ( Server ) then
		if ( FormType <> "Form" ) then
			return;
		endif;
		reportName = Metadata.FindByType ( TypeOf ( Source ) ).Name;
		if ( nonStandardReport ( reportName ) ) then
			return;
		endif; 
		StandardProcessing = false;
		setParams ( Parameters, ReportName );
		class = Reports [ ReportName ];
		if ( class.Events ().OnInitDefaultParams ) then
			class.OnInitDefaultParams ( Parameters );
		endif; 
		SelectedForm = Metadata.Reports.Common.Forms.Form;
	#endif
	
EndProcedure

#if ( Server ) then
	
Function nonStandardReport ( ReportName )

	reps = "Common, Records";
	return Find ( reps, ReportName ) > 0;
	
EndFunction 

#endif

Procedure setParams ( Params, ReportName )
	
	Params.Insert ( "ReportName", ReportName );
	Params.Insert ( "Command", "OpenReport" );
	Params.Insert ( "Filters" );
	Params.Insert ( "Parent" );
	Params.Insert ( "Variant" );
	Params.Insert ( "Settings" );
	Params.Insert ( "GenerateOnOpen", false );
	
EndProcedure

Function GetParams ( ReportName ) export
	
	p = new Structure ();
	setParams ( p, ReportName );
	return p;
	
EndFunction
