
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	values = getFillingValues ( CommandParameter );
	if ( values = undefined ) then
		Output.InvoiceWrongBase ();
		return;
	endif; 
	p = new Structure ( "FillingValues, Base", values, CommandParameter );
	OpenForm ( "Document.ProjectsInvoice.ObjectForm", p );
	
EndProcedure

&AtServer
Function getFillingValues ( val Objects )
	
	table = getFieldsTable ( Objects );
	if ( table.Count () <> 1 ) then
		return undefined;
	endif; 
	fillingValues = new Structure ( "Customer, Currency, InvoiceMethod" );
	FillPropertyValues ( fillingValues, table [ 0 ] );
	return fillingValues;

EndFunction 

&AtServer
Function getFieldsTable ( Objects )
	
	typeOfObject = TypeOf ( Objects [ 0 ] );
	if ( typeOfObject = Type ( "DocumentRef.TimeEntry" ) ) then
		s = "
		|select distinct TimeEntries.Customer as Customer, TimeEntries.Project.Currency as Currency, value ( Enum.InvoiceMethods.ByTimeEntries ) as InvoiceMethod
		|from Document.TimeEntry as TimeEntries
		|where TimeEntries.Ref in ( &Objects )
		|";
	elsif ( typeOfObject = Type ( "CatalogRef.Projects" ) ) then
		s = "
		|select distinct Projects.Owner as Customer, Projects.Currency as Currency, value ( Enum.InvoiceMethods.ByProjects ) as InvoiceMethod
		|from Catalog.Projects as Projects
		|where not Projects.IsFolder
		|and Projects.Ref in ( &Objects )
		|";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Objects", Objects );
	return q.Execute ().Unload ();

EndFunction 
