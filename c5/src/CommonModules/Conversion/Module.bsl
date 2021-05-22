Function ValueToString ( Value ) export
	
	return ? ( ValueIsFilled ( Value ), String ( Value ), "<...>" );

EndFunction

Function ValuesToString ( Value1 = undefined, Value2 = undefined, Value3 = undefined, Value4 = undefined ) export
	
	parts = new Array ();
	if ( ValueIsFilled ( Value1 ) ) then
		parts.Add ( Value1 );
	endif;
	if ( ValueIsFilled ( Value2 ) ) then
		parts.Add ( Value2 );
	endif;
	if ( ValueIsFilled ( Value3 ) ) then
		parts.Add ( Value3 );
	endif;
	if ( ValueIsFilled ( Value4 ) ) then
		parts.Add ( Value4 );
	endif;
	return StrConcat ( parts, ", " );

EndFunction

Function DescriptionToCode ( Description ) export
	
	code = Mid ( Description, 2 );
	exceptions = "eyuioaйуеыаояиёэьъю.-+@#&* :()[]{}""'%^|\/<>`~";
	count = StrLen ( exceptions );
	for i = 1 to count do
		code = StrReplace ( code, Mid ( exceptions, i, 1 ), "" );
	enddo; 
	return Upper ( Left ( Description, 1 ) + code );
	
EndFunction 

&AtServer
Function DimsToString ( Account, Dim1, Dim2, Dim3 ) export
	
	values = new Array ();
	count = ServerCache.DimsCount ( Account );
	if ( count > 0 ) then
		values.Add ( Conversion.ValueToString ( Dim1 ) );
	endif; 
	if ( count > 1 ) then
		values.Add ( Conversion.ValueToString ( Dim2 ) );
	endif; 
	if ( count > 2 ) then
		values.Add ( Conversion.ValueToString ( Dim3 ) );
	endif; 
	return StrConcat ( values, ", " );

EndFunction 
 
Function NumberToMoney ( Number, Currency = "USD" ) export
	
	return Format ( Number, "NFD=2; NZ=" ) + " " + Currency;
	
EndFunction

Function NumberToQuantity ( Number, Package = undefined ) export
	
	value = Round ( Number, 3 );
	if ( Package = undefined ) then
		return Format ( value, Application.Accuracy () );
	else
		return Format ( value, "NZ=0;" + Application.Accuracy () ) + " " + Package;
	endif; 
	
EndFunction

Function MinutesToDuration ( Minutes ) export
	
	if ( Minutes = 0 or Minutes = null ) then
		return 0;
	endif; 
	return Round ( Int ( Minutes / 60 ) + 0.01 * ( Minutes % 60 ), 2 );
	
EndFunction

Function DurationToMinutes ( Duration ) export
	
	hours = Int ( Duration );
	minutes = ( Duration - hours ) * 100;
	return hours * 60 + minutes;
	
EndFunction

Function MinutesToString ( Minutes ) export
	
	days = Int ( Minutes / 1440 );
	span = days * 1440;
	hours = Int ( ( Minutes - span ) / 60 );
	span = span + hours * 60;
	mins = Minutes - span;
	parts = new Array ();
	if ( days > 0 ) then
		parts.Add ( Format ( days, "NG=0" ) + Output.TimeDay () );
	endif;	
	if ( hours > 0 ) then
		parts.Add ( Format ( hours, "NG=0" ) + Output.TimeHour () );
	endif;
	if ( mins > 0 ) then
		parts.Add ( "" + mins + Output.TimeMinute () );
	endif; 
	return StrConcat ( parts );
	
EndFunction 

&AtClient
Procedure AdjustTime ( Duration ) export
	
	hours = Int ( Duration );
	minutes = Duration - hours;
	if ( minutes >= 0.6 ) then
		Duration = hours + 1 + ( minutes - 0.6 );
	endif; 
	
EndProcedure 

Function DateToString ( D, StringFormat = "DLF=D; DE=..." ) export

	return Format ( D, StringFormat );

EndFunction

&AtServer
Function DateToTime ( Date ) export

	return CoreLibrary.DateToTime ( Date );

EndFunction

Function StringToArray ( String, Separator = "," ) export
	
	a = StrSplit ( String, Separator, false );
	j = a.UBound ();
	for i = 0 to j do
		a [ i ] = TrimAll ( a [ i ] );
	enddo; 
	return a;
	
