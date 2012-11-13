Create Table Attrs(
 id	Integer Primary Key,
 serial	VarChar(15),
 notBefore	DateTime,
 notAfter	DateTime,
 SHA1	VarChar(60),
 email	Text,
 subj	Text
);

Create Index iBefore On Attrs(notBefore);
Create Index iAfter On Attrs(notAfter);
Create Index iSerial On Attrs(serial);
