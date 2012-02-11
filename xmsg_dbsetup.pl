 # Project: x_msg invisible activist machinery
 # File name: xmsg_dbsetup.pl
 # Description:  Sets up the database for initial use
 # Authors: Cliff Hammett and Alexandra Joensson
 #
 # 
 # This program is free software; you can redistribute it and/or modify 
 # it under the terms of the GNU General Public License as published by 
 # the Free Software Foundation; either version 2 of the License, or 
 # (at your option) any later version.
 # 
 # This program is distributed in the hope that it will be useful, but 
 # WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 # or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
 # for more details.
 # 
 # You should have received a copy of the GNU General Public License along 
 # with this program; if not, write to the Free Software Foundation, Inc., 
 # 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 #


use Settings;
use DBD2;
use Term::ReadKey;
use strict;


 #This sets up the database connection
print "Username:\n";
my $user = <>; 
 
print "Password:\n";
 
ReadMode('noecho'); 
my $password = ReadLine(0);
 
ReadMode(0);
 
chomp $user;
chomp $password;
 
my $dbd2 = DBD2->new;
$dbd2->Connect_DB($user, $password);
$dbd2->Init_DB;

