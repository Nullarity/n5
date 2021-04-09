// - Open list of settings elements
// - Change system's presentation to russian

CloseAll ();

Commando ( "e1cib/list/ChartOfCharacteristicTypes.Settings" );

for each item in _ do
	OldName = item.Key;
	NewName = item.Value;

	With ( "Settings" );

	p = Call ( "Common.Find.Params" );
	p.Where = "Parameter";
	p.What = OldName;
	p.CompareType = "Exact match";
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	try
		With ( OldName + " (Settings)" );
		Put ( "#Description", NewName );
		Click ( "#FormWriteAndClose" );
	except
	endtry;	
enddo;
