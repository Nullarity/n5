#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Sheet;
var Batch;
var TooOld;
var CurrentYear;
var Code, Registered, Description, Entity, Address,
		Area, Directors, Founders, LiquidationDate;

Procedure Exec () export
	
	readFile ();
	end = Sheet.TableHeight;
	BeginTransaction ();
	counter = 1;
	for line = 3 to end do
		read ( line );
		if ( not valid () ) then
			continue;
		endif;
		ref = Catalogs.OrganizationsClassifier.FindByCode ( code );
		obj = ? ( ref.IsEmpty (), Catalogs.OrganizationsClassifier.CreateItem (),
			ref.GetObject() );
		obj.Code = code;
		obj.Registered = Registered;
		obj.Description = Description;
		obj.Entity = Entity;
		obj.Address = Address;
		obj.Area = Area;
		obj.Directors = Directors;
		obj.Founders = Founders;
		obj.LiquidationDate = LiquidationDate;
		obj.Liquidated = LiquidationDate <> undefined;
		obj.Write ();
		if ( counter = Batch ) then
			CommitTransaction ();
			BeginTransaction ();
			counter = 0;
		endif;
		counter = counter + 1;
	enddo;
	CommitTransaction ();

EndProcedure

Procedure readFile ()

	file = GetTempFileName ( "xlsx" );
	Parameters.File.Write ( file );
	Sheet = new SpreadsheetDocument ();
	Sheet.Read ( file );
	DeleteFiles ( file );

EndProcedure

Procedure read ( Line )
	
		Code = Sheet.Area ( Line, 1 ).Text;
		Registered = textToDate ( Sheet.Area ( line, 2 ).Text );
		Description = Sheet.Area ( line, 3 ).Text;
		Entity = Sheet.Area ( line, 4 ).Text;
		Address = Sheet.Area ( line, 5 ).Text;
		Area = Sheet.Area ( line, 6 ).Text;
		Directors = Sheet.Area ( line, 7 ).Text;
		Founders = Sheet.Area ( line, 8 ).Text;
		LiquidationDate = textToDate ( Sheet.Area ( line, 11 ).Text );
	
EndProcedure

Function textToDate ( Text )
	
	if ( IsBlankString ( Text ) ) then
		return undefined;
	endif;
	parts = StrSplit ( Text, ".-/" );
	try
		return Date ( parts [ 2 ], parts [ 1 ], parts [ 0 ] );
	except
		return undefined;
	endtry;
	
EndFunction

Function valid ()
	
	invalid = IsBlankString ( Code )
	or IsBlankString ( Description )
	or Registered = undefined
	or ( LiquidationDate <> undefined
			and ( CurrentYear - Year ( LiquidationDate ) ) > TooOld );
	return not invalid;
	
EndFunction

Batch = 1000;
CurrentYear = Year ( CurrentSessionDate () );
TooOld = 3;

#endif