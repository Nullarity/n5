#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Realtime;

Procedure Filling ( FillingData, FillingText, StandardProcessing )
	
	type = TypeOf ( FillingData );
	if ( type = Type ( "DocumentObject.InvoiceRecord" ) )
		or ( type = Type ( "DocumentObject.ItemsPurchase" ) )
		or ( type = Type ( "DocumentObject.ServicesPurchase" ) )then
		fillByBase ( FillingData );
	endif;
	
EndProcedure

Procedure fillByBase ( FillingData )
	
	Range = FillingData.Range;
	Date = FillingData.Date;
	Base = FillingData.Ref;
	Company = FillingData.Company;
	data = rangeData ();
	if ( data = undefined ) then
		raise OutputCont.UndefinedRangeLocation ( new Structure ( "Range", Range ) );
	endif;
	Account = data.Account;
	Capacity = data.Capacity;
	Dim1 = data.Dim1;
	Dim2 = data.Dim2;
	Dim3 = data.Dim1;
	ExpenseAccount = data.ExpenseAccount;
	Feature = data.Feature;
	Item = data.Item;
	Package = data.Package;
	Product = data.Product;
	ProductFeature = data.ProductFeature;
	Series = data.Series;
	Warehouse = data.Warehouse;
	if ( Creator.IsEmpty () ) then
		Creator = SessionParameters.User;
	endif;
	
EndProcedure

Function rangeData ()
	
	s = "
	|select Ranges.Account as Account, Ranges.Capacity as Capacity, Ranges.Dim1 as Dim1, Ranges.Dim2 as Dim2,
	|	Ranges.Dim3 as Dim3, Ranges.ExpenseAccount as ExpenseAccount, Ranges.Feature as Feature, Ranges.Item as Item,
	|	Ranges.Package as Package, Ranges.Product as Product, Ranges.ProductFeature as ProductFeature, Ranges.Series as Series,
	|	Locations.Warehouse as Warehouse
	|from Catalog.Ranges as Ranges
	|	//
	|	// Locations
	|	//
	|	join InformationRegister.RangeLocations.SliceLast ( &Date, Range = &Range ) as Locations
	|	on true
	|where Ranges.Ref = &Range
	|";
	q = new Query ( s );
	q.SetParameter ( "Range", Range );
	q.SetParameter ( "Date", Date );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	setProperties ();
	
EndProcedure

Procedure setProperties ()
	
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		SequenceCost.Rollback ( Ref, Company, PointInTime () );
	endif;
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	env.Realtime = Realtime;
	Cancel = not Documents.WriteOffForm.Post ( env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	BelongingToSequences.Cost.Clear ();
	
EndProcedure

#endif
