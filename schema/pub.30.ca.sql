Create Table CA(
 id	Integer Primary Key AutoIncrement,
 CN	VarChar(60) Unique,
 ctime	DateTime Default CURRENT_TIMESTAMP,
 x509	Integer,
 serial	VarChar(15) Default '01',
 crlSigner	Integer,
 crlNo	VarChar(15) Default '01',
 Notes	Text
);
