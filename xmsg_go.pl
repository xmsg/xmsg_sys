

 # Project: x_msg invisible activist machinery
 # File name: xmsg_go.pl
 # Description:  Sets the program going provides main control loop
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




#!usr/bin/perl
	
use strict;
use warnings;
use DBD2;
use Switch;
use Settings;
use xmsg_phone_comms;
use xmsg_parser;
#require "xmsg_parser.pl";
#require "xmsg_gnokii.pl";
use Term::ReadKey;


#Set ups the different markers.  This needs to be rewritten to use constants
my(	$sendmark,
	$rmvmark,
	$errmark,
	$idmark,
	$langmark,
	$rfshmark) = (SYMB_SEND, SYMB_RMV, SYMB_ERR, SYMB_ID, SYMB_LANG, SYMB_RFSH);

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

#oooh look some object orientation
my $phone = xmsg_phone_comms->new;
my $parser = xmsg_parser->new;
#my $testval = &lang_findbyname('english');

#print $testval . " - returned lang\n";

#not sure what this does...
my $test_run = `ps aux | grep -c xmsg`;
print $test_run;

#sets up a date value for starting date checks 
#(they make sure no user has been inactive on the system for too long
my $exp_datecheck = `date -d "1 day ago" +%Y%m%d`;

&start_mainloop;




sub start_mainloop{

#	my $rdbd2 = shift;
	
	#Sets up the error_queue - this will be used to store messages which failed
	#to send on the first attempt, to be resent later.
	my @error_queue = ();
	my @notready = ();

	#this is the location gnokii will write to and the parser will read from
	my $msglocale = './inbox.txt';
	my $quitchar='q';


	for(my $i = 0;;$i++) {


		ReadMode ('cbreak');
		if (defined (my $ch = ReadKey(-1))){
		 #input was waiting and it was $ch
		    if ($ch eq $quitchar){&exit_check;}
		}else{
			
			#performs check on memberships	
			if (($i == 1) && (EXPIRING_MEMS == 1)){
			
				&exp_check(\@error_queue);
		
			}else{print "continuing...\n";}

			#downloads messages from the phone to the message location
			$phone->download_msgs($msglocale);
		
			my @messages = ();	
			#sets the parser to run an operation on the message location
			$parser->parse_start($msglocale, \@messages, \@notready);
			

			if (@messages){#needs a check to see if it is empty
				
				#runs a sub which cycles through the messages and determines what
				#to do with them.  Passes a ref to the error queue and the messages
				&fork_on_function(\@error_queue, \@messages);

			}elsif(@notready){

			#	&print_msg_fields(@notready);
				my @retries = $parser->parse_lnk_retry(\@notready);
				
				if (@retries){
					
					
					print "RETRIES\n";
			#		&print_msg_fields(@retries);
					&fork_on_function(\@error_queue, \@retries);	

				}


			}else{	
				
				@error_queue = &no_msg_waiting(@error_queue);
				
			}
			print "resting\n";
			
			sleep 12;
		
		

			if($i == 200){

			$i = 0;
			&DB_restart;

			}
		}

		ReadMode ('normal'); # restore normal tty settings
	
	}
}


sub exit_check{

	print "\nAre you sure you want to quit? strike 'y' for yes or 'n' for no\n" .
		"Program will resume in...\n";
	
	for(my $i = 0; $i <10; $i++){

		my $time = 10 - $i;
		print "$time secs\n";
		sleep 1;
		if (defined (my $ch = ReadKey(-1))){
		 #input was waiting and it was $ch
			if ($ch eq 'y'){
				&safe_exit;
			}elsif($ch eq 'n'){
				return;
			}
		}
		

	}


}



sub safe_exit {
	print "Exiting...\n";
	sleep 1;
	ReadMode('normal');
	$dbd2->Disconnect_DB;
	exit(@_);
}





