// Check Taxes check box

Call ( "Common.Init" );
CloseAll ();

#region companyBankAccount
Commando("e1cib/command/Catalog.BankAccounts.Create");
CheckState("#Taxes", "Visible", false );
CheckState("#AccountTax", "Visible", false );
CheckState("#Dim1", "Visible", false );
CheckState("#Dim2", "Visible", false );
CheckState("#Dim3", "Visible", false );
Close ();
#endregion

#region organizationBankAccount
Commando("e1cib/command/Catalog.Organizations.Create");
Set ( "#Description", Call ( "Common.GetID" ));
Click("#FormWrite");
Click ( "Bank Accounts", GetLinks () );
With ();
Click("#FormCreate");
With ();
CheckState("#AccountTax", "Visible", false );
CheckState("#Dim1", "Visible", false );
CheckState("#Dim2", "Visible", false );
CheckState("#Dim3", "Visible", false );
#endregion

#region tickTaxes
Click("#Taxes");
CheckState("#AccountTax", "Visible" );
CheckState("#Dim1", "Visible", false );
#endregion

#region setAccount
Put("#AccountTax", "5348");
CheckState("#Dim1", "Visible" );
#endregion

#region untick
Click ("#Taxes");
CheckState("#AccountTax", "Visible", false );
CheckState("#Dim1", "Visible", false );
CheckState("#Dim2", "Visible", false );
CheckState("#Dim3", "Visible", false );
#endregion