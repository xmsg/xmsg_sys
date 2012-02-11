
 # Project: x_msg invisible activist machinery
 # File name: xmsg_config
 # Description: Provides some basic database functionality
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


use strict;
#use warnings;
use Switch;
use Settings;
use DBD2;
use Term::ReadKey;

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

&menu;

sub menu{

	my $selection = 0;	
	while ($selection !~ m/Q|q/){
		
		print "\nMAIN MENU\n";
		print "\nPlease enter a selection:\n";
		print "1 User governance\n2 Change password\nq Quit\n\n";
		
		$selection = <>;
	        chomp $selection;	
		switch($selection){
			case (1){&usrgov_MAIN;}
			case (2){&chpass_MAIN;}
		}

	}
	$dbd2->Disconnect_DB;
}


sub chpass_MAIN{

	print "Are you sure you wish to change your password? Enter 'y' for yes, or 'n' for no.\n";

	my $input = <>;
	
	if ($input =~ m/y|Y/){
	
		&chpass_check;		

	}

}


sub chpass_check{

	ReadMode('noecho');
	print "Please enter your CURRENT password.\n";
	my $input = <>;
	chomp $input;

	if ($input eq $password){
		&chpass_newpassword;
	}else{
		print "The passwords do not match.\n";
		&check_spacebar;

	}

	ReadMode(0);
}

sub chpass_newpassword{

	print "Please enter your NEW password.\n";
	my $input = <>;
	chomp $input;
	
	print "Please RE-ENTER your new password.\n";

	my $input2 = <>;
	chomp $input2;

	if ($input eq $input2){

		$dbd2->change_password($user, $input);
		print "Password changed.\n";
		$password = $input;
		&check_spacebar;
	
	}else{
		print "The passwords do not match.\n";
		&check_spacebar;
	}


}

sub usrgov_MAIN{

	my $selection = 0;	
	while ($selection !~ m/Q|q/){
		
		print "\nUSER GOVERNANCE\n";
		print "\nWhat would you like to do:\n";
		print "1 View users and dates\n2 Check for tel number" .
			"\n3 Delete user\nq Cancel\n\n";
		
		$selection = <>;
		chomp $selection;
		
		switch($selection){
			case (1){&usrgov_view_users}
			case (2){&usrgov_check_for_no}
			case (3){&usrgov_del_user}
		}

	}
}

sub usrgov_view_users{

	my $header = "\nUSERID     Date of Last Activity\n";
	print $header;
	my $rowlength;

	my @userlist = $dbd2->retrieve_table(\$rowlength, "NumberID, LastActivity", "tblNumbers", "");

	my $size = @userlist;
	my $c = 0;

	for(my $i = 0; $i < $size; $i++){

		print $userlist[$i];
		$i++;
		print "         " . $userlist[$i] . "\n";

		if ($c > 20){

			&check_spacebar;
			print $header;	
		}

		$c++;
	}

	&check_spacebar;

}


sub usrgov_check_for_no{

	print "\nCHECK FOR TEL NUMBER\n";
	print "Enter part of the number you wish to check for (this may work better if you start"
		. " on the second digit)\n";
	
	my $input = <>;
	chomp $input;
	
	my $rowlength;
	my @matches = $dbd2->check_like_telnumber("%$input%");
	
	my $size = @matches;

	if ($size == 0){
		
		print "No users have that sequence in their telephone number\n";
		&check_spacebar;

	}else{
		print "The following users have that sequence in their telephone number:\n";
		print "USER ID\n";
		for (my $i = 0; $i < $size; $i++){

			print $matches[$i] . "\n";

		}

		&check_spacebar;
	}


}

sub usrgov_del_user{


	my $input = "X";
	while ($input !~ m/q|Q/){
		print "\nDELETE USER\n";
		print "Enter the user ID of the user you wish to remove from the system." . 
			"  Or enter 'q' to cancel\n";
	
		$input = <>;
		chomp $input;
		
		if ($input !~ m/\D/){

			$input = &usrgov_du_check($input);
		}
			

	}

}

sub usrgov_du_check{

	my $userid = shift;
	my $rowlength;
	my @check = $dbd2->retrieve_table(\$rowlength, "NumberID", 
		"tblNumbers", "WHERE NumberID = $userid");
	
	if ($check[0] == $userid){
		print "\nUser found.  Do you wish to remove them from the system?" .
			"Enter 'y' to confirm or 'n' to cancel.\n";

		my $input = <>;
		if ($input =~ /Y|y/){
			&usrgov_du_remove($userid);
			return 'q';
		}else{
			print "The user has not been deleted.\n";
			
			&check_spacebar;
			return 'X';
		}

	}else{

		print "No such user detected\n";
		&check_spacebar;
		return 'X';
	}


}

sub usrgov_du_remove{

	my $userid = shift;
	my $rowlength;
	my @memberships = $dbd2->retrieve_table(\$rowlength, "ListID", "tblLinkNumList",
			  	"WHERE NumberID = $userid");
	
	my $size = @memberships;
	
	for (my $i = 0; $i < $size; $i++){

		$dbd2->ctrl_dlt_commands($userid, $memberships[$i]);

	}

	print "\nUser $userid has been removed from the system.\n";
	&check_spacebar;

}


sub check_spacebar{

	print "Press space to continue\n";
        my $done;
        while ( 1 ) { 
		sleep 1;

		ReadMode( 'cbreak' );
		if ( defined ( my $key = ReadKey( -1 ) ) ) { 
		    # input waiting; it's in $key
			$done = $key eq ' ';
		}   
		ReadMode( 'normal' );
	        return if $done;

	}



}