sub exp_check {

	my $rerr_q = shift;
	my $curhour = `date +%H`;
	my $curdate = `date +%Y%m%d`;
	print "assessing for date check..\n";	
	print "hour is $curhour\n";
	print "date is $curdate\n";
	print "datecheck is $exp_datecheck";
	if (($curhour >= EXP_MSG_HOUR) && ($curdate > $exp_datecheck)) {

		print "Performing date check!\n";
		$exp_datecheck = $curdate;
		&exp_check_rmv($rerr_q);
		&exp_check_2ndmsg($rerr_q);
		&exp_check_1stmsg($rerr_q);		

	}

}

sub exp_check_1stmsg{
	my $rerr_q = shift;
	my @numbers = $dbd2->get_exp_numbers(EXPIRE_PERIOD - WARN_DAYS_1, 0);
	my $size = @numbers;
	print "$size numbers notified once\n";
	for (my $i = 0; $i < $size; $i++){		
		$dbd2->update_exp_warnings($numbers[$i], 1);
		my $lang = $dbd2->check_no_has_lang_bytel($numbers[$i]);
                my $sysmsg = &sys_msg_finder($lang,  @MSG_EXP_WARN1);
                push @{$rerr_q}, $phone->send_sms($sysmsg, $numbers[$i]);
	}
}

sub exp_check_2ndmsg{


	my $rerr_q = shift;
	my @numbers = $dbd2->get_exp_numbers(EXPIRE_PERIOD - WARN_DAYS_2, 1);

	my $size = @numbers;
	
	print "$size numbers notified a second time\n";
	for (my $i = 0; $i < $size; $i++){
		
		$dbd2->update_exp_warnings($numbers[$i], 2);
		my $lang = $dbd2->check_no_has_lang_bytel($numbers[$i]);
                my $sysmsg = &sys_msg_finder($lang,  @MSG_EXP_WARN2);
                push @{$rerr_q}, $phone->send_sms($sysmsg, $numbers[$i]);
	}
}

sub exp_check_rmv{

	my $rerr_q = shift;
	my @numbers = $dbd2->get_exp_numbers(EXPIRE_PERIOD, 2);
	my $size = @numbers;
	
	print "$size numbers removed\n";
	for (my $i = 0; $i < $size; $i++){
		
		my $lang = $dbd2->check_no_has_lang_bytel($numbers[$i]);
                my $sysmsg = &sys_msg_finder($lang,  @MSG_EXP_RMV);
                push @{$rerr_q}, $phone->send_sms($sysmsg, $numbers[$i]);

		my $id = $dbd2->check_telnumber($numbers[$i]);

		$dbd2->delete_frm_all_lists($id);
		$dbd2->delete_frm_tblNumbers($id);		
	}



}



sub no_msg_waiting{
	
		my @error_queue = @_;

		print "no messages waiting, checking error queue...\n";	
		
		if (@error_queue){
			
			print "entry in error list, processing...\n";
		
			
			&error_resends(\@error_queue);
		
		}else{ print "no errors, ";}

		return @error_queue;

}



sub sys_msg_finder{ # finds system message by language id

	my $lang_id = shift;
	my @sysmsg = @_;
	my $msg = 'oh dear';	
#	print $sysmsg[0]{'lng_id'} . "- sys language id first entry\n";
#	print $lang_id . "received lang_id\n";
	&sys_msg_searchloop($lang_id, \@sysmsg, \$msg);

	if($msg eq 'oh dear'){
	
		&sys_msg_searchloop(DFLT_LANG, \@sysmsg, \$msg);

	}
	
	return $msg;
		
	

}



sub sys_msg_searchloop{

	my ($lang_id, $rsysmsg, $rmsg) = @_;

	my $size = @{$rsysmsg};
	for(my $i = 0; $i < $size; $i++){

		if ($rsysmsg->[$i]{'lng_id'} == $lang_id){
			
			${$rmsg} = $rsysmsg->[$i]{'msg'};

		}
	}
	
}
sub DB_restart{
	
	sleep 5;
	$dbd2->Disconnect_DB;
	$dbd2 = DBD2->new;
	$dbd2->Connect_DB($user, $password);
	

}


