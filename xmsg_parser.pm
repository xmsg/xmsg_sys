
 # Project: x_msg invisible activist machinery
 # File name: xmsg_parser.pm
 # Description:  Provides parsing functions to interpret incoming messages 
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
use warnings;
use Settings;


package xmsg_parser;
use Settings;
my (
	$sendmark,
	$rmvmark, 
	$errmark,
	$idmark,
	$langmark,
	$rfshmark) = (SYMB_SEND, SYMB_RMV, SYMB_ERR, SYMB_ID, SYMB_LANG, SYMB_RFSH);


{


        sub new { bless {}, shift }

	#Our first parsing subroutine, used to initialise the process!
	sub parse_start{
		print "Commencing parse";
		# sets the file it will look at, from the first argument in the subroutine
		my ($This, $filename, $rmessages, $rnotready) = @_;
			
		#opens the file with our text messages, puts all its data in an array, then closes the file
		open(MSGFILE, $filename) || die("could not open file");
		my @msgarray =  <MSGFILE>;
		close(MSGFILE);
		&parse_loop(\@msgarray, $rmessages, $rnotready);
		
		return 1;
	}

	sub parse_loop{
		
		my ($rmsgarray, $rmessages, $rnotready) = @_;
		#this detects the number of lines in @msgarray to allow our for loop to run properly.
		my $size = @{$rmsgarray};
		my @parsedmsg = ();

		#for loop, set to keep running until it's counted through every line of @msgarrary
		for (my $i = 0; $i < $size; ){
			#removes linebreak from entry
			chomp $rmsgarray->[$i];
			
			#a regular expression - if it starts with digits and contains the word message, it
			#will assign parts of the line to set variables.
			if($rmsgarray->[$i] =~ m/^(\d{1,2})\.(.*) Message(.*)/){

				#this takes the three variables taken from the line above, and assigns them
				#to variables. At only $box is used by the program 
				my $box =  $2;

				&parse_lookmsg($box, \@parsedmsg, \$i, $rmsgarray);			

			}else{$i++;} #if it's not a message line, go on to the next line.
				
		}

		&parse_sendback(\@parsedmsg, $rmessages, $rnotready);	

	}

	sub parse_lookmsg{

		my ($box, $rparsedmsg, $ri, $rmsgarray) = @_;
		my %this_msg = ();		

		#this runs the parse_boxjump subrotuine, passing the box value 
		#the line number and the whole set of messages
		my $hasmsg = &parse_boxjump($box, $ri, $rmsgarray, \%this_msg);

	#	print $hasmsg . "\n";	
		#for any sent messages, no further values will be returned.  This checks whether there
		#are further values before proceeding.

		if ($hasmsg){
			
			#this pushes the values returned as a hash in the main array that the subroutine
			#will eventually return
			push @{$rparsedmsg}, { %this_msg };
			print '.';

		}

	}

	sub parse_sendback{#attempts to resolve linked message issues and sends it back to
	#the arrays in xmsg_ctrl.pl	


		my ($rparsedmsg, $rmessages, $rnotready) = @_;	
		
		my @lnkresolve = ();
		my @notready = ();	
		if(@{$rparsedmsg}){
			@lnkresolve = &parse_lnkresolve(\@notready, @{$rparsedmsg});
		}
		print " Finishing parse\n";
	#	&print_msg_fields(@notready);

		@{$rmessages} = @lnkresolve;  
		push @{$rnotready}, @notready;		


	}



	sub parse_lnk_retry{
		
		my $This = shift;
		my $rnotready = shift;
		my @holder = ();
		
		push @holder, @{$rnotready};
			
		my $size = @holder;
		for (my $i = 0; $i < $size; $i++){

			$holder[$i]{'wait'} = 0;


		}
		
		undef @{$rnotready}; 
		@holder = &parse_lnkresolve($rnotready, @holder);
		
		return @holder;

	}

	sub parse_lnkresolve{

		my @lnkresolve = ();
		my $rnotready = shift;

		my @sd = sort	{ 

				$$b{'lnkttl'} <=> $$a {'lnkttl'} ||
				$$a{'lnkno'} <=> $$b{'lnkno'} ||
				$$a{'msgcallr'} cmp $$b{'msgcallr'} ||
				$$a{'dtno'} <=> $$b{'dtno'}

				} @_;

		my $size = @sd;

		for(my $i = 0; $i < $size; $i++){

		
			&concat_links(\$i, \@lnkresolve, \@sd, $rnotready);

		}
		return @lnkresolve;
	}


	sub concat_links{


		my ($ri, $rlnkresolve, $rsd, $rnotready) = @_;

		if ($rsd->[${$ri}]{'lnkttl'} > 1){		
		
			unless(&test_missinglink(@_)){
			
				my @msg1 = ($rsd->[${$ri}]);
				${$ri}++;
				my $cnt = 0;		
				
		#		if (&test_wholemsg(@_)){

				for(${$ri}; 
				    $rsd->[${$ri}]{'lnkno'} <= $rsd->[${$ri}]{'lnkttl'} &&  $rsd->[${$ri}]{'lnkttl'} >1; 
				    ${$ri}++ ){

					$msg1[0]{'msgtxt'} = 
					  $msg1[0]{'msgtxt'} . substr $rsd->[${$ri}]{'msgtxt'}, 1;
					
				}
		#		}
				push @{$rlnkresolve}, $msg1[0];

				print "LINK RESOLVER:\n";
	#			&print_msg_fields(@{$rlnkresolve});
				
			}
		}else{
				
			push @{$rlnkresolve}, $rsd->[${$ri}];
			
		}	


	}


	sub test_missinglink{ # checks to see if the message is still there, if not passes to array


		my ($ri, $rlnkresolve, $rsd, $rnotready) = @_;
		my @seq = ();
		my $sender = $rsd->[${$ri}]{'msgcallr'};
		my $total = $rsd->[${$ri}]{'lnkttl'};
		my $size = @{$rsd};
		my $track = 0;

		for(my $i = 0; $i < $total && $i < $size; $i++){
			
			my $p = ${$ri} + $i;
			#this performs three checks - that the message has the same sender,
			#total no of messages and correct place in sequence for a linked message.
			if ($rsd->[$p]{'msgcallr'} eq $sender &&
			     $rsd->[$p]{'lnkttl'} == $total &&
			     $rsd->[$p]{'lnkno'} == $i + 1){
				print "XXXXX detected correct message\n";

				$track++;
						
			}else {print "XXXXX detected error\n";}

		}

		unless($track == $total){

			for(my $i = 0; $i < $total && $i < $size; $i++){
			
				my $p = ${$ri} + $i;
				#this performs three checks - that the message has the same sender,
				#total no of messages and correct place in sequence for a linked message.
				if ($rsd->[$p]{'msgcallr'} eq $sender &&
				     $rsd->[$p]{'lnkttl'} == $total &&
				     $rsd->[$p]{'wait'} != 1){

					unless($rsd->[$p]{'tries'}){

						$rsd->[$p]{'tries'} = 1;

					}
					my @pusher = ($rsd->[$p]);
					push @{$rnotready}, @pusher;
					$rsd->[$p]{'wait'} = 1;
					print "XXXXX pushed msg to queue\n"
							
				}
		}
			
			return 1;

		}else {return 0;}


	}

	sub parse_boxjump{

		
		my ($box, $ri, $rarray, $rhash) = @_;

		${$ri}++;
		if ($box =~ m/Inbox/){
			&parse_datetime($ri, $rarray, $rhash);
			return 1;
		}elsif ($box =~ m/MO/){
			return 0;
		}else{
			my $sub = (caller(0))[3];
			&parse_logerror($sub, ${$ri}, 'Unexpected box name');
			return 0;
		}
		
	} 



	sub parse_datetime{
	#takes the line with the date and time and puts them in in our hash

		my ($ri, $rarr, $rhash) = @_;

		if($rarr->[${$ri}] =~ m/Date\/time: (\d\d)\/(\d\d)\/(\d\d\d\d) (\d\d):(\d\d):(\d\d)/) {
			
			${$ri}++;
			&parse_caller(@_);
			${$rhash}{'msgdate'} = "$1/$2/$3";		
			${$rhash}{'msgtime'} = "$4:$5:$6";		
			my $dateno = $3 . $2 . $1 . $6 . $5 . $4;
			${$rhash}{'dtno'} = $dateno + 0;
	#		print $dateno . "\n";
		}else{

			my $sub = (caller(0))[3];
		
			&parse_logerror($sub, ${$ri}, 'Expected line structure not present');
			${$ri}++;
		}

		
	}


	sub parse_caller{
	#takes the line with the sender's phone number and puts in in our hash
		my ($ri, $rarr, $rhash) = @_;


		chomp $rarr->[${$ri}];
		
		if($rarr->[${$ri}] =~ m/Sender: (.*) Msg Center: (.*)/) {
			
			${$ri}++;
			&parse_textheader(@_);
			${$rhash}{'msgcallr'} = $1;
		}else{

			my $sub = (caller(0))[3];

			&parse_logerror($sub, ${$ri}, 'Expected line structure not present');
			${$ri}++;
		}


	}


	sub parse_textheader{
		
		my ($ri, $rarr, $rhash) = @_;
		
		my $sub = (caller(0))[3];

		chomp $rarr->[${$ri}];
		if($rarr->[${$ri}] =~ m/Linked:/) {

			&parse_links(@_);

		}elsif($rarr->[${$ri}] =~ m/Text:/){
			
			${$rhash}{'lnkno'} = 1;
			${$rhash}{'lnkttl'} = 1;
			${$ri}++;
		}else{

			&parse_logerror($sub, ${$ri}, 'Unexpected string for linked mark');

		}

		&parse_msg(@_)	

	}


	sub parse_links{
	# 
		
		my ($ri, $rarr, $rhash) = @_;

		${$ri}++;

		if($rarr->[${$ri}] =~ m/Linked \((\d)\/(\d)\):/){
		
			${$ri}++;
			${$rhash}{'lnkno'} =  $1 + 0;
			${$rhash}{'lnkttl'} = $2 + 0;

		}else{ 

			my $sub = (caller(0))[3];
			&parse_logerror($sub, ${$ri}, 'Unexpected string after Linked:');
			${$rhash}{'lnkno'} = 1;
			${$rhash}{'lnkttl'} = 1;

		}
	}


	sub parse_msg{

		my ($ri, $rarr, $rhash) = @_;

		my ($func, $list, $lang, $msgtxt);	
		my $val = $rarr->[${$ri}];

		chomp $val;	
		

		#I'm sorry!  A very long if elsif elsif chain.  I must learn how to do regex in case statements...
		if ($val eq $rfshmark){

			($func, $list, $lang, $msgtxt) = ($rfshmark, '#empty#', '#empty#', '#empty#' );
		
			${$ri}++;

		}elsif (length($val) < 2){ 

			($func, $list, $lang, $msgtxt) = ($errmark, '#empty#', '#empty' , $val);
			${$ri}++;

		}elsif( $val =~ m/^($sendmark|$rmvmark)(.+?)\s(.+)/){#message to list
			# ^ means start at beginning of string		
			
			($func, $list, $lang, $msgtxt) = ($1, $2, '#empty#', $2 . $idmark . $3);
			
			if ($list =~ m/^(.+?)$langmark(.+)/){#set list lang with msg

				($list, $lang) = ($1, $2);
		
			}
			${$ri}++;
			

		}elsif ($val =~ m/^($sendmark|$rmvmark)(.+?)$langmark(.+)/){#set list lang only
			# ^ means start at beginning of string          
			($func, $list, $lang, $msgtxt) = ($1, $2, $3, '#empty#');
			${$ri}++;


		}elsif ($val =~ m/^($sendmark|$rmvmark)(.*)/){#only list comamnd

			($func, $list, $lang, $msgtxt) = ($1, $2, '#empty#', '#empty#' );
			${$ri}++;

		}elsif ($val =~ m/^($langmark)(.*)/){#only language

			($func, $list, $lang, $msgtxt) = ($1, '#empty#', $2, '#empty#' );
			${$ri}++;

		}elsif ($val =~ m/^($rfshmark)(.*)/){


			($func, $list, $lang, $msgtxt) = ($1, '#empty#', '#empty#', '#empty#' );
			
			${$ri}++;
		}else{

			($func, $list, $lang, $msgtxt) = ($errmark, '#empty#', '#empty' , $val);
			${$ri}++;

		}
					
		&fix_msg(\$msgtxt);

		#some values can't have certain characters or it can mess things up big style.
		$list =~ s/\s//g;
		$list =~ s/;//g;
		$lang =~ s/\s//g;	

		#sets values to 
		${$rhash}{'func'} = $func;
		${$rhash}{'list'} = $list;
		${$rhash}{'lang'} = $lang;
		${$rhash}{'msgtxt'} = $msgtxt;

		&parse_msglastlines(@_);

	}

	sub parse_msglastlines{


		my ($ri, $rarr, $rhash) = @_;
		my $size = @{$rarr};

		until ($rarr->[${$ri}] =~  m/^(\d{1,2})\.(.*) Message(.*)/
			|| ${$ri} >= $size ) {
			
			my $msgline = $rarr->[${$ri}];
			chomp $msgline;
			&fix_msg(\$msgline);
			${$rhash}{'msgtxt'} = ${$rhash}{'msgtxt'} . " " . $rarr->[${$ri}];
			${$ri}++;
		}

	}


	sub parse_logerror{
		
		my $sub = shift;
		my $place = shift;
		my $msg = shift;
		
		open(DAT,">>./errorlog_parse.txt") || die("Cannot Open File");
		print DAT $sub . "   " . $place . "   " . $msg . "\n";
		close(DAT); 

	}


	sub fix_msg{
	#this prepares the message and fixes quotemarks etc so it doesn't screw up the send command.

		my $rmsg = shift; # the actual message



		${$rmsg} =~ s/\\/\\\\/g;
		
		${$rmsg} =~ s/\(/\\\(/g;
		${$rmsg} =~ s/\)/\\\)/g;
		${$rmsg} =~ s/%/\\%/g;
		${$rmsg} =~ s/\$/\\\$/g;
		${$rmsg} =~ s/&/\\&/g;
		${$rmsg} =~ s/\*/\\\*/g;
		${$rmsg} =~ s/=/\\=/g;
		${$rmsg} =~ s/\+/\\\+/g;
		${$rmsg} =~ s/\[/\\\[/g;
		${$rmsg} =~ s/\]/\\\]/g;
		${$rmsg} =~ s/"/\\"/g;
		${$rmsg} =~ s/'/\\'/g;


		${$rmsg} =~ s/</\\</g;
		${$rmsg} =~ s/>/\\>/g;

		${$rmsg} =~ s/\#/\\\#/g;
		
		${$rmsg} =~ s/\|/\\\|/g;

		${$rmsg} =~ s/\^/\\\^/g;

		${$rmsg} =~ s/\{/\\\{/g;

		${$rmsg} =~ s/\{/\\\{/g;
		${$rmsg} =~ s/\£/\\\£/g;
		${$rmsg} =~ s/\€/\\\€/g;

		${$rmsg} =~ s/\~/\\\~/g;
		${$rmsg} =~ s/\//\\\//g;

	}

	sub print_msg_fields{ 
	#an inefficient script to print all the fields of all the messages in an array
		my @messages = @_; 

		
		if (@messages){
		       my $size = @messages;
		
		       for(my $i = 0; $i < $size; $i++){
		       
			       print 'Date: ' . $messages[$i]{'msgdate'} . "\n";
			       print 'Time: ' . $messages[$i]{'msgtime'} . "\n";
			       print 'DT no: ' . $messages[$i]{'dtno'} . "\n";
			       print 'Sender: ' . $messages[$i]{'msgcallr'} . "\n" ;
			       print 'Msg ' . $messages[$i]{'lnkno'};
			       print ' of ' . $messages[$i]{'lnkttl'} . "\n" ;
			       print 'Function: ' . $messages[$i]{'func'} . "\n";
			       print 'List: ' . $messages[$i]{'list'} . "\n";
			       print 'Msg: ' . $messages[$i]{'msgtxt'} . "\n";

		       }
	       }

	}
}
1;

