Create Table Certs(
 id	Integer Primary Key AutoIncrement,
 Issuer	Integer,
 Key	Integer,
 ctime	DateTime Default CURRENT_TIMESTAMP,
 Revoke	DateTime,
 revokeReason	Text,
 BLOB	Text
);

Create Index iRevoke On Certs(Revoke);
Create Index iIssuer On Certs(Issuer);
