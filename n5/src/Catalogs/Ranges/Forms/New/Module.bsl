// *****************************************
// *********** Form events

&AtClient
Procedure OnOpen ( Cancel )
	
	applyParams ();
	
EndProcedure

&AtClient
Procedure applyParams ()
	
	p = new FixedStructure ( new Structure ( Enum.AdditionalPropertiesReceived (), Parameters.Received ) );
	Items.List.AdditionalCreateParameters = p;
	
EndProcedure
