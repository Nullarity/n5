&AtClient
Procedure ShowFull ( Text, ChoiceData, StandardProcessing ) export
	
	proposeEmails ( Text, ChoiceData, StandardProcessing, false );
	
EndProcedure 

&AtClient
Procedure proposeEmails ( Text, ChoiceData, StandardProcessing, OnlyAddresses )
	
	if ( textIsShort ( Text ) ) then
		return;
	endif; 
	ChoiceData = EmailsTipSrv.BuildAddresses ( Text, OnlyAddresses );
	if ( ChoiceData <> undefined ) then
		StandardProcessing = false;
	endif; 
	
EndProcedure 

&AtClient
Function textIsShort ( Text )
	
	return StrLen ( Text ) < 1;
	
EndFunction

&AtClient
Procedure ShowShort ( Text, ChoiceData, StandardProcessing ) export
	
	proposeEmails ( Text, ChoiceData, StandardProcessing, true );
	
EndProcedure 

&AtClient
Procedure FixEmail ( Choice ) export
	
	if ( EmailsTip.Combined ( Choice ) ) then
		suffix = EmailsTip.GroupSuffix () + " ";
		i = StrFind ( Choice, suffix, , 1 + StrLen ( EmailsTip.GroupMark () ) );
		Choice = Mid ( Choice, i + StrLen ( suffix ) );
	endif; 
	
EndProcedure 

Function Combined ( Email ) export
	
	return StrStartsWith ( Email, EmailsTip.GroupMark () ) > 0;
	
EndFunction 

Function GroupMark () export
	
	return "::";
	
EndFunction 

Function GroupSuffix () export
	
	return ":";
	
EndFunction 

&AtServer
Function DblQuotes () export
	
	return """";
	
EndFunction 

&AtServer
Function Splitted1 () export
	
	return ",";
	
EndFunction 

&AtServer
Function Splitted2 () export
	
	return ";";
	
EndFunction 
