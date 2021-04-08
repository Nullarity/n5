// *****************************************
// *********** Table List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	choose ( SelectedRow );
	
EndProcedure

&AtClient
Procedure choose ( Value )
	
	if ( Value = undefined ) then
		return;
	endif;
	p = DF.Values ( Value, "Code, Description, DescriptionRu" );
	position = getPosition ( p );
	NotifyWritingNew ( position );
	NotifyChoice ( position );
	
EndProcedure 

&AtServerNoContext
Function getPosition ( val Params )
	
	code = Params.Code;
	ref = Catalogs.Positions.FindByAttribute ( "PositionCode", code );	
	if ( ref.IsEmpty () ) then
		obj = Catalogs.Positions.CreateItem ();
		obj.Description = Params.Description;
		obj.DescriptionRu = Params.DescriptionRu;
		obj.PositionCode = code;
		obj.Write ();
		return obj.Ref;
	else
		return ref;
	endif; 
	
EndFunction

&AtClient
Procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	choose ( Value );
	
EndProcedure
