// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setPrint ( Object );
	endif;
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setPrint ( Object )
	
	Object.Print = Object.Description;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure DescriptionOnChange ( Item )
	
	setPrint ( Object );
	
EndProcedure