sub error_resends{

	my $rsd = shift;

	my $msg = $rsd->[0]{'msg'};
	my $num = $rsd->[0]{'num'};
	chomp $msg;
	chomp $num;
	my @numbers = ();
	push @numbers, $num;
	&sms_queuer($rsd, $msg, \@numbers);
	print "done\n";

}


sub sms_queuer{

	my ($rerr, $msg, $rnums) = @_;

	my @rtn = $phone->send_sms($msg, @{$rnums});

	if (@rtn){

		push @{$rerr}, @rtn;
	
	}

}


sub fork_on_function{

	print "branching initialised\n";
	#grabs the references to the message and error queue arrays
	my ($rerr_q, $rmsg) = @_;	


	#gets size of message arrary
	my $size = @{$rmsg};

	#print $rmsg->[0]{'msgcallr'} . "\n";
	#sorts message array by date
	my @sd = sort {$$a{'dtno'} <=> $$b{'dtno'}} @{$rmsg};


	print $size . "-messages received.\n";

	#for loop to cycle through all messages
	for(my $i = 0; $i < $size; $i++){
				 
		#runs a subroutine defining responses to each symbol
		&fork_cases($rerr_q, \@sd, $i);

	}
	
}


sub fork_cases{

	#gets the subrountine and all fields for the current message	
	my ($rerr_q, $rsd, $i) = @_;

	my $func = $rsd->[$i]{'func'};
	my $sender = $rsd->[$i]{'msgcallr'};

	#if this is not a message from a normal phone (e.g. has alpha characters) it 
	#will exit
	if ($sender =~ m/[a-z]/){return;}
	if ($sender eq "O2-UK"){
		print "Service message, ignoring...\n";
		return;
	}
	
	print $rsd->[$i]{'lang'} . "lang txt received!";
	switch($func){
		#runs a sub with appropriate variables depending on what function
		#the message is attempting to use
		case ($sendmark){
			print "--send action\n";
			&send_manager( 	 $rerr_q,
					 $rsd, $i);
		}case ($rmvmark){
			print "--rmv action\n";
			&rmv_manager(	$rerr_q,
					$rsd->[$i]{'msgcallr'},
					$rsd->[$i]{'list'});	

		}case ($errmark){
		
			print "--user mistake\n";
			&mistake_manager($rerr_q, 
					 $rsd->[$i]{'msgcallr'}
					 );
		}case ($langmark){

			print "--user language change\n";
			&lang_manager(	$rerr_q,
					$rsd->[$i]{'msgcallr'},
					$rsd->[$i]{'lang'},
					$rsd->[$i]{'list'});		 

		}case ($rfshmark){
			print "--user membership refreshed\n";
			&rfsh_manager(	$rerr_q,
					$rsd->[$i]{'msgcallr'}
					);
	
		}else{
			print "--Parsing error in function assignment\n";
		}

	}
}


sub rfsh_manager{


	my ($rerr_q, $number) = @_;

	my $num_id = $dbd2->check_telnumber($number);
	$dbd2->la_update_telnumber($number, $num_id);

	my $num_lang_id = $dbd2->check_no_has_lang($num_id);
	
 	my $sysmsg = &sys_msg_finder($num_lang_id, @MSG_REFRESH);
	
	push @{$rerr_q}, $phone->send_sms($sysmsg, $number);

	$dbd2->update_exp_warnings($number, 0);

}


sub lang_manager{
	
	my ($rerr_q, $number, $lang, $list) = @_;
	my $sysmsg;
	my $num_id = $dbd2->check_telnumber($number);
	my $lang_id = &lang_findbyname($lang);

	unless($lang_id == -1){	
	
		$dbd2->update_number_lang($num_id, $lang_id);
		
		$sysmsg = &sys_msg_finder($lang_id, @MSG_CONF_NUM_LNG);
		&sys_msg_sub_langid(\$sysmsg, $list, $lang_id);

	}else{
		my $num_lang_id = $dbd2->check_no_has_lang($num_id);

		$sysmsg = &sys_msg_finder($lang_id, @MSG_INVLD_CMND);

	}
	
	
	#sends the message, puts it in the error_queue in case of something going wrong
	push @{$rerr_q}, $phone->send_sms($sysmsg, $number);

}

