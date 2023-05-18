
&AtClient
Function GetEmailParams () export
	
	p = new Structure ();
	p.Insert ( "To" );
	p.Insert ( "Subject" );
	p.Insert ( "TableAddress" );
	p.Insert ( "TableDescription" );
	return p;
	
EndFunction 

&AtServer
Function TestAddress ( Address ) export
	
	return StrFind ( Address, "@" ) > 1;
	
EndFunction 

&AtServer
Function emailPattern ()
	
	return "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?";
	
EndFunction 

&AtServer
Function CheckAddresses ( Object, Field, DataPath = "Object" ) export
	
	addresses = Mailboxes.GetAddresses ( Object [ Field ] );
	if ( addresses = undefined ) then
		Output.InvalidEmail ( , Field, , DataPath );
		return false;
	endif; 
	return true;
	
EndFunction 

&AtServer
Function CheckName ( Object, Field, DataPath = "Object" ) export
	
	error = false;
	name = Object [ Field ];
	a = new Array ();
	a.Add ( EmailsTip.GroupMark () );
	a.Add ( EmailsTip.GroupSuffix () );
	a.Add ( EmailsTip.DblQuotes () );
	for each char in a do
		if ( StrFind ( name, char ) > 0 ) then
			error = true;
			break;
		endif; 
	enddo; 
	if ( error ) then
		Output.EmailDescriptionError ( new Structure ( "Chars", StrConcat ( a, ", " ) ), Field, , DataPath );
	endif; 
	return not error;
	
EndFunction 

&AtServer
Function GetNames ( Address ) export
	
	addresses = GetAddresses ( Address );
	if ( addresses = undefined ) then
		return "";
	endif; 
	result = "";
	for each pair in addresses do
		if ( pair.Name = "" ) then
			continue;
		endif; 
		result = result + ", " + pair.Name;
	enddo; 
	return Mid ( result, 3 );
	
EndFunction

&AtServer
Function GetAddresses ( Address ) export
	
	splitter1 = EmailsTip.Splitted1 ();
	splitter2 = EmailsTip.Splitted2 ();
	quotes = EmailsTip.DblQuotes ();
	pattern = quotes + "[^" + quotes + "]*" + quotes;
	matches = Regexp.Select ( Address, pattern );
	comma = "::*::";
	semicolon = "::**::";
	adjusted = Address;
	for each match in matches do
		found = match.Value;
		part = found;
		part = StrReplace ( part, splitter1, comma );
		part = StrReplace ( part, splitter2, semicolon );
		adjusted = StrReplace ( adjusted, found, part );
	enddo; 
	pattern = "(" + splitter1 + "|" + splitter2 + ")";
	s = Regexp.Replace ( adjusted, pattern, "," );
	pairs = Conversion.StringToArray ( s );
	result = new Array ();
	for each pair in pairs do
		matches = Regexp.Select ( pair, emailPattern () );
		if ( matches.Count () = 0 ) then
			return undefined;
		endif; 
		for each match in matches do
			email = match.Value;
		enddo; 
		name = TrimAll ( Regexp.Replace ( pair, emailCombination (), "" ) );
		name = TrimAll ( Regexp.Replace ( name, emailPattern (), "" ) );
		pattern = quotes + "([^" + quotes + "]*)" + quotes;
		if ( Regexp.Test ( name, pattern ) ) then
			name = quotes + TrimAll ( Regexp.Replace ( name, pattern, "$1" ) ) + quotes;
		endif; 
		name = StrReplace ( name, comma, splitter1 );
		name = StrReplace ( name, semicolon, splitter2 );
		result.Add ( new Structure ( "Name, Email", name, email ) );
	enddo; 
	return result;
	
EndFunction 

&AtServer
Function emailCombination ()
	
	return "[\(<'""]" + emailPattern () + "(([\)>'""])|[\)>'""])";
	
EndFunction 

&AtServer
Procedure SetByDefault ( Mailbox ) export
	
	settings = Logins.Settings ( "Ref" ).Ref.GetObject ();
	settings.Mailbox = Mailbox;
	settings.Write ();
	
EndProcedure 

&AtServer
Procedure AddAddress ( Email, Name ) export
	
	if ( not Mailboxes.TestAddress ( Email ) ) then
		return;
	endif; 
	presentation = buildPresentation ( Email, Name );
	r = InformationRegisters.AddressBook.CreateRecordManager ();
	r.User = SessionParameters.User;
	r.Email = Email;
	r.Read ();
	if ( r.Selected () ) then
		if ( Name <> "" and r.Presentation <> presentation ) then
			r.Presentation = presentation;
		endif; 
	else
		r.User = SessionParameters.User;
		r.Email = Email;
		r.Presentation = presentation;
	endif; 
	r.Used = CurrentSessionDate ();
	r.Write ();
	
EndProcedure 

&AtServer
Function buildPresentation ( Email, Name )
	
	fixedName = adjustName ( Name );
	addresses = GetAddresses ( Email );
	if ( addresses = undefined ) then
		return Email;
	endif;
	if ( addresses.Count () = 1 ) then
		pair = addresses [ 0 ];
		return GetAddressPresentation ( pair.Email, ? ( pair.Name = "", fixedName, pair.Name ) );
	else
		group = new Array ();
		for each pair in addresses do
			group.Add ( GetAddressPresentation ( pair.Email, pair.Name ) );
		enddo; 
		list = StrConcat ( group, ", " );
		if ( fixedName = "" ) then
			return list;
		else
			title = EmailsTip.GroupMark () + fixedName + EmailsTip.GroupSuffix () + " ";
			return title + list;
		endif; 
	endif; 
	
EndFunction 

&AtServer
Function adjustName ( Name )
	
	if ( StrFind ( Name, EmailsTip.Splitted1 () ) = 0
		and StrFind ( Name, EmailsTip.Splitted2 () ) = 0 ) then
		return Name;
	else
		quotes = EmailsTip.DblQuotes ();
		return quotes + TrimAll ( Name ) + quotes;
	endif; 

EndFunction 

Function GetAddressPresentation ( Email, Name, Full = true ) export
	
	if ( IsBlankString ( Name ) ) then
		return Email;
	else
		if ( Full ) then
			return Name + " <" + Email + ">";
		else
			return name;
		endif; 
	endif; 
	
EndFunction 

&AtServer
Function SystemMailReady () export
	
	SetPrivilegedMode ( true );
	return Cloud.SMTPServer () <> ""
	and Cloud.SMTPUser () <> "";
	
EndFunction