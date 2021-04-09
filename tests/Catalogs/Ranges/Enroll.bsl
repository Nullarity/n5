// Create an Enroll Range
// Create a new Range
// Write & check records

Call("Common.Init");
CloseAll();

prefix = Right(Call("Common.GetID"), 5);

Commando("e1cib/command/Document.EnrollRange.Create");
Set("#Warehouse", "Main");
Next();
Activate("#Range").Create();
With();
Set("#Prefix", prefix);
Set("#Start", 1);
Set("#Finish", 30);
Set("#Length", 3);
Click("#WriteAndClose");
With();
Click("#FormWrite");
Click("#FormShowRecords");
With();
CheckTemplate("#TabDoc");

Disconnect();