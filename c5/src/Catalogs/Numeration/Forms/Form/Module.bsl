// *****************************************
// *********** Form events

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	SetPrivilegedMode ( true );
	RefreshObjectsNumbering ( Metadata.Catalogs.Numeration );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DescriptionOnChange ( Item )
	
	if ( Object.Ref.IsEmpty ()
		and IsBlankString ( Object.Code ) ) then
		setNewCode ();
	else
		setCode ();
	endif;
	
EndProcedure

&AtClient
Procedure setNewCode () 

	description = Object.Description;
	zeros = "";
	for i = 1 + StrLen ( description ) to getLength () do
		zeros = zeros + "0";
	enddo;
	Object.Code = description + zeros;
	
EndProcedure

&AtServerNoContext
Function getLength ( Code = true ) 

	if ( Code ) then
		return Metadata.Catalogs.Numeration.CodeLength;
	else
		return Metadata.Catalogs.Numeration.DescriptionLength;
	endif;

EndFunction

&AtClient
Procedure setCode () 

	prefix = Object.Description + "";
	descriptionLength = getLength ( false );
	for i = 1 + StrLen ( prefix ) to descriptionLength do
		prefix = prefix + "0";
	enddo;
	code = TrimAll ( Object.Code );
	Object.Code = prefix + Right ( code, StrLen ( code ) - descriptionLength );
	
EndProcedure


