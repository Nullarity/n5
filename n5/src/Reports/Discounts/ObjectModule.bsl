#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var Data;
var InHandQuery;
var ResultQuery;

Procedure OnPrepare ( Template ) export
	
	prepareTables ( Template );
	
EndProcedure 

Procedure prepareTables ( Template )
	
	text = Template.DataSets.Discounts.Query;
	splitter = StrFind ( text, ";", SearchDirection.FromEnd );
	Template.DataSets.Discounts.Query = Mid ( text, splitter + 1 );
	q = new Query ( Left ( text, splitter - 1 ) );
	q.TempTablesManager = new TempTablesManager ();
	for each item in Template.ParameterValues do
		q.SetParameter ( item.Name, item.Value );
	enddo; 
	CoreLibrary.AdjustQuery ( q );
	q.Execute ();
	Params.TempTables = q.TempTablesManager;
	
EndProcedure

Procedure AfterOutput () export

	entitleDiscounts ();

EndProcedure

Procedure entitleDiscounts ()

	Print.Entitle ( Params.Result, Metadata.Reports.Discounts.Presentation () );

EndProcedure

#endif