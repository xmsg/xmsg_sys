

 # Project: x_msg invisible activist machinery
 # File name: xmsg_phone_comms.pm
 # Description:  Provides subroutines to phone interactions
 # Authors: Alexandra Joensson and Cliff Hammett
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


#!/usr/bin/perl

#this code sends out a sms to x numbers using gnokii
#also creates log files for all error files and a separated newest error-only file

use warnings;
use strict;


package xmsg_phone_comms;
{

	sub new { bless {}, shift }


	sub download_msgs{
		my $This = shift;
		my $path = shift;
		`/usr/bin/gnokii --getsms SM 1 end -d >$path`;
	}



	sub send_sms{
		
		#this takes and removes the first value that has been put 
		#into the subroutine's array
		my $This = shift;
		my $message = shift;

		#this puts the rest of the subroutine's array into @numbers
		my @numbers = @_;		
		my @error = ();
		# divides the units in the errorfiles
		my $line3 = "--------------------------------";
		

		#foreach loop sends off msg from gnokii and creates error files
		foreach my $i(@numbers){ 
		
			my $errtest = 0;
			my $errtest2 = 0;
			my $cnt = 0;
			my $success = 0;
			#conditions for loop
			while($success == 0 && $cnt < 3){
				#gnokii sends out sms and standart output for that action is put in file: error.txt
				my $length = length($message);

				my $kk = `rm error.txt`;

				my $ll = `touch error.txt`;

	#			my $gnokback = `echo $message | gnokii --sendsms $i 2>error.txt`;
				my $gnokback = `echo $message | gammu --sendsms TEXT $i -autolen $length >error.txt`;
				#setting the conditions for file  errorall.txt which contains all the errors (from error.txt) 
				#+ with timedate stamp and divisons
				my $timedate = `date 1>>errorall.txt`;
				my $nn = `cat error.txt 1>>errorall.txt`; 
				my $xx = `echo $line3 1>>errorall.txt`; 

				#keyword search for succesful send action
				$errtest = `grep -c "OK" ./error.txt`;
				$errtest2 = `grep -c "Segmentation fault" ./error.txt`;	
				#optional way to do the above search
				
				print $errtest;
				if ($errtest > 0 || $errtest2 > 0){
					print 'success!';
					$success = 1;
				}
					
				sleep 1 + $cnt;
				$cnt++;

				
				if ($cnt == 3){

					push @error, {msg=> $message, num => $i, tries => 1};
				
				}			
		
			}	
		
		}

		return @error;	
	}

}
#redirect output
1;		
	
#	push (@backarray, $gnokback); 	
#		
#	


 