EndFunction

Function findMinPos ( Str, CharsFind )
	
	minPosResult = 0;
	findCharsLen = StrLen ( CharsFind );
	// Find equal pos
	if ( findCharsLen = 1 ) then
		minPosResult = Find ( Str, CharsFind );
	else
		for i = 1 To findCharsLen do
			equalPosCur = Find ( Str, Mid ( CharsFind, i, 1 ) );
			if ( minPosResult = 0 ) or ( ( equalPosCur < minPosResult ) and ( equalPosCur <> 0 ) ) then
				minPosResult = equalPosCur;
			endif;
		enddo;
	endif;	
	return minPosResult;
	
EndFunction

Function StringToStructure ( StringValue, EqualChars = "=:", SplitteChars = ",;" ) export
	
	resultSructure = new Structure;
	templateStr = StringValue;	
	while ( not IsBlankString ( templateStr ) ) do
		equalPos = findMinPos ( templateStr, EqualChars );
		splitePos = findMinPos ( templateStr, SplitteChars );
		equalPos = ? ( ( equalPos > splitePos ) and splitePos, 0, equalPos ); // "a;b=0"
		if ( equalPos = 0 ) and ( splitePos = 0 ) then // "a"
			keyStructure = templateStr;
			valueStructure = "";
			templateStr = "";
		elsif ( equalPos = 0 ) or ( splitePos = 0 ) then // "a;..." or "a=0"
			keyStructure = Left ( templateStr, max ( equalPos, splitePos ) - 1 );
			valueStructure = ? ( equalPos = 0, "", Mid ( templateStr, equalPos + 1 ) );
			templateStr = ? ( splitePos = 0, "", Mid ( templateStr, splitePos + 1 ) );
		else // "a=0;..."
			keyStructure = Left ( templateStr, min ( equalPos, splitePos ) - 1 );
			valueStructure = Mid ( templateStr, equalPos + 1, splitePos - equalPos - 1 );
			templateStr = Mid ( templateStr, splitePos + 1 );
		endif;
		if ( IsBlankString ( keyStructure ) ) then
			continue;
		endif; 
		resultSructure.Insert ( StrReplace ( keyStructure, " ", "" ), valueStructure );
	enddo;
	return resultSructure;
	
EndFunction

&AtServer
Function RowToStructure ( Table ) export
	
	row = ? ( Table.Count () = 0, undefined, Table [ 0 ] );
	result = new Structure ();
	columns = Table.Columns;
	if ( row = undefined ) then
		for each column in columns do
			result.Insert ( column.Name );
		enddo; 
	else
		for each column in columns do
			result.Insert ( column.Name, row [ column.Name ] );
		enddo; 
	endif; 
	return result;
	
EndFunction 

&AtServer
Function StringToHash ( Str ) export
	
	hash = new DataHashing ( HashFunction.SHA256 );
	hash.Append ( Str );
	return StrReplace ( String ( hash.HashSum ), " ", "" );
	
EndFunction 

&AtServer
Function EnumItemToName ( EnumItem ) export
	
	if ( EnumItem.IsEmpty () ) then
		return undefined;
	endif; 
	meta = EnumItem.Metadata ();
	index = Enums [ meta.Name ].IndexOf ( EnumItem );
	return meta.EnumValues [ index ].Name;
	
EndFunction

Procedure Wait ( Seconds ) export
	
	start = CurrentDate () + Seconds;
	while ( true ) do
		if ( CurrentDate () > start ) then
			break;
		endif; 
	enddo; 

EndProcedure

&AtServer
Function ShrinkNumber ( DocumentNumber ) export
	
	try
		s = Number ( DocumentNumber );
	except
		s = DocumentNumber;
	endtry;
	return s;
	
EndFunction 

&AtServer
Function XMLToStandard ( val Text ) export
	
	position = FindDisallowedXMLCharacters ( Text );
	while ( position > 0 ) do
		Text = StrReplace ( Text, Mid ( Text, position, 1 ), "" );
		position = FindDisallowedXMLCharacters ( text );
	enddo;
	return Text;
	
EndFunction

&AtServer
Function ToXML ( Object ) export
	
	xml = new XMLWriter ();
	xml.SetString ( "UTF-8" );
	xml.WriteXMLDeclaration ();
	XDTOSerializer.WriteXML ( xml, Object );
	return xml.Close ();
	
