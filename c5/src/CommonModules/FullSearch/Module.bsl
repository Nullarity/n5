
Function List ( Search, Scope, Limit = 10 ) export
	
	request = prepareRequest ( Search );
	list = getList ( request.Template, Scope, Limit );
	if ( list = undefined ) then
		return undefined;
	endif; 
	result = new ValueList ();
	highlights = request.Highlights;
	for each response in list do
		foundText = extractResult ( response );
		item = result.Add ();
		item.Value = response.Value;
		item.Presentation = ? ( highlights = undefined, foundText, highlight ( foundText, highlights ) );
	enddo; 
	return result;
	
EndFunction 

Function prepareRequest ( Search )
	
	template = "";
	highlights = new Array ();
	parts = Conversion.StringToArray ( Search, " " );
	for each part in parts do
		if ( IsBlankString ( part ) ) then
			continue;
		endif; 
		template = template + part;
		if ( isWord ( part ) ) then
			template = template + "*";
			highlights.Add ( part );
		endif; 
		template = template + " ";
	enddo; 
	Collections.Sort ( highlights );
	result = new Structure ( "Template, Highlights" );
	result.Template = TrimAll ( template );
	result.Highlights = highlights;
	return result;
	
EndFunction 

Function isWord ( Word )
	
	if ( StrLen ( Word ) < 3 ) then
		return false;
	endif; 
	if ( isReserved ( Word ) ) then
		return false;
	endif; 
	leftChar = Left ( Word, 1 );
	rightChar = Right ( Word, 1 );
	symbols = """()-+?/\|*!#:<>[]{},`~";
	return not ( Find ( symbols, leftChar ) > 0
			or Find ( symbols, rightChar ) > 0 );
	
EndFunction 

Function isReserved ( Word )
	
	s = Upper ( Word );
	return s = "AND"
	or s = "OR"
	or s = "NOT"
	or s = "NEAR"
	or s = "И"
	or s = "ИЛИ"
	or s = "НЕ"
	or s = "РЯДОМ";
	
EndFunction 

Function getList ( Search, Scope, Limit )
	
	list = firstPart ( Search, Scope );
	if ( list = undefined ) then
		return undefined;
	endif;
	result = new Array ();
	found = 0;
	count = 0;
	while ( true ) do
		total = list.TotalCount ();
		finish = true;
		for each response in list do
			count = count + 1;
			finish = false;
			value = response.Value;
			if ( result.Find ( value ) = undefined ) then
				result.Add ( response );
				found = found + 1;
				if ( found = Limit ) then
					finish = true;
					break;
				endif;
			endif;
		enddo; 
		if ( finish
			or count >= total ) then
			break;
		else
			list.NextPart ();
		endif;
	enddo;
	return result;
	
EndFunction 

Function firstPart ( Search, Scope )
	
	list = FullTextSearch.CreateList ( Search );
	list.PortionSize = 50;
	if ( Scope = Enums.Search.Incoming ) then
		list.SearchArea.Add ( Metadata.Documents.IncomingEmail );
	elsif ( Scope = Enums.Search.Outgoing ) then
		list.SearchArea.Add ( Metadata.Documents.OutgoingEmail );
	elsif ( Scope = Enums.Search.Mail ) then
		list.SearchArea.Add ( Metadata.Documents.IncomingEmail );
		list.SearchArea.Add ( Metadata.Documents.OutgoingEmail );
	endif; 
	try
		list.FirstPart ();
	except
		return undefined;
	endtry;
	if ( list.Count () = 0 ) then
		return undefined;
	endif; 
	if ( list.TooManyResults ()  ) then
		return undefined;
	endif; 
	return list;
	
EndFunction

Function extractResult ( Response )
	
	if ( IsBlankString ( Response.Description ) ) then
		s = Response.Presentation;
	else
		s = Response.Description;
	endif; 
	j = StrLineCount ( s );
	a = new Array ();
	for i = 1 to j do
		row = StrGetLine ( s, i );
		if ( not IsBlankString ( row ) ) then
			a.Add ( row );
		endif; 
	enddo; 
	return StrConcat ( a, " " );
	
EndFunction

Function highlight ( Text, Highlights )
	
	parts = Conversion.StringToArray ( Text, " " );
	result = new Array ();
	for each part in parts do
		source = Lower ( part );
		sourceSize = StrLen ( source );
		found = false;
		for each word in Highlights do
			foundPart = new FormattedString ( word, , StyleColors.SpecialTextColor );
			i = Find ( source, Lower ( word ) );
			if ( i = 0 ) then
				continue;
			else
				if ( i > 1 ) then
					result.Add ( Mid ( part, 1, i - 1 ) );
				endif; 
				result.Add ( foundPart );
				wordSize = StrLen ( word );
				j = i + wordSize;
				if ( j <= sourceSize ) then
					result.Add ( Mid ( part, j ) );
				endif;
				found = true;
				break;
			endif; 
		enddo; 
		if ( not found ) then
			result.Add ( part );
		endif; 
		result.Add ( " " );
	enddo; 
	return new FormattedString ( result );
	
EndFunction 

Function Refs ( Search, Scope, Limit = 100 ) export
	
	request = prepareRequest ( Search );
	list = getList ( request.Template, Scope, Limit );
	if ( list = undefined ) then
		return undefined;
	endif; 
	result = new Array ();
	for each response in list do
		result.Add ( response.Value );
	enddo; 
	return result;
	
EndFunction 

Procedure Background ( Search, Scope, Storage, LastID ) export
	
	job = Jobs.GetByID ( LastID );
	if ( job <> undefined ) then
		job.Cancel ();
	endif; 
	result = FullSearch.Refs ( Search, Scope );
	PutToTempStorage ( result, Storage );
	
EndProcedure
