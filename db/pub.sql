Create Table Certs(
 id	Integer Primary Key AutoIncrement,
 Issuer	Integer,
 Key	Integer,
 ctime	DateTime Default CURRENT_TIMESTAMP,
 Revoke	DateTime,
 BLOB	Text
);

Create Index iRevoke On Certs(Revoke);
Create Index iIssuer On Certs(Issuer);

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

Create Table CA(
 id	Integer Primary Key AutoIncrement,
 CN	VarChar(60) Unique,
 ctime	DateTime Default CURRENT_TIMESTAMP,
 x509	Integer,
 serial	VarChar(15) Default '01',
 Notes	Text
);

Create Index iCN On CA(CN);