sub lang_findbyname{
	
	my $lang = shift;
	my @lang_ass = @LANG_ASSGN;
	my $size = @lang_ass;
	my $return = -1;	

	for(my $i = 0; $i < $size; $i++){
		
		my $rnames = $lang_ass[$i]{'lng_name'};
		my $lsize = @{$rnames};
		my $lang_id = $lang_ass[$i]{'lng_id'};	
		print $lang_id . " will be considered\n";
		for(my $j = 0; $j < $lsize; $j++){
			print $rnames->[$j] . " was checked\n";
			
			if ($rnames->[$j] eq lc($lang)){
						
				$return = $lang_id;
				print $return . "was sent for return\n";
			}

		}

	}
	print $return . " was returned";
	return $return;

}

sub lang_findbyid{
	
	my $lang_id = shift;
	my @lang_ass = @LANG_ASSGN;
	my $size = @lang_ass;
	my $return = 'your_language';	
	

	for(my $i = 0; $i < $size; $i++){
	
		if ($lang_ass[$i]{'lng_id'} == ($lang_id)){
					
			$return = $lang_ass[$i]{'lng_name'}->[0];
		}
	}

	return $return;

}

sub mistake_manager{ #This sub controls the response of the system if a keyword is not properly specified.
	
	my ($rerr_q, $number) = @_;
	my $number_id = $dbd2->check_telnumber($number);
	my $lang_id = $dbd2->check_no_has_lang($number_id);	

	
	unless ($lang_id) {

			$lang_id = DFLT_LANG; #needs to refer to default lang (see settings)

	}

	#checks to see if the number is in the database.  If so, sends an error message.
	#If not, it ignores it - reduces chance of unwelcome user on the system
	if ($number_id != -1){

		my $sysmsg = &sys_msg_finder($lang_id, @MSG_INVLD_CMND);
		push @{$rerr_q}, $phone->send_sms($sysmsg, $number);
	}

}


sub rmv_manager{
	#grabs ref to error queue, tel number, list name and language
	my ($rerr_q, $number, $list) = @_;
	
	#checks number and list are both in the database/
	my $num_id = $dbd2->check_telnumber($number);
	my $list_id = $dbd2->check_listname($list);
	my $msg;

	my $list_lang_id = &listlang_fallbacks($list_id, $num_id);


 	if ($num_id && $list_id){# if number and list exist then...

		#removes number from the members of this list in the db and sets the msg
		&rmv_from_list($rerr_q, \$msg, $number, $list, $num_id, $list_id, $list_lang_id);

	#/
	}else{
         	#sets the system sms to the result of the sub to find the correct system sms
		my $sysmsg = &sys_msg_finder($list_lang_id, @MSG_INVLD_MMBR);
		&sys_msg_sub_langid(\$sysmsg, $list, $list_lang_id);
	#sends the message, puts it in the error_queue in case of something going wrong
		push @{$rerr_q}, $phone->send_sms($sysmsg, $number);
	}
}

sub rmv_from_list{
	
	#grabs reference to the message that will be send out, list, number id and list id and lang id	
	my ($rerr_q, $rmsg, $number, $list, $num_id, $list_id, $list_lang_id) = @_;

	#remove number from members of the list
	my ($num_result, $list_result) = $dbd2->ctrl_dlt_commands($num_id, $list_id);		

	my $sysmsg;

	#sets a message according to whether the list still has members.
	if($list_result){#if list still has members then...
               #sets the system sms to the result of the sub to find the sms: leaving network
               $sysmsg = &sys_msg_finder($list_lang_id, @MSG_CONF_LVE_LST);

		#runs sub to notify all that a member has left
		my $notify = &rmv_notify($rerr_q, $list, $list_id, $list_lang_id);
	}else{
                #sets the system sms to the result of the sub to find the sms: leaving network				
		# and network following deleted
               $sysmsg = &sys_msg_finder($list_lang_id, @MSG_LVE_ND_DLT_LST);

	}
	&sys_msg_sub_langid(\$sysmsg, $list, $list_lang_id);
        #sends the message, puts it in the error_queue in case of something going wrong
        push @{$rerr_q}, $phone->send_sms($sysmsg, $number);
}

