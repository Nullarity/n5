// Description:
// Creates a new Position
//
// Returns:
// Structure ( "Code, Description" )

if ( _ = undefined ) then
	name = "_Employee: " + CurrentDate ();
elsif ( TypeOf ( _ ) = Type ( "Structure" ) ) then
	name = _.Description;
else
	name = _;
endif;

if ( Call ( "Common.AppIsCont" ) ) then
	MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Positions" );
	formPositions = With ();
	Click ( "#FormCreate" );
	
	classifierForm = With ();
	p = Call ( "Common.Find.Params" );
	p.Where = "Description, Ro";
	classifier = ? ( _ = undefined, "Contabil", _.ClassifierName );
	p.What = classifier;
	Call ( "Common.Find", p );
	if ( Call ( "Table.Count", Get ( "#List" ) ) = 0 ) then
		Click ( "#FormCreate" );
		With ();
		Put ( "#Description", classifier );
		Click ( "#FormWriteAndClose" );
		With ( classifierForm );
		p = Call ( "Common.Find.Params" );
		p.Where = "Description, Ro";
		p.What = classifier;
		Call ( "Common.Find", p );
	endif;
	
	Click ( "#FormChoose" );

	With ( formPositions );
	
	Click ( "#FormChange" );
	formPosition = With ();

	Put ( "#Description", name );
	Get ( "#PositionCode" ).Clear ();

	Click ( "#FormWrite" );
	code = Fetch ( "Code" );
	Close ( formPosition );
	try
		Click ( "No", "1?:*"  );
		With ( formPositions );
		p = Call ( "Common.Find.Params" );
		p.Where = "Description, Ro";
		p.What = name;
		Call ( "Common.Find", p );
		Click ( "#FormChange" );
		form = With ( name + " (Positions)" );
		code = Fetch ( "Code" );
		Close ( form );
	except
	endtry;
	return new Structure ( "Code, Description", code, name );

else
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Positions" );
	form = With ( "Positions (create)" );
	Put ( "#Description", name );
	Click ( "#FormWrite" );
	code = Fetch ( "Code" );
	Close ( form );
	return new Structure ( "Code, Description", code, name );
endif;

