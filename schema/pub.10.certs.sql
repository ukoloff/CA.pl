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
Create Index iCCtime On Certs(ctime);

-- revokeReason (according to RFC 5280):
-- unspecified (0)
-- keyCompromise (1)
-- CACompromise (2)
-- affiliationChanged (3)
-- superseded (4)
-- cessationOfOperation (5)
-- certificateHold (6)
-- (value 7 is not used)
-- removeFromCRL (8)
-- privilegeWithdrawn (9)
-- AACompromise (10)