EndFunction 

&AtServer
Function FromXML ( XML ) export
	
	reader = new XMLReader ();
	reader.SetString ( XML );
	return XDTOSerializer.ReadXML ( reader );
	
EndFunction 

#if ( not WebClient ) then
	
Function ToJSON ( Params ) export
	
	writer = new JSONWriter ();
	writer.SetString ( new JSONWriterSettings ( JSONLineBreak.None ) );
	WriteJSON ( writer, Params );
	return writer.Close ();
	
EndFunction 

Function FromJSON ( JSON ) export
	
	reader = new JSONReader ();
	reader.SetString ( JSON );
	return ReadJSON ( reader );
		
EndFunction 

#endif

Function BytesToSize ( Size ) export
	
	kb = Size / 1024;
	if ( kb >= 1024 ) then
		mb = Round ( kb / 1024, 2 );
		return String ( mb ) + " " + Output.Megabyte ();
	else
		return Format ( Round ( kb, 1 ), "NZ=" ) + " " + Output.Kilobyte ();
	endif; 
	
EndFunction 

&AtServer
Function ObjectToURL ( Ref ) export
	
	code = Cloud.GetTenantCode ();
	url = Cloud.GetTenantURL ( code );
	return url + "/#" + GetURL ( Ref );
	
EndFunction 

&AtServer
Function HTMLToDocument ( HTML ) export
	
	reader = new HTMLReader ();
	reader.SetString ( html );
	dom = new DOMBuilder ();
	return dom.Read ( reader );
	
EndFunction 

&AtServer
Function DocumentToHTML ( Document ) export
	
	removeXMLtag ( Document );
	writer = new HTMLWriter ();
	writer.SetString ();
	dom = new DOMWriter ();
	dom.Write ( Document, writer );
	return writer.Close ();
	
EndFunction 

&AtServer
Procedure removeXMLtag ( Document )
	
	children = Document.ChildNodes;
	instruction = Type ( "DOMProcessingInstruction" );
	for each item in children do
		if ( item.NodeName = "xml"
			and TypeOf ( item ) = instruction ) then
			Document.RemoveChild ( item );
			return;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function PeriodToString ( Period, Periodicity ) export
	
	lang = "L=" + CurrentLanguage ();
	if ( Periodicity = 1 ) then
		s = dayFormat ( Period, lang );
	elsif ( Periodicity = 2 ) then
		s = weekFormat ( Period, lang );
	elsif ( Periodicity = 3 ) then
		s = tenDaysFormat ( Period, lang );
	elsif ( Periodicity = 4 ) then
		s = monthFormat ( Period, lang );
	elsif ( Periodicity = 5 ) then
		s = quarterFormat ( Period, lang );
	elsif ( Periodicity = 6 ) then
		s = halfYearFormat ( Period, lang );
	elsif ( Periodicity = 7 ) then
		s = yearFormat ( Period, Lang );
	else
		s = periodFormat ( Period, lang );
    endif; 
	return Title ( s );
	
EndFunction

&AtServer
Function dayFormat ( Period, Lang )
	
	return Format ( Period, Lang + ";DF='ddd, dd/MM'" );
	
EndFunction

&AtServer
Function weekFormat ( Period, Lang )
	
	startDate = BegOfWeek ( Period );
	endDate = EndOfWeek ( Period );
	sameMonth = ( Month ( startDate ) = Month ( endDate ) );
	return Format ( startDate, Lang + ";DF='MMM '" ) + Day ( startDate ) + " - " + Day ( endDate ) + Format ( endDate, Lang + ";" + ? ( sameMonth, "DF=', yyyy'", "DF=' MMM, yyyy'" ) );
	
EndFunction

&AtServer
Function tenDaysFormat ( Period, Lang )
	
	dayPeriod = Day ( Period );
	begMonth = BegOfMonth ( Period );
	if ( dayPeriod < 11 ) then
		startDate = begMonth;
		endDate = begMonth + 9 * 86400;
	elsif ( dayPeriod > 20 ) then
		startDate = begMonth + 20 * 86400;
		endDate = EndOfMonth ( Period );
	else
		startDate = begMonth + 10 * 86400;
		endDate = begMonth + 19 * 86400;
	endif;
	return Format ( startDate, Lang + ";DF='MMM '" ) + Day ( startDate ) + " - " + Day ( endDate ) + Format ( endDate, Lang + ";DF=', yyyy'" );
	
