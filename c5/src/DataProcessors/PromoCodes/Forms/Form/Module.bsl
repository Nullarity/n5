// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setIssueDate ();
	
EndProcedure

&AtServer
Procedure setIssueDate ()
	
	Object.IssueDate = CurrentSessionDate ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Generate ( Command )
	
	Output.GeneratePromoCodesConfirmation ( ThisObject );
	
EndProcedure

&AtClient
Procedure GeneratePromoCodesConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( not CheckFilling () ) then
		return;
	endif; 
	generateCodes ();
	
EndProcedure 

&AtServer
Procedure generateCodes ()
	
	BeginTransaction ();
	Codes.Clear ();
	t = DataProcessors.PromoCodes.GetTemplate ( "Template" );
	Codes.Put ( t.GetArea ( "Header" ) );
	area = t.GetArea ( "Row" );
	agentTenant = DF.Pick ( Object.Agent, "Tenant" );
	for i = 1 to Object.Count do
		obj = Catalogs.PromoCodes.CreateItem ();
		FillPropertyValues ( obj, Object );
		obj.Code = getCode ();
		obj.Parent = Object.Folder;
		obj.AgentTenant = agentTenant;
		obj.Write ();
		area.Parameters.Fill ( obj );
		Codes.Put ( area );
	enddo; 
	CommitTransaction ();
	
EndProcedure 

&AtServer
Function getCode ()
	
	code = Upper ( Left ( StrReplace ( new UUID (), "-", "" ), 9 ) );
	if ( Catalogs.PromoCodes.FindByCode ( code ).IsEmpty () ) then
		return code;
	else
		return getCode ();
	endif; 
	
EndFunction 
