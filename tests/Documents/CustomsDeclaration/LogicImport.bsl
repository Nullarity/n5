Call ( "Common.OpenList", Meta.Documents.VendorInvoice );

p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = _.id;
Call ( "Common.Find", p );
form = With ( "Vendor Invoices" );

Click ( "#FormReportRecordsShow" );
With ( "Records: Vendor Invoice *" );
Call ( "Common.CheckLogic", "#TabDoc" );
