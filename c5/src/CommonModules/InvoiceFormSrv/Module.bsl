
Function GetTaxes ( val TaxGroup, val Date ) export
	
	s = "
	|select Taxes.Tax as Tax, Info.Percent as Percent
	|from Catalog.TaxGroups.Taxes as Taxes
	|	//
	|	// Info
	|	//
	|	left join InformationRegister.TaxItems.SliceLast ( &Date, Tax in ( select distinct Tax from Catalog.TaxGroups.Taxes where Ref = &Ref ) ) as Info
	|	on Info.Tax = Taxes.Tax
	|where Taxes.Ref = &Ref
	|order by Taxes.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", TaxGroup );
	q.SetParameter ( "Date", Date );
	return CollectionsSrv.Serialize ( q.Execute ().Unload () );
	
EndFunction 
