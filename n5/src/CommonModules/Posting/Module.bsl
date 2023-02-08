
Function GetParams ( Document = undefined, Registers = undefined, Properties = undefined ) export
	
	p = new Structure ();
	p.Insert ( "Ref", Document );
	p.Insert ( "Type", TypeOf ( Document ) );
	p.Insert ( "Document", ? ( Document = undefined, undefined, Metadata.FindByType ( TypeOf ( Document ) ).Name ) );
	p.Insert ( "Registers", Registers );
	p.Insert ( "Properties", Properties );
	p.Insert ( "RestoreCost", false );
	p.Insert ( "Reposted", false );
	p.Insert ( "Realtime", false );
	p.Insert ( "Interactive", true );
	SQL.Init ( p );
	return p;
	
EndFunction 

Function Msg ( Env, Keys = undefined ) export
	
	p = new Structure ( Keys );
	p.Insert ( Enum.AdditionalPropertiesInteractive (), Env.Interactive );
	return p;
	
EndFunction 

Procedure ClearRecords ( Registers ) export
	
	for each recordset in Registers do
		recordset.Clear ();
		recordset.Write = true;
	enddo; 
	
EndProcedure

Function Interactive ( Object ) export
	
	property = Enum.AdditionalPropertiesInteractive ();
	set = Object.AdditionalProperties;
	return not set.Property ( property ) or set [ property ];
	
EndFunction