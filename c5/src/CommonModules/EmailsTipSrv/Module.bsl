Function BuildAddresses ( val Text, val OnlyAddresses = false ) export
	
	table = getAddresses ( Text, OnlyAddresses );
	if ( table.Count () = 0 ) then
		return undefined;
	endif; 
	result = new ValueList ();
	foundPart = new FormattedString ( Text, , StyleColors.SpecialTextColor );
	lowerText = Lower ( Text );
	textLen = StrLen ( Text );
	markLen = 1 + StrLen ( EmailsTip.GroupMark () );
	for each row in table do
		presentation = row.Presentation;
		if ( EmailsTip.Combined ( presentation ) ) then
			presentation = Mid ( presentation, markLen );
		endif; 
		parts = new Array ();
		while ( true ) do
			position = Find ( Lower ( presentation ), lowerText );
			if ( position = 0 ) then
				parts.Add ( presentation );
				break;
			elsif ( position > 1 ) then
				parts.Add ( Left ( presentation, position - 1 ) );
			endif; 
			parts.Add ( foundPart );
			presentation = Mid ( presentation, position + textLen );
		enddo;
		result.Add ( ? ( OnlyAddresses, row.Email, row.Presentation ), new FormattedString ( parts ) );
	enddo; 
	return result;
	
EndFunction 

Function getAddresses ( Text, OnlyAddresses )
	
	s = "
	|select distinct top 10 AddressBook.Presentation as Presentation, AddressBook.Used as Used";
	if ( OnlyAddresses ) then
		s = s + ", AddressBook.Email as Email";
	endif;
	s = s + "
	|from InformationRegister.AddressBook as AddressBook
	|where AddressBook.User = &User
	|and AddressBook.Presentation like &Text
	|order by AddressBook.Used desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Text", "%" + Text + "%" );
	q.SetParameter ( "User", SessionParameters.User );
	return q.Execute ().Unload ();
	
EndFunction 
