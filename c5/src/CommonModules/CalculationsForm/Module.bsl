&AtServer
Procedure SetDate ( Object ) export

	type = TypeOf ( Object.Ref );
	if ( type = Type ( "DocumentRef.ClosingEmployees" ) ) then
		name = "ClosingEmployees";
	elsif ( type = Type ( "DocumentRef.ClosingAdvances" ) ) then
		name = "ClosingAdvances";
	else
		name = "ClosingAdvancesGiven";	
	endif;
	s = "
	|// Last month documents
	|select allowed top 1 Documents.Ref as Ref
	|from Document." + name + " as Documents
	|where Documents.Posted
	|and endofperiod ( Documents.Date, month ) = &LastMonth
	|and Documents.Company = &Company
	|";
	q = new Query ( s );
	lastMonth = BegOfMonth ( CurrentSessionDate () ) - 1;
	q.SetParameter ( "LastMonth", lastMonth );
	q.SetParameter ( "Company", Object.Company );
	if ( q.Execute ().IsEmpty () ) then
		Object.Date = lastMonth;
	endif;

EndProcedure
