// *****************************************
// *********** Form events

&AtClient
Procedure OnOpen ( Cancel )
	
	init ();
	
EndProcedure

&AtClient
Procedure init ()
	
	Items.List.AdditionalCreateParameters = new FixedStructure (
		new Structure ( Enum.AdditionalPropertiesProposeEnrollment (), true ) );
	
EndProcedure