
// *****************************************
// *********** Form events

&AtClient
Procedure OnOpen ( Cancel )
	
	AmountEn = 9561.83;
	AmountRo = AmountEn;
	AmountRu = AmountEn;
	setExampleRo ();
	setExampleRu ();
	setExampleEn ();
	
EndProcedure

&AtClient
Procedure setExampleRo () 

	InWordsRo = NumberInWords ( AmountRo, "L=ro_Ro; FS=false", Object.OptionsRo );

EndProcedure

&AtClient
Procedure setExampleRu () 

	InWordsRu = NumberInWords ( AmountRu, "L=ru_RU; FS=false", Object.OptionsRu );

EndProcedure

&AtClient
Procedure setExampleEn () 

	InWordsEn = NumberInWords ( AmountEn, "L=en_En; FS=false", Object.OptionsEn );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OptionsRoOnChange ( Item )
	
	setOptionsRo ();
	setExampleRo ();
	
EndProcedure

&AtClient
Procedure setOptionsRo () 

	Object.OptionsRo = TrimAll ( Object.SingularIntRo ) + ", " + TrimAll ( Object.PlurarIntRo ) + ", " + gender ( Object.GenderIntRo ) + ", " 
	+ TrimAll ( Object.SingularFractionalRo ) + ", " + TrimAll ( Object.PlurarFractionalRo ) + ", " + gender ( Object.GenderFractionalRo );

EndProcedure

&AtClient
Function gender ( Gender ) 

	return ? ( Gender = PredefinedValue ( "Enum.Sex.Male" ), "M", "W" );

EndFunction

&AtClient
Procedure OptionsEnOnChange ( Item )
	
	setOptionsEn ();
	setExampleEn ();
	
EndProcedure

&AtClient
Procedure setOptionsEn () 

	Object.OptionsEn = TrimAll ( Object.SingularIntEn ) + ", " + TrimAll ( Object.PlurarIntEn ) + ", " + TrimAll ( Object.SingularFractionalEn ) 
	+ ", " + TrimAll ( Object.PlurarFractionalEn );

EndProcedure

&AtClient
Procedure AmountRoOnChange ( Item )
	
	setExampleRo ();
	
EndProcedure

&AtClient
Procedure AmountEnOnChange ( Item )
	
	setExampleEn ();
	
EndProcedure

&AtClient
Procedure OptionsRuOnChange ( Item )
	
	setOptionsRu ();
	setExampleRu ();
	
EndProcedure

&AtClient
Procedure setOptionsRu () 

	Object.OptionsRu = TrimAll ( Object.NominativeIntRu ) + ", " + TrimAll ( Object.SingularIntRu ) + ", " 
	+ TrimAll ( Object.PlurarIntRu ) + ", " + Object.GenderIntRu + ", " + TrimAll ( Object.NominativeFractionalRu ) + ", " 
	+ TrimAll ( Object.SingularFractionalRu ) + ", " + TrimAll ( Object.PlurarFractionalRu ) + ", " + Object.GenderFractionalRu;

EndProcedure

&AtClient
Procedure AmountRuOnChange ( Item )
	
	setExampleRu ();
	
EndProcedure
