Create Table if not exists H(
 id	Integer Primary Key,
 idMy	Integer,
 hash	VarChar(255) Unique,
 xtime	DateTime Default(DateTime('now', '+3 minutes'))
);

Delete From H Where xtime<DateTime('now');
