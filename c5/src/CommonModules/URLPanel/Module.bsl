
Function DocumentsToURL ( Table, Label = undefined ) export
	
	j = Table.Count () - 1;
	if ( j < 0 ) then
		return undefined;
	endif; 
	parts = new Array ();
	if ( Label <> undefined ) then
		parts.Add ( getLabel ( Label ) + ": " );
	endif; 
	p = new Structure ( "Number, Date" );
	for i = 0 to j do
		row = Table [ i ];
		p.Number = Print.ShortNumber ( row.Number );
		p.Date = Conversion.DateToString ( row.Date );
		parts.Add ( new FormattedString ( Output.DateNumber ( p ), , , , GetURL ( row.Document ) ) );
		if ( i < j ) then
			parts.Add ( ", " );
		endif; 
	enddo; 
	return new FormattedString ( parts );
	
EndFunction 

Function getLabel ( Label )
	
	labeType = TypeOf ( Label );
	if ( labeType = Type ( "String" ) ) then
		return Label;
	else
		presentation = "";
		if ( Metadata.Documents.Contains ( Label ) ) then
			presentation = Label.ListPresentation;
		endif; 
		return ? ( presentation = "", Label.Presentation (), presentation );
	endif; 
	
EndFunction 

Function Build ( Parts ) export
	
	return CoreLibrary.BuildPanel ( Parts );
	
EndFunction 
