Create Table User(
 id	Integer Primary Key,
 u	VarChar(255) Not Null,
 byWho	VarChar(255) Not Null
);

Create Index iUser On User(u);
