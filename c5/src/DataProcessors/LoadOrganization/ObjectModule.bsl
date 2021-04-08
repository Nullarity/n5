#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var CodeFiscal;
var DOMDocument;
var Result;

Procedure Exec () export
	
	init ();
	if ( not requestFields () ) then
		return;
	endif;
	parseDescription ();
	parseVAT ();
	parseContact ();
	requestAddress ();
	parseAddress ();
	PutToTempStorage ( Result, Parameters.Address );
	
EndProcedure

Procedure init ()
	
	CodeFiscal = Parameters.CodeFiscal;
	Result = new Structure ( "Description, FullDescription, VATCode, Address, FirstName, LastName, Patronymic" );
	
EndProcedure

Function requestFields ()
	
	connection = new HTTPConnection ( "servicii.fisc.md", , , , , 10, new OpenSSLSecureConnection () );
	request = new HTTPRequest ( "/contribuabil.aspx?ctl00$body$Default1$tin_in=" + CodeFiscal + "&__EVENTTARGET=" );
	answer = connection.Get ( request ); 
	body = answer.GetBodyAsString ();
	reader = new HTMLReader ();
	reader.SetString ( body );
	builder = new DOMBuilder ();
	DOMDocument = builder.Read ( reader );
	reader.Close ();
	return DOMDocument.GetElementById ( "ctl00_body_Default1_h_name_s" ) <> undefined;
	
EndFunction

Procedure parseDescription ()
	
	element = DOMDocument.GetElementById ( "ctl00_body_Default1_h_name_s" );
	if ( element = undefined ) then
		return;
	endif;
	s = TrimAll ( element.TextContent );
	Result.FullDescription = TrimAll ( s );
	s = StrReplace ( s, "S.C.", "" );
	s = StrReplace ( s, "S.R.L.", "" );
	s = StrReplace ( s, "I.C.S.", "" );
	s = StrReplace ( s, "C.S.V.", "" );
	s = StrReplace ( s, "S.A.", "" );
	s = StrReplace ( s, "O.M.", "" );
	s = StrReplace ( s, "I.M.", "" );
	s = StrReplace ( s, "F.P.C.", "" );
	s = StrReplace ( s, "I.I.", "" );
	Result.Description = TrimAll ( s );
	
EndProcedure

Procedure parseVAT ()
	
	element = DOMDocument.GetElementById ( "ctl00_body_Default1_platitorTVA_Table" );
	if ( element = undefined ) then
		return;
	endif;
	code = "";
	registration = Date ( 1, 1, 1 );
	childs = element.ChildNodes;
	for i = 1 to childs.Count () - 1 do
		date = childs [ i ].ChildNodes [ 2 ].TextContent;
		d = Left ( date, 2 );
		m = Mid ( date, 4, 2 );
		y = Right ( date, 4 );
		date = Date ( y, m, d );
		if ( date > registration ) then
			code = childs [ i ].ChildNodes [ 0 ].TextContent;
		endif;
	enddo;
	Result.VATCode = code;
	
EndProcedure

Procedure parseContact ()
	
	element = DOMDocument.GetElementById ( "ctl00_body_Default1_h_director");
	if ( element = undefined ) then
		return;
	endif;
	list = StrSplit ( element.TextContent, " " );
	if ( list.Count () = 0 ) then
		return;
	endif;
	Result.LastName = Title ( list [ 0 ] );
	if ( list.Count () > 1 ) then
		Result.FirstName = Title ( list [ 1 ] );
	endif;
	if ( list.Count () > 2 ) then
		Result.Patronymic = Title ( list [ 2 ] );
	endif;
	
EndProcedure

Procedure requestAddress ()
	
	connection = new HTTPConnection ( "idno.md", , , , , 10, new OpenSSLSecureConnection () );
	request = new HTTPRequest ( "/companie?idno=" + CodeFiscal );
	answer = connection.Get ( request ); 
	body = answer.GetBodyAsString ();
	reader = new HTMLReader ();
	reader.SetString ( body );
	builder = new DOMBuilder ();
	DOMDocument = builder.Read ( reader );
	reader.Close ();
	
EndProcedure

Procedure parseAddress ()
	
	elements = DOMDocument.GetElementByTagName ( "h4" );
	for each element in elements do
		if ( element.TextContent = "Adresa" ) then
			siblings = element.ParentNode.GetElementByTagName ( "a" );
			if ( siblings.Count () > 0 ) then
				Result.Address = siblings [ 0 ].TextContent;	
			endif;
		endif;
	enddo;
	
EndProcedure

#endif