CREATE TABLE pfx (
  id int(11) NOT NULL auto_increment,
  Op char(1) NOT NULL,
  ctime timestamp NOT NULL default CURRENT_TIMESTAMP,
  Parent int(11) default NULL,
  IP varchar(15) NOT NULL,
  u varchar(255) default NULL,
  Error text,
  PRIMARY KEY  (id),
  KEY ctime (ctime),
  KEY Parent (Parent),
  KEY u (u),
  KEY IP (IP)
);