EndFunction

&AtServer
Function monthFormat ( Period, Lang ) 
	
	return Format ( Period, Lang + ";DF='MMM yyyy'" );
	
EndFunction

&AtServer
Function quarterFormat ( Period, Lang ) 

	startDate = BegOfQuarter ( Period );
	endDate = EndOfQuarter ( Period );
	return Format ( startDate, Lang + ";DF='MMM '" ) + Day ( startDate ) + " - " + Day ( endDate ) + Format ( endDate, Lang + ";DF=' MMM, yyyy'" );
	
EndFunction

&AtServer
Function halfYearFormat ( Period, Lang ) 

	if ( Month ( Period ) < 6 ) then
		startDate = BegOfYear ( Period );
		endDate = ( AddMonth ( BegOfYear ( Period ), 6 ) - 1 );
	else
		startDate = ( AddMonth ( BegOfYear ( Period ), 6 ) );
		endDate = EndOfYear ( Period );
	endif;
	return Format ( startDate, Lang + ";DF='MMM '" ) + Day ( startDate ) + " - " + Day ( endDate ) + Format ( endDate, Lang + ";DF=' MMM, yyyy'" );
	
EndFunction

&AtServer
Function yearFormat ( Period, Lang )
	
	startDate = BegOfYear ( Period );
	endDate = EndOfYear ( Period );
	return Format ( startDate, Lang + ";DF='MMM '" ) + Day ( startDate ) + " - " + Day ( endDate ) + Format ( endDate, Lang + ";DF=' MMM, yyyy'" );
	
EndFunction 

&AtServer
Function periodFormat ( Period, Lang )
	
	return Format ( Period, Lang + ";DF='MMM '" ) + Day ( Period  ) + ", " + Format ( Period, Lang + ";DF=' yyyy'" );
	
EndFunction 

&AtServer
Function MapToStruct ( Map ) export
	
	p = new Structure ();
	for each item in Map do
		p.Insert ( item.Key, item.Value );
	enddo; 
	return p;
	
EndFunction 

Function StringToNumber ( S ) export
	
	type = new TypeDescription ( "Number" );
	return type.AdjustValue ( S );
	
EndFunction 

&AtClient
Function ParametersToMap ( Parameters ) export
	
	keys = new Array ();
	values = new Array ();
	mustbeKey = false;
	keyStarted = false;
	valueStarted = false;
	quoteStarted = false;
	for i = 1 to StrLen ( Parameters ) do
		c = Mid ( Parameters, i, 1 );
		if ( c = """" ) then
			quoteStarted = not quoteStarted;
			continue;
		endif; 
		if ( not quoteStarted ) then
			if ( c = "-" ) then
				mustbeKey = true;
				valueStarted = false;
				continue;
			elsif ( c = " " ) then
				mustbeKey = false;
				if ( keyStarted ) then
					keyStarted = false;
					valueStarted = true;
					values.Add ( new Array () );
				endif;
				continue;
			endif;
		endif; 
		if ( mustbeKey ) then
			mustbeKey = false;
			keyStarted = true;
			keys.Add ( new Array () );
			keyIndex = keys.UBound ();
		endif;
		if ( keyStarted ) then
			keys [ keyIndex ].Add ( c );
		elsif ( valueStarted ) then
			values [ keyIndex ].Add ( c );
		endif; 
	enddo; 
	result = new Map ();
	for i = 0 to keys.UBound () do
		result [ StrConcat ( keys [ i ] ) ] = StrConcat ( values [ i ] );
	enddo; 
	return result;
	
EndFunction 

&AtServer
Function AmountToWords ( Amount, Currency = undefined, Language = "ro" ) export
	
	if ( Currency = undefined ) then
		Currency = Application.Currency ();
	endif;
	numOptions = DF.Values ( Currency, "Options" + Language ) [ "Options" + Language ];
	format = "L=" + Language + "_" + Upper ( Language ) + "; FS=false";
	return NumberInWords ( Amount, format, numOptions );
	
EndFunction 

&AtServer
Function DecToHex ( Number ) export
	
	set = "0123456789ABCDEF"; 
	value = Number; 
	s = ""; 
	while ( value > 0 ) do
		s = Mid ( set, 1 + ( value % 16 ), 1 ) + s; 
		value = Int ( value / 16 );
	enddo;
	return s; 
	
EndFunction
