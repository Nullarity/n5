#if ( Server ) then

Function IsIncoming ( Email, Box, Senders ) export
	
	boxes = Senders [ Box ];
	for i = 0 to Email.NumTo - 1 do
		address = Lower ( Email.GetToAddr ( i ) );
		if ( boxes.Find ( address ) <> undefined ) then
			return true;
		endif;
	enddo;
	for i = 0 to Email.NumCC - 1 do
		address = Lower ( Email.GetCcAddr ( i ) );
		if ( boxes.Find ( address ) <> undefined ) then
			return true;
		endif;
	enddo;
	for i = 0 to Email.NumBcc - 1 do
		address = Lower ( Email.GetBccAddr ( i ) );
		if ( boxes.Find ( address ) <> undefined ) then
			return true;
		endif;
	enddo;
	return false;
	
EndFunction 

Function GetID ( Email, Incoming ) export
	
	id = Email.GetHeaderField ( "Message-ID" );
	id = Mid ( id, 2, StrLen ( id ) - 2 );
	if ( Incoming or IsBlankString ( id ) ) then
		id = id + Email.EmailDateStr + Email.FromAddress + getTo ( Email ) + getCc ( Email );
	endif; 
	return Conversion.StringToHash ( id );
	
EndFunction 

Function getTo ( Email )
	
	bound = Email.NumTo - 1;
	list = new Array ();
	for i = 0 to bound do
		list.Add ( Email.GetToAddr ( i ) );
	enddo; 
	return StrConcat ( list, ", " );
	
EndFunction 

Function getCc ( Email )
	
	bound = Email.NumCC - 1;
	list = new Array ();
	for i = 0 to bound do
		list.Add ( Email.GetCcAddr ( i ) );
	enddo; 
	return StrConcat ( list, ", " );
	
EndFunction 

Function BriefBody ( Body ) export
	
	pattern = "(\r\n)|\t|\r|\n| ";
	return TrimAll ( Regexp.Replace ( Body, pattern, " " ) );

EndFunction 

Function Load ( Box, Profile, Email, Stream, AttachedEmails = undefined ) export
	
	obj = Create ();
	obj.Profile = Profile;
	obj.Email = Email;
	obj.Stream = Stream;
	obj.Box = Box;
	obj.AttachedEmails = AttachedEmails;
	return obj.Load ();
	
EndFunction 

#endif