sub rmv_notify{
#This notifies all members that someone has removed themselves from a list
	my ($rerr_q, $list, $list_id, $list_lang_id) = @_;

	my @listnums = $dbd2->get_numbers($list_id, 0);

	my $sysmsg = &sys_msg_finder($list_lang_id,@MSG_RM_MMBER);
	&sys_msg_sub_langid(\$sysmsg, $list, $list_lang_id);		

	push @{$rerr_q}, $phone->send_sms($sysmsg, @listnums);

}

sub listlang_fallbacks{
#goes back through list, user and then to default language if any are undetermined.
	
	my ($list_id, $num_id) = @_;

	my $list_lang_id = $dbd2->check_list_has_lang($list_id);
	unless  ($list_lang_id){
		$list_lang_id = $dbd2->check_no_has_lang($num_id);

		unless ($list_lang_id){
			$list_lang_id = DFLT_LANG;
		}

	}

}

sub send_manager{

	#retrieves number, list, message sent
	my ($rerr_q, $rsd, $i) = @_;
	my %id = ();
	my %result = ();
	
	$dbd2->update_exp_warnings($rsd->[$i]{'msgcallr'}, 0);

	$id{'sent_lang'} = -1;
	if($rsd->[$i]{'lang'} ne "#empty#"){
	
		$id{'sent_lang'} = &lang_findbyname($rsd->[$i]{'lang'});
		
	}

	print $id{'sent_lang'} . "was the sent lang id!\n";

	#returns the list id and the list result.  List result is 0 (false) if the list
	#was already in the database, 1 (true) if the list was new and had to be added.
	($id{'list'}, $result{'list'}) = $dbd2->ctrl_listname($rsd->[$i]{'list'});
	
	#runs a sub to check if the number is in the database at all, sends welcome
	#and adds it if it isn't.  Returns the number id to num_id
	($id{'num'}, $id{'list_lang'}) = &fc_telnumber($rerr_q, $rsd->[$i]{'msgcallr'}, $id{'list'}, $rsd->[$i]{'list'});
	
	#returns the numlist id and the numlist result.  Numlist_result is 0 (false) if the number
	#was already a member of the list, 1 (true) if it wasn't and had to be added.
        
	(    $id{'numlist'},
                $result{'numlist'}
           ) = $dbd2->ctrl_numlist($id{'num'}, $id{'list'});

#	print "langid:" . $rsd->[$i]{'lang'} . "\n";	
#	print "numid:" . $id{'num'} . "\n";
#	print "listid:" . $id{'list'} . "\n";
#	print "numlistid:" . $id{'numlist'} . "\n";
#	print "numlistresult:" . $result{'numlist'} . "\n";
#	print "sent_lang:" . $id{'sent_lang'} . "\n";


	#sets up the error queue to be passed back.
	#move to subroutines
        
	&send_actions($rerr_q, $rsd, $i, \%result, \%id);

}


