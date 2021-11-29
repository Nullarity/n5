// Check Taxes check box

Call ( "Common.Init" );
CloseAll ();

#region newPaymentOrder
Commando("e1cib/command/Document.PaymentOrder.Create");
CheckState("#Account", "Visible", false );
CheckState("#Dim1", "Visible", false );
CheckState("#Dim2", "Visible", false );
CheckState("#Dim3", "Visible", false );
#endregion

#region tickTaxes
Click("#Taxes");
CheckState("#Account", "Visible" );
CheckState("#Dim1", "Visible", false );
#endregion

#region setAccount
Put("#Account", "5348");
CheckState("#Dim1", "Visible" );
#endregion

#region untick
Click ("#Taxes");
CheckState("#Account", "Visible", false );
CheckState("#Dim1", "Visible", false );
CheckState("#Dim2", "Visible", false );
CheckState("#Dim3", "Visible", false );
#endregion