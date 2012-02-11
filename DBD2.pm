

 # Project: x_msg invisible activist machinery
 # File name: DBD2.pm
 # Description: Sets up database interaction subroutines 
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





use strict;
use warnings;
use Settings;

package DBD2;
{
    use Settings;
    use DBI;

    use constant FOUND     => 1;
    use constant NOT_FOUND => 0;

    sub new {
        my $class = shift;
        my $This  = {};

        bless $This, $class;
        return $This;
    }

    sub Connect_DB {
        my ($This, $User, $Pass) = @_;	
        $This->{Dbh} = DBI->connect(
            MYSQL_DB,
            $User,
            $Pass,
            {
                PrintError => MYSQL_PRINT_ERROR, #don't report errors via warn
                RaiseError => MYSQL_RAISE_ERROR, #Report errors via die
            }
        );
        return "ERROR: MSQL:\n Did not connect to (MYSQL){DB}: Maybe MYSQL is not setup " unless defined $This->{Dbh};
 
        return;
    }

    sub Init_DB {
        my $This = shift;
        # create the rables of the Monster
        #no strict "refs";
        my @Tables = keys(%MYSQL_TABLES);
        foreach (@Tables) {
            print "\n making table $_ ";
            my $query = $This->{Dbh}->prepare( $MYSQL_TABLES{$_} )
              or return "\n<P>ERROR: MSQL:<P>\n Can't prepare SQL $DBI::errstr\n";
            $query->execute
              or return "\n<P>ERROR: MSQL:<P>\n Can't execute SQL $DBI::errstr\n";
        }
        return;
    }

# special stuff to disconect properly from the database.
#
    sub Disconnect_DB {
        my $This = shift;
        # connect to database (regular DBI)
        $This->{Dbh}->disconnect;
        return;
    }

    sub DESTROY {
        my $This = shift;
        $This->Disconnect_DB unless not defined $This->{Dbh};

    }




	#this is the control subroutine for when we get a telephone number in
	sub ctrl_telnumber{
		
		#this defines number_id and assigns it to the NumberID retrieved by the subroutine
		# check_telnumber
		my $number_id;
	 	$number_id = &check_telnumber(@_);
			
		#checks to see if a NumberID was returned
		if($number_id){
			#if one, it uses the subroutine la_update_telnumber to update the activity data and 
			#returns the NumberID
			&la_update_telnumber(@_, $number_id);
			return ($number_id, 0);
		}else{
			#if one wasn't, it uses the subroutine add_telnumber to add the number to the list,
			#it then retrieves that numberID with check_telnumber and returns it.
			&add_telnumber(@_);
			$number_id = &check_telnumber(@_);
			return ($number_id, 1);
		}
			
		

	}

	#this adds the telephone number to tblNumbers
	sub add_telnumber {

		#this takes the values passed to the subroutines (a hash containing DB info, 
		# and the telephone number
		my ( 	$This,
                        $tel_no,
                ) = @_;


		#this puts the telephone number in quote marks for insertion.
                my $qtel_no = $This->{Dbh}->quote($tel_no);

		#this readies the query...
                my $query = $This->{Dbh}->prepare(
                        "INSERT INTO tblNumbers
                        (
                                TelNumber,
				LastActivity
                        ) 
                        values(
                                $qtel_no,
				CURDATE()
                        )"
              	);

		#... executes it ...
                $query->execute;

		#and then finshes it.
                $query->finish;
        	

	}

	#this runs a query to see if the telephone number exists, and returns the NumberID
	sub check_telnumber{

                #this takes the values passed to the subroutines (a hash containing DB info, 
                # and the telephone number
                my (    $This,
                        $tel_no,
                ) = @_;

 		#this puts the telephone number in quote marks for the check.
                my $qtel_no = $This->{Dbh}->quote($tel_no);

                #this readies the query...
                my $query    = $This->{Dbh}->prepare(

                        "SELECT NumberID FROM tblNumbers WHERE TelNumber =$qtel_no "
                );

                #... executes it
                $query->execute;

		#this sets the number id to the returned value.  Not sure what the point of the = -1 bit is
		#but the scripts working so I'll leave it
                my $number_id = -1;
                ($number_id) = $query->fetchrow_array;
                $query->finish;
		
		#returns the result of the query
		return $number_id;
	
	}


	#This one updates the LastActivity date to today's date.  
	sub la_update_telnumber{

 
                #this takes the values passed to the subroutines (a hash containing DB info, 
                # and the telephone number and the NumberID) and assignes them to variables

                my (    $This,
			$tel_no,
                        $no_id,
                ) = @_;

		#then this prepares and runs the query
                my $query    = $This->{Dbh}->prepare(


                        "UPDATE tblNumbers SET LastActivity=(CURDATE()), Warn=0  WHERE NumberID =$no_id "
                );
                $query->execute;
                $query->finish;
	

	}


	sub ctrl_numlist{
		
	#the second returned value represents if the sub had to add the number as a member of the list.
	#i.e. returns 0 (false) if it is a member, 1 (true) if is not a member.
	# confusing, eh?
		my $numlist_id = &check_numlist(@_);				
		
		if ($numlist_id){
	
			return ($numlist_id, 0);	
	
		}else{
			
			&add_numlist(@_);	
			$numlist_id = &check_numlist(@_);
			return ($numlist_id, 1);

		}


	}	


	sub check_numlist{

               #this takes the values passed to the subroutines (a hash containing DB info, 
               # + the NumberID and the List ID) and passes it to variables

                my (    $This,
                        $number_id,
                        $list_id
                   ) = @_;



                #this readies the query...
                my $query    = $This->{Dbh}->prepare(

                        "SELECT NumListID FROM tblLinkNumList WHERE NumberID =$number_id AND ListID =$list_id "
                );

                #... executes it
                $query->execute;

                #this sets the number id to the returned value.  Not sure what the point of the = -1 bit is
                #but the scripts working so I'll leave it
                my $numlist_id = -1;
                ($numlist_id) = $query->fetchrow_array;
                $query->finish;

                #returns the result of the query
                return $numlist_id;


		
	}

	sub add_numlist{

               #this takes the values passed to the subroutines (a hash containing DB info, 
               # + the NumberID and the List ID) and passes it to variables

                my (    $This,
                        $number_id,
                        $list_id
                   ) = @_;

		#this readies the query...
                my $query = $This->{Dbh}->prepare(
                        "INSERT INTO tblLinkNumList
                        (
                                ListID,
                                NumberID
                        ) 
                        values(
                               
				 $list_id,
				 $number_id
                                
                        )"
                );

                #... executes it ...
                $query->execute;

                #and then finshes it.
                $query->finish;

		#write a function to get the last inserted id.

	}
	


        #this is the control subroutine for when we get a Listmane in
        sub ctrl_listname {

                #this defines list_id and assigns it to the listID retrieved by the subroutine
                # check_listid
                my $list_id;
                $list_id = &check_listname(@_);

                #checks to see if a ListID was returned
                if($list_id){
                        	
			#if zero return list_id 

			return ($list_id, 0);
                }else{
                        #if one it uses the  subroutine &add_listname(@_); to add the new list.
                        #it then retrieves that ListID  with check_listname and returns it.
                        &add_listname(@_);
                        $list_id = &check_listname(@_);
                        return ($list_id, 1);
                }

	}





        #this runs a query to see if the list name  exists, and returns the ListID
        sub check_listname{

                #this takes the values passed to the subroutines (a hash containing DB info, 
                # and the list_name
                my (    $This,
                        $list_name,
                ) = @_;

                #this puts the list_name in quote marks for the check.
                my $qlist_name = $This->{Dbh}->quote($list_name);

                #this readies the query...
                my $query    = $This->{Dbh}->prepare(

                        "SELECT ListID FROM tblLists WHERE ListName =$qlist_name "
                );

                #... executes it
                $query->execute;

                #this sets the list_ id to the returned value.  Not sure what the point of the = -1 bit is
                #but the scripts working so I'll leave it
                my $list_id = -1;
                ($list_id) = $query->fetchrow_array;
                $query->finish;

                #returns the result of the query
                return $list_id;

        }

	
	#this adds a new list to mysql DB
       sub add_listname {

                #this takes the values passed to the subroutines (a hash containing DB info, 
                # and the list_name
                my (    $This,
                        $list_name,
                ) = @_;


                #this puts the list name  in quote marks for insertion

                my $qlist_name = $This->{Dbh}->quote($list_name);

                #this readies the query...
                my $query = $This->{Dbh}->prepare(
                        "INSERT INTO tblLists

                        (
                                ListName
                       
                        ) 
                        values(
                                $qlist_name                               
                        )"
                );

                #... executes it ...
                $query->execute;

                #and then finshes it.
                $query->finish;

	}


	# this get the number from joint tables tblLinkNumList and tblNumbers
        sub get_numbers {
		# this takes the values passed to the subroutines (a hash containing DB info, 
                # and the list_id

                my (    $This,
                         $list_ID,
			 $num_id
                ) = @_;

		#num_id here is a number id that will be excluded e.g. that you do not
		#want to send a message to
		unless ($num_id){
			$num_id = 0;
		}

                my $query = $This->{Dbh}->prepare(

                        "SELECT TelNumber
                        FROM tblLinkNumList LEFT JOIN tblNumbers 
                        ON tblLinkNumList.NumberID = tblNumbers.NumberID
                        WHERE  ListID = $list_ID AND tblNumbers.NumberID <> $num_id
                ");

                #... executes it ...
                $query->execute;
		my @numbers;
		

		while (my $check = $query->fetchrow_array){
			push @numbers, $check;
		}			
	
                #and then finshes it.
                $query->finish;

                return @numbers;
	}    



        sub get_exp_numbers {
		# this takes the values passed to the subroutines (a hash containing DB info, 
                # and the list_id

                my (    $This,
                         $interval,
			 $warn
                ) = @_;

                my $query = $This->{Dbh}->prepare(

                        "SELECT Telnumber
                        FROM tblNumbers 
                        WHERE LastActivity < SubDate(CurDate(), INTERVAL $interval DAY) AND Warn = $warn
                ");
		
		
                #... executes it ...
                $query->execute;
		my @numbers;
		
		while (my $check = $query->fetchrow_array){
			push @numbers, $check;
		}			
	
                #and then finshes it.
                $query->finish;
	
		return @numbers;
	}


	sub update_exp_warnings{
	
		my (
			$This,
			$tel,
			$warnings
		) = @_;

                my $query = $This->{Dbh}->prepare(
                "UPDATE tblNumbers
		SET Warn = $warnings     
                WHERE Telnumber = $tel
                ");

                $query->execute;

                $query->finish;

	}

	# this sub routine deletes an entry in tblLinkNumList when a msg with a 'unsubscribe from list' command is recieved,.
	sub delete_frm_tblLinkNumList {

                my (
                        $This,
                        $number_id,
                        $list_id

                ) = @_;

                my $query = $This->{Dbh}->prepare(
                "DELETE FROM tblLinkNumList     
                WHERE NumberID = $number_id
                AND ListID = $list_id
                ");

                $query->execute;

                #and then finshes it.
                $query->finish;

        }

	#this subroutine checks if there are any remainig numbers on the list when one number is removed.
 	sub check_list_has_numbers {

               #this takes the values passed to the subroutines (a hash containing DB info, 
               # + the List ID) and passes it to variables

                my (    $This,
                        $list_id

                   ) = @_;

                #this readies the query...
                my $query    = $This->{Dbh}->prepare(

                        "SELECT NumberID FROM tblLinkNumList 
                        WHERE ListID = $list_id"
                );

                #... executes it
                $query->execute;

                #this sets the number id to the returned value.  Not sure what the point of the = -1 bit is
                #but the scripts working so I'll leave it
                my $number_id = -1;
                ($number_id) = $query->fetchrow_array;
                $query->finish;

                # if number_id has the value one no action is taken, if the value is zero then use subsroutine
		#  &delete_frm_tblLists(_@); to delete the list because it is empty.
              	if ($number_id){
                        return 1;
                }else {
                        return 0;
                }	
		
		&delete_frm_tblLists(@_);

	}

	#this subroutine deletes list from tbllist by using the passed values from DB+list_id
	sub delete_frm_tblLists {

                my (
                        $This,
                        $list_id
                ) = @_;

                my $query = $This->{Dbh}->prepare(
                "DELETE FROM tblLists     
                WHERE ListID = $list_id

                ");

                $query->execute;

                #and then finshes it.
                $query->finish;
	}

	# this subroutine check if a number is subscribed to any other lists (after requesting being removed from one)
	 sub check_number_has_lists {

               #this takes the values passed to the subroutines (a hash containing DB info, 
		# + the NumberID and passes it to variables

                my (    $This,
                        $number_id

                   ) = @_;



                #this readies the query...
                my $query = $This->{Dbh}->prepare(

                        "SELECT ListID FROM tblLinkNumList 
                        WHERE NumberID = $number_id"
                );

                #... executes it
                $query->execute;

                #this sets the number id to the returned value.  Not sure what the point of the = -1 bit is
                #but the scripts working so I'll leave it
                my $list_id = -1;
                ($list_id) = $query->fetchrow_array;
                $query->finish;

                #returns the result of the query
                if ($list_id){
                        return 1;
                }else {
                        return 0;
                }
	}

	# this subroutine deletes an entry from tblNumbers by using the passed values from DB+number
	sub delete_frm_tblNumbers {

                my (
                        $This,
                        $number_id,


                ) = @_;

                my $query = $This->{Dbh}->prepare(
                "DELETE FROM tblNumbers     
                WHERE numberID = $number_id

                ");

                $query->execute;

                #and then finshes it.
                $query->finish;
	}

	#this subroutine erases all of the user's list memberships
	sub delete_frm_all_lists {

		my (
			$This,
			$number_id

		) = @_;

		my $query = $This->{Dbh}->prepare(
		"DELETE FROM tblLinkNumList
		WHERE numberID = $number_id
		
		");

		$query->execute;
		$query->finish;

	}

	

	#this subroutine controls the delete-subroutines when a msg is recieved with a delete command
	#using the values passed fromt the DB+numberid+listid
	sub ctrl_dlt_commands {

                 my (
                        $This,
                        $number_id,
                        $list_id

                ) = @_;

		#deletes entry from tblLinkNumlist
                &delete_frm_tblLinkNumList(@_);
		
		#check if list has any more numbers
               my $listresult = &check_list_has_numbers ($This, $list_id);

		#if the list is empty, delete the list from tblLists
                if ($listresult == 0){
                        &delete_frm_tblLists ($This, $list_id);
                }

		#check number is on any other lists
                my $numberresult = &check_number_has_lists ($This, $number_id);
		
		#if the number is not on any other list, delete the number from tblNumbers
                 if ($numberresult == 0) {
                        &delete_frm_tblNumbers ($This, $number_id);
                }
                return ($numberresult, $listresult);
        }

	sub check_list_has_lang {
  
                  my (    $This,
                          $list_id
                   ) = @_;
  
                  my $query = $This->{Dbh}->prepare (
  
                "SELECT LangID FROM tblLists
                WHERE ListID = $list_id
		");
 
                 $query->execute;
        	 my $lang_id = -1;
              	 ($lang_id) = $query->fetchrow_array;
               	 $query->finish;
 
                 return $lang_id;
 
 
        }
 
 
                 #send out request to sender
 
	sub check_no_has_lang {
 
                 my (    $This,
                         $number_id
                 ) = @_;  
               
		if (not($number_id > 0)){

			return -1;
		}
 
                 my $query = $This->{Dbh}->prepare(
                 
                 "SELECT LangID FROM tblNumbers
                 WHERE NumberID = $number_id
		");

                 $query->execute;	
                 my $lang_id = -1;
                 ($lang_id) = $query->fetchrow_array;
                 $query->finish;
                 
                 return $lang_id;
 
 	}

	sub check_no_has_lang_bytel {
 
                 my (    $This,
                         $telno
                 ) = @_;  
                
                 my $query = $This->{Dbh}->prepare(
                 
                 "SELECT LangID FROM tblNumbers
                 WHERE Telnumber = $telno
		");

                 $query->execute;	
                 my $lang_id = -1;
                 ($lang_id) = $query->fetchrow_array;
                 $query->finish;
                 
                 return $lang_id;
 
 	}


	sub update_list_lang{



                my (    $This,
			$list_id,
                        $lang_id,
                ) = @_;

		#then this prepares and runs the query
                my $query    = $This->{Dbh}->prepare(

                        "UPDATE tblLists SET LangID= $lang_id  WHERE ListID =$list_id "

                );
                $query->execute;
                $query->finish;

	}
		
	sub update_number_lang{

                my (    $This,
			$number_id,
                        $lang_id,
                ) = @_;

		#then this prepares and runs the query
                my $query    = $This->{Dbh}->prepare(

                        "UPDATE tblNumbers SET LangID= $lang_id  WHERE NumberID =$number_id "

                );
                $query->execute;
                $query->finish;

	}


	sub retrieve_table{
	#this is primarily used by xmsg_config to retrieve a lot of date.
	#actually I could have made a few subs like this rather than 30 odd doing similar things
	#oh well
		
                my (    $This,
                         $rf_length,
			 $fields,
			 $table,
			 $condition
                 ) = @_;  
                
                my $query = $This->{Dbh}->prepare(
                 
                 "SELECT $fields FROM $table $condition
		");

                $query->execute;	
                my @return;
	
                if (my @row = $query->fetchrow_array){
			${$rf_length} = @row;
			push (@return, @row);		 
			while (@row = $query->fetchrow_array){

				push (@return, @row);		 
			}		
		}else{
			${$rf_length} = 0; 
		}

                $query->finish;
                 
                return @return;
 
 	}


	sub wipe_table{

		my ($This, $table) = @_;

                my $query = $This->{Dbh}->prepare(

		"DELETE FROM $table"
		);

		$query->execute;
		$query->finish;
	}


	sub insert_into_table{

		my ($This, $fields, $table, $values) = @_;

		my @val = split(/;/, $values);

		my $size = @val;
		my $prepvals;

		for (my $i = 0; $i < $size; $i++){

			if ($i > 0){
				$prepvals = $prepvals . ',';
			}
			print $val[$i] . "\n";
			
			if(($val[$i] =~ m/\D/) ||
			   ($val[$i] =~ m/0\d.*/)) {
				
                		$val[$i] = $This->{Dbh}->quote($val[$i]);
			}

			if ($val[$i] eq ""){$val[$i]='NULL'};

			$prepvals = $prepvals . $val[$i];
		}

		$prepvals =~ s/\s//g;
		print $prepvals;

                my $query = $This->{Dbh}->prepare(

		"INSERT INTO $table ($fields) VALUES($prepvals)"
		);

		$query->execute;
		$query->finish;
	}

	sub check_like_telnumber{

                #this takes the values passed to the subroutines (a hash containing DB info, 
                # and the telephone number
                my (    $This,
                        $tel_no,
                ) = @_;

 		#this puts the telephone number in quote marks for the check.
                my $qtel_no = $This->{Dbh}->quote($tel_no);

                #this readies the query...
                my $query    = $This->{Dbh}->prepare(

                        "SELECT NumberID FROM tblNumbers WHERE TelNumber LIKE $qtel_no "
                );

                #... executes it
                $query->execute;

		#this sets the number id to the returned value.  Not sure what the point of the = -1 bit is
		#but the scripts working so I'll leave it
                my @userid;
				
		while (my $check = $query->fetchrow_array){
			push @userid, $check;
		}			
		#returns the result of the query
		return @userid;
	
	}




	sub change_password {

		#this takes the values passed to the subroutines (a hash containing DB info, 
		# and the telephone number
		my ( 	$This,
			$user,
                        $password,
                ) = @_;


		#this puts the telephone number in quote marks for insertion.

                my $quser = $This->{Dbh}->quote($user);
                my $qpassword = $This->{Dbh}->quote($password);
		my $qhost =  $This->{Dbh}->quote("localhost");

		#this readies the query...
                my $query = $This->{Dbh}->prepare(
                        "SET PASSWORD FOR $quser\@$qhost = PASSWORD($qpassword)"
              	);

		#... executes it ...
                $query->execute;

		#and then finshes it.
                $query->finish;
        	

	}



}
1;