sub send_actions{
	#grabs ref to error queue, list result, list name, sender no.
	my ($rerr_q, $rsd, $i, $rresult, $rid) = @_;
	my $sysmsg;

	
	if ($rresult->{'list'}){ #is this a new list?
                #sets the system sms to the result of the sub to find the correct system sms
        	$sysmsg = &sys_msg_finder($rid->{'list_lang'}, @MSG_NW_LST);
		&sys_msg_sub_langid(\$sysmsg, $rsd->[$i]{'list'}, $rid->{'sent_lang'});
        #sends the message, puts it in the error_queue in case of something going wrong
        	push @{$rerr_q}, $phone->send_sms($sysmsg, $rsd->[$i]{'msgcallr'});

        }elsif ($rresult->{'numlist'}){ # are they a new member??
               # if so, sends welcome message
		&join_list($rerr_q, $rsd, $i, %{$rid}); #goes to sub

	}elsif ($rid->{'sent_lang'} > -1){
		
		$dbd2->update_list_lang($rid->{'list'}, $rid->{'sent_lang'});
	
                #sets the system sms to the result of the sub to find the correct system sms
        	$sysmsg = &sys_msg_finder($rid->{'sent_lang'}, @MSG_CONF_LST_LNG);
		&sys_msg_sub_langid(\$sysmsg, $rsd->[$i]{'list'}, $rid->{'sent_lang'});
        #sends the message, puts it in the error_queue in case of something going wrong
        	push @{$rerr_q}, $phone->send_sms($sysmsg, $rsd->[$i]{'msgcallr'});

        }else{
		#if the above are false, will send the message out to all members
		my @listnums = $dbd2->get_numbers($rid->{'list'}, 0);
		push @{$rerr_q}, $phone->send_sms($rsd->[$i]{'msgtxt'}, @listnums);
	}

}

sub fc_telnumber{
 
	my ($rerr_q, $number, $list_id, $list) = @_;
        #checks number exists, adds if not, retrieves numberID and whether number needed 
        #to be added
        my (    $num_id,
                $num_result
           ) = $dbd2->ctrl_telnumber($number);
	my $sysmsg;
	my $list_lang_id = &listlang_fallbacks($list_id, $num_id);

        #checks if number needed to be added.
        if ($num_result){
                
		#sets the system sms to the result of the sub to find join- sms
                #$sysmsg = &sys_msg_finder($list_lang_id, @MSG_WLCM);
		$dbd2->update_number_lang($num_id, $list_lang_id);
		
		#substitutes NWRK and LNNGE in the message with their proper names
		#&sys_msg_sub_langnme(\$sysmsg, $list, $list_lang_id);
		#sends the message, puts it in the error_queue in case of something going wrong
                #push @{$rerr_q}, $phone->send_sms($sysmsg, $number);


	}
	return $num_id, $list_lang_id;

}

sub join_list{
		#grabs ref to error queue, list, number and list id 
		my ($rerr_q, $rsd, $i, %id) = @_;
		my $sysmsg;

                #sets the system sms to the result of the sub to find join- sms
                $sysmsg = &sys_msg_finder($id{'list_lang'},  @MSG_JOIN);
                #sends the message, puts it in the error_queue in case of something going wrong
               
		&sys_msg_sub_langid(\$sysmsg, $rsd->[$i]{'list'}, $id{'list_lang'});		
		push @{$rerr_q}, $phone->send_sms($sysmsg, $rsd->[$i]{'msgcallr'});

		#gets all numbers which are a part of this list.
		my @listnums = $dbd2->get_numbers($id{'list'}, $id{'num'});

                my $sysmsg2 = &sys_msg_finder($id{'list_lang'},@MSG_NW_MMBER);
		&sys_msg_sub_langid(\$sysmsg2, $rsd->[$i]{'list'}, $id{'list_lang'});		

		push @{$rerr_q}, $phone->send_sms($sysmsg2, @listnums);

}

sub sys_msg_sub_langnme{

	my ($rmessage, $list_nme, $lang_nme) = @_;
	${$rmessage} =~ s/NWRK/$list_nme/g;
	${$rmessage} =~ s/LNGGE/$lang_nme/g;
}

sub sys_msg_sub_langid{

	my ($rmessage, $list_nme, $lang_id) = @_;
	my $lang_nme = &lang_findbyid($lang_id);

	${$rmessage} =~ s/NWRK/$list_nme/g;
	${$rmessage} =~ s/LNGGE/$lang_nme/g;
}
