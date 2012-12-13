Create Table Ini(
 id	Integer Primary Key AutoIncrement,
 Name	VarChar(15) Unique,
 ctime	DateTime Default CURRENT_TIMESTAMP,
 Value	Text,
 Notes	Text
);
