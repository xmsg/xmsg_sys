
 # Project: x_msg invisible activist machinery
 # File name: Settings.pm
 # Description:  Sets up language and other settings
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



package Settings;
require Exporter;
use encoding "utf8";
use Term::ReadKey;

@ISA     = qw(Exporter);
@EXPORT =
  qw (
    	%MYSQL_TABLES 
	MYSQL_DB
 	MYSQL_PRINT_ERROR MYSQL_RAISE_ERROR
	DFLT_LANG
	EXPIRING_MEMS
	EXPIRE_PERIOD
	WARN_DAYS_1
	WARN_DAYS_2
	EXP_MSG_HOUR
	@LANG_ASSGN
	@MSG_WLCM
	@MSG_JOIN
	@MSG_NW_LST 
	@MSG_SET_LNG
	@MSG_CONF_LST_LNG
	@MSG_CONF_NUM_LNG
	@MSG_NW_MMBER
	@MSG_RM_MMBER 
	@MSG_CONF_LVE_LST
	@MSG_LVE_ND_DLT_LST
	@MSG_INVLD_MMBR
	@MSG_INVLD_CMND
	@MSG_HLP_BASIC
	@MSG_HLP_ADV 
	@MSG_SYS_ERR
	@MSG_EXP_WARN1
	@MSG_EXP_WARN2
	@MSG_REFRESH
	@MSG_EXP_RMV
	SYMB_SEND
	SYMB_RMV 
	SYMB_ERR
	SYMB_ID
	SYMB_LANG
	SYMB_RFSH
	@PORTU_NME
	@ENG_NME
	@SPAN_NME
	@POL_NME
	@FRAN_NME
);



#set this value to 1 if you wish for memberships to expire after a set period, 0 if you wish
#memberships to be permanent.
use constant EXPIRING_MEMS => 1;

#This value set up how many days a member can be an inactive before their membership expires.
use constant EXPIRE_PERIOD => 90;

#These two values set up how many days before a member will be notified that their membership
#will expire for the first and second time.
use constant WARN_DAYS_1 => 7;
use constant WARN_DAYS_2 => 3;

#Sets the hour after which expiry check messages will be sent (e.g. 4 = 4am, 13 = 1pm)
use constant EXP_MSG_HOUR =>13;


use constant MYDATABASE => 'xmsg_dev';

use constant TRUE => 1;
use constant FALSE => 0;


use constant {

    MYSQL_DB          => 'dbi:mysql:'.MYDATABASE.';mysql_read_default_file=/etc/mysql/my.cnf',
    MYSQL_USER        => MYUSER,
    MYSQL_PRINT_ERROR => 1,
    MYSQL_RAISE_ERROR => 1,

};

# Now we will define our table
# varible types char integer



use constant SYMB_SEND => '@';
use constant SYMB_RMV => '&';
use constant SYMB_ERR => '£';
use constant SYMB_ID => ': ';
use constant SYMB_LANG => '#';
use constant SYMB_RFSH => '%';




%MYSQL_TABLES = (
    
tblNumbers =>  'create table tblNumbers (
			NumberID integer NOT NULL AUTO_INCREMENT, 
			Telnumber char(20), 
			LastActivity date, 
			LangID integer, 
			Warn tinyint,
			PRIMARY KEY (NumberID)
			) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',
		
tblLists =>  	'create table tblLists (
			ListID integer NOT NULL AUTO_INCREMENT,
			ListName char(20), 
			LangID integer, 
			PRIMARY KEY (ListID)
			)DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',

tblLinkNumLists => 'create table tblLinkNumList (
			NumListID integer NOT NULL AUTO_INCREMENT,
			NumberID integer, 
			ListID integer, 
			PRIMARY KEY (NumListID)
			)DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',

);

my ($m, $l, $n, $p) = ("msg", "lng_name", "lng_id", "main");

use constant DFLT_LANG => 2;

@PORTU_NME = ("português", "portugues");
my $portu_id = 1;

@ENG_NME = ("english");
my $eng_id  = 2;

@SPAN_NME = ("español", "espanol");
my $span_id =  3;

@POL_NME = ("polski");
my $pol_id = 4;

@FRAN_NME = ("français" , "francais");
my $fran_id =  5;

#@ITAL_NME = ("italiano");
#my $ital_id = 6;
 
my $dfl = "português";
my $df_list = "net";
@LANG_ASSGN = (
		{$l => \@PORTU_NME, $n => $portu_id},
		{$l => \@ENG_NME, $n => $eng_id },
		{$l => \@SPAN_NME, $n => $span_id},
		{$l => \@POL_NME, $n => $pol_id},
		{$l => \@FRAN_NME, $n => $fran_id});
	
#@ = <>
#& = //


@MSG_JOIN = ({$m => "You\\'ve joined \\" . SYMB_SEND . "NWRK. To respond to an SMS, begin your SMS" 
		. "with \\" . SYMB_SEND . "NWRK,followed by a space and your message. To leave this network: just" 
		. " text \\" .SYMB_RMV . "NWRK.", 
		$n => $eng_id},

		{$m => "Acabou de aderir à rede \\" . SYMB_SEND . "NWWK. Para responder a um SMS, escreva"
		.  "\\" . SYMB_SEND . "NWRK, seguido de espaço e da sua mensagem. Para deixar a rede escreva" 
		. " apenas \\". SYMB_RMV ."NWWK.",
		$n => $portu_id},

		{$m => "Usted se ha suscrito a \\" . SYMB_SEND . "NWRK. Para responder a un SMS, inicie su"
		.  " SMS digitando \\" . SYMB_SEND . "NWRK, seguido por un espacio y el cuerpo de su mensaje."
		.  " Para salir de esta red simplemente digite \\" . SYMB_RMV . "NWRK.",
		$n => $span_id},

		{$m => "Dołączyłeś do \\" . SYMB_SEND . "NWRK. Aby odpowiedzieć na SMS-a" 
		. " wybierz \\" . SYMB_SEND . "NWRK, spacja a następnie wpisz treść SMS-a."
		. " Aby opuścić tę sieć wyślij SMS-a o treści \\" . SYMB_RMV . "NWRK.",
                 $n => $pol_id},

		{$m => "Tu as joint \\" . SYMB_SEND . "NWRK. Pour répondre au SMS, commence ton SMS" 
		. " avec \\" . SYMB_SEND . "NWRK, suivi d’un espace et de ton message. Pour quitter" 
		. " le réseau: simplement texte \\" . SYMB_RMV . "NWRK.",
		$n => $fran_id}
 
);
                              
@MSG_NW_LST = ({$m => "You\\'ve created a new network, to send an SMS to the network begin your SMS" 
		. " with \\" . SYMB_SEND .  "NWRK, followed by a space and your message. Invite all the people you would"
		. " like to be on this network with you by forwarding these instructions to them\\! Enjoy\\!",
		$n => $eng_id},

		{$m => "Acabou de criar uma nova rede. Para enviar um SMS para"
		. " escreva \\" . SYMB_SEND . "NWRK, seguido de espaço e da sua mensagem. Encaminhe estas instruções"
		. " para todas as pessoas que gostaria que aderissem à rede. Aproveite\\!",
		$n => $portu_id},

		{$m => "Usted ha creado una nueva red. Para enviar un SMS, empiece su SMS" 
		. " con \\". SYMB_SEND ."NWRK seguido por un espacio y el cuerpo de su mensaje. "
		. " Invite todas las personas que usted  quiera incluir en esta red enviando estas "
		. " instrucciones. ¡Disfrute este servicio\\!",
		 $n => $span_id},

		{$m => "Stworzyłeś nową sieć. Aby wysłać SMS-a wpisz \\". SYMB_SEND ."NWRK," 
		. "następnie spację i właściwą treść SMS-a.",
		$n => $pol_id},

		{$m => "Tu as crée un nouveau réseau. Pour envoyer un SMS, commence ton SMS"
		. " par\\". SYMB_SEND ."NWRK, suivi d’un espace et de ton message. Invite toutes tes" 
		. "amies sur ce réseau en leurs envoyant les instructions. Profites-en !",
		$n => $fran_id}
);

@MSG_SET_LNG = ({$m => "You\\'ve not chosen a language, to do so, please text \\" . SYMB_SEND .  
		"NWRK followed by a \\" . SYMB_LANG . " and the name of your language," 
		. " eg. \\" . SYMB_SEND . "NWRK\\" . SYMB_LANG ."$dfl", 
		$n => $eng_id},

		{$m => "Não escolheu um idioma. Para o fazer escreva \\" . SYMB_SEND . "NWRK"
		. " seguido do \\" . SYMB_LANG . "idioma que deseja. Ex: \\" . SYMB_SEND . "NWRK\\" . SYMB_LANG . "$dfl",
		$n => $portu_id},

		{$m => "Usted no ha seleccionado un lenguaje para su red. Para seleccionarlo por favor" 
		. " envíe un mensaje incluyendo \\" . SYMB_SEND . "NWRK seguido por el nombre de el lenguaje"
		. " ue desea utilizar, por ejemplo:\\" . SYMB_SEND . "NWRK\\" . SYMB_LANG . "$dfl",
		$n => $span_id},

		{$m => "Nie wybrałeś języka. Aby to zrobić wyślij SMS z nazwą swojego języka poprzedzoną \\"
		 . SYMB_SEND . "NWRK, np. \\" . SYMB_SEND . "NWRK\\" . SYMB_LANG . "$dfl",
		$n => $pol_id},

		{$m => "Tu n’as pas sélectionné de langue. Pour choisir le langage d’utilisation," 
		. "texte \\" . SYMB_SEND . "NWRK suivi du nom de la langue, par exemple \\" . SYMB_SEND 
		. "NWRK\\" . SYMB_LANG . "$dfl",
		$n => $fran_id}
 		
);                             

@MSG_CONF_LST_LNG = ({$m => "The network\\’s language is now set to LNGGE, to change to another language," 
		. "text \\" . SYMB_SEND . "NWRK followed by the name of your language, eg. \\" . SYMB_SEND .
		"NWRK\\" . SYMB_LANG . "$dfl", 
		$n => $eng_id},

		{$m => "O idioma da rede está agora definido como LNGGE. Para mudar de idioma," 
		. "escreva \\". SYMB_SEND . "NWRK seguido do novo idioma, e envie para. Ex." 
		. "\\" . SYMB_SEND . "NWRK\\" . SYMB_LANG . "$dfl", 
		$n=> $portu_id},

		{$m=> "Usted ha seleccionado como lenguaje de su red LNGGE, para seleccionar otro lenguaje,"
		. " digite \\" . SYMB_SEND . "NWRK seguido por el nombre del lenguaje que desea seleccionar," 
		. " por ejemplo:\\" . SYMB_SEND . "NWRK\\" . SYMB_LANG . "$dfl",
		$n => $span_id},

		{$m => "Język tej sieci jest ustawiony na LNGGE. Aby zmienić język wyślij SMS"
		. " z nazwą wybranego języka poprzedzoną \\" . SYMB_SEND . "NWRK,"
		. " np. \\" . SYMB_SEND . "NWRK\\" . SYMB_LANG . "$dfl",
		$n => $pol_id},

		{$m => "La langue du réseau est réglée sur LNGGE. Pour changer a une autre langue," 
		. " texte \\" . SYMB_SEND . "NWRK suivi du nom de ta langue, par exemple \\" . SYMB_SEND 
		. "NWRK\\" . SYMB_LANG . "$dfl",
		$n => $fran_id}

);

@MSG_CONF_NUM_LNG = ({$m => "Your language is now set to LNGGE, to change to another language," 
		. "text \\". SYMB_LANG . " followed by the name of your language, eg. \\" . SYMB_LANG . "$dfl.",
		 $n => $eng_id},

		{$m => "O seu idioma está agora definido como LNGGE. Para mudar de idioma, escreva"
		. " \\" . SYMB_LANG . "seguido do novo idioma. Ex.\\" . SYMB_LANG ."$dfl.",
		$n=> $portu_id},
	
		#spanish msg missing here


		{$m => "O seu idioma está agora definido como LNGGE. Para mudar de idioma, escreva"
		. " \\" . SYMB_LANG . "seguido do novo idioma. Ex.\\" . SYMB_LANG ."$dfl.",
		$n=> $span_id},#this is portugueue!! We need a spanish version

		{$m => "Twój język to LNGGE. Aby zmienić wybrany jezyk na inny wyśłij SMS-a z nazwą"
		. " języka poprzedzoną kratką, np.\\" . SYMB_LANG ."$dfl.",
   		$n => $pol_id},

		{$m => "Ta langue d’utilisation est réglée sur LNGGE. Pour changer à une autre langue,"
		. " texte  \\". SYMB_LANG . " suivi du nom de ta langue, par exemple \\" . SYMB_LANG . "$dfl.",
		$n => $fran_id}
);


@MSG_NW_MMBER = ({$m => "A new member has joined the \\" . SYMB_SEND . "NWRK network.", 
		$n => $eng_id},

		{$m => "Um novo membro aderiu à rede \\" . SYMB_SEND ."NWRK.",
		$n => $portu_id},

		{$m => "Un Nuevo miembro se ha suscrito a la red \\" . SYMB_SEND ."NWRK.",
		$n => $span_id},
		
		{$m => "Nowy użytkownik dołączył do sieci \\" . SYMB_SEND ."NWRK.",
		$n => $pol_id},
		
		{$m => "Un nouveau membre a joint le \\" . SYMB_SEND ."NWRK réseau",
		$n => $fran_id}

);


@MSG_RM_MMBER = ({$m => "A member has left the \\" . SYMB_SEND . "NWRK network.", 
		$n => $eng_id},


		{$m => "Um membro desistiu da rede \\" . SYMB_SEND . "NWRK.",
		$n => $portu_id},


		{$m => "Un miembro ha salido de la red \\" . SYMB_SEND . "NWRK.",
		$n => $span_id},

		{$m => "Użytkownik opuścił sieć \\" . SYMB_SEND . "NWRK.", 
		$n => $pol_id},
	
		{$m => "Un membre a sorti du réseau \\" .SYMB_SEND . "NWRK.",
		$n => $fran_id}
		);




@MSG_MMBER_LEFT = ({$m => "A member has quit the \\" . SYMB_SEND . "NWRK network.", 
		$n => $eng_id},
	
		{$m => "Um membro saiu da rede \\" . SYMB_SEND . "NWRK.",
		$n => $portu_id},

		{$m => "Un miembro ha abandonado la red \\" . SYMB_SEND . "NWRK.",
		$n => $span_id},
		
		{$m => "Użytkownik wylogował się z sieci \\" . SYMB_SEND . "NWRK.",
		$n => $pol_id},

		{$m => "Un membre a quitté le réseau \\"  . SYMB_SEND . "NWRK.",
		$n => $fran_id}

		);

@MSG_MMBER_EXP = ({$m => "A member of the \\" . SYMB_SEND . "NWRK network's membership has expired.", 
		$n => $eng_id},
	
		{$m => "Um membro da rede \\" . SYMB_SEND . "NWRK expirou.",
		$n => $portu_id},

		{$m => "La membresía de un miembro de la red \\" . SYMB_SEND . "NWRK ha vencido.",
		$n => $span_id},
		
		{$m => "Członkostwo użytkownika sieci \\" . SYMB_SEND . "NWRK wygasło.",
		$n => $pol_id},

		{$m => "L'adhésion d'un membre au red \\" . SYMB_SEND . "NWRK a expirée.",
		$n => $fran_id}

		);


@MSG_CONF_LVE_LST = ({$m => "You\\'ve left the \\" . SYMB_SEND . "NWRK network. To join another network," 
		. " begin your SMS with an \\" . SYMB_SEND . " followed by "
		. " the name of the network you wish to text e.g. \\" . SYMB_SEND . $df_list, 
		$n => $eng_id},

		{$m => "Acabou de deixar a rede \\" . SYMB_SEND . "NWRK. Para aderir a outra rede,"
		. " começando com \\" . SYMB_SEND . ", seguido do nome"
		. " da rede para onde deseja escrever. Ex. \\" . SYMB_SEND . $df_list,
		$n => $portu_id},

		{$m => "Usted se ha salido de la \\" . SYMB_SEND . "NWRK. Para suscribirse a otra red," 
		. " incluyendo en el inicio el símbolo \\" . SYMB_SEND . " seguido"
		. " por el nombre de la red a la que desea suscribirse. Por ejemplo: \\" . SYMB_SEND . $df_list,
		$n => $span_id},

		{$m => "Opuściłeś sieć \\" . SYMB_SEND . "NWRK. Aby dołączyć do innej sieci" 
		. " w reści wpisujc nazwę sieci, do której chciałbyś dołączyć poprzedzoną" 
		. " znakiem małpa, np. \\" . SYMB_SEND . $df_list,
		$n => $pol_id},
		#check pol spelling wpisujc
		{$m => "Tu as quitte le réseau \\" . SYMB_SEND . "NWRK. Pour joindre un autre réseau, "
		. " en commençant ton SMS avec \\" . SYMB_SEND . "suivi du nom du réseau"
		. " que tu veux texter, par exemple \\" . SYMB_SEND . $df_list,
		$n => $fran_id}
);


@MSG_LVE_ND_DLT_LST = ({$m => "You\\'ve now been removed from \\" . SYMB_SEND . "NWRK and it has been" 
		. " deleted because you were the last member. To join another network,"
		. " begin your SMS with an \\" . SYMB_SEND . "followed by the name of the network" 
 		. " you wish to text e.g. \\" . SYMB_SEND . $df_list, 
		$n => $eng_id},

		{$m => "Foi removido da rede\\" . SYMB_SEND . "NWRK. Esta rede foi agora apagada por ser" 
		.  " o último membro. Para aderir a outra rede, comece sempre"
		.  " os seus SMS com \\" . SYMB_SEND . "seguido do nome da rede para onde deseja escrever."
		.  " Ex.\\" . SYMB_SEND . $df_list,
		$n => $portu_id},

		{$m => "Usted ha sido eliminado de \\" . SYMB_SEND . "NWRK. Esto ha sucedido debido a que"
		.  " usted era el ultimo miembro. Para Suscribirse a otra red," 
		. " inicie siempre sus SMS con el símbolo \\" . SYMB_SEND . "seguido por el nombre de la red en"
		. " la cual usted desea enviar un mensaje. Por ejemplo:\\" . SYMB_SEND ." $df_list",
		$n => $span_id},

		{$m => "Zostałeś usunięty z sieci \\" . SYMB_SEND . "NWRK, która różnież została usunięta,"
		. " ponieważ byłeś jej ostatnim członkiem. Aby dołączyć do innej sieci, "
		. " w treści zawsze poprzedzaj nazwę sieci, do której chciałbyś dołączyć znakiem małpa,"
		. " np. \\" . SYMB_SEND . "$df_list.",
		$n => $pol_id},

		{$m => "Tu viens d’être retiré du réseau \\" . SYMB_SEND . "NWRK parce que tu étais le dernier"
		. " membre. Pour joindre un autre réseau, commence toujours ton SMS"
		. " par \\" . SYMB_SEND . "suivi du nom du réseau auquel tu veux texter, par"
		. " exemple \\" . SYMB_SEND . "$df_list.",
		$n => $fran_id}

);
		
@MSG_INVLD_MMBR = ({$m => "You\\'re not a member of the \\" . SYMB_SEND . "NWRK, to join this network"
		. " begin your SMS with an \\" . SYMB_SEND
		 . " followed by the name of the network you wish to text e.g. \\" . SYMB_SEND . "NWRK",
		$n => $eng_id},
		
		{$m => "Não é um membro da rede \\" . SYMB_SEND . "NWRK. Para aderir a esta rede" 
		. " comece sempre os seus SMS com \\" . SYMB_SEND . " seguido do" 
		. " nome da rede para onde deseja escrever. Ex.\\" . SYMB_SEND . "NWRK",
		 $n => $portu_id},

		{$m => "Usted no es un miembro de \\" . SYMB_SEND . "NWRK, para suscribirse a esta red" 
		. " inicie siempre sus SMS con el símbolo \\" . SYMB_SEND . "seguido" 
		. " por el nombre de la red en la cual usted desea enviar mensajes." 
		. " Por ejemplo:\\". SYMB_SEND . "NWRK",
		$n => $span_id},

		{$m => "Nie jesteś członkiem sieci \\" . SYMB_SEND . "NWRK. Aby dołączyć do tej sieci"
		. " w treści zawsze poprzedzaj nazwę sieci, do której"
		. " chciałbyś dołączyć znakiem małpa, np. \\". SYMB_SEND . "NWRK",
	        $n => $pol_id},

		{$m => "Tu n’es pas un membre du réseau  \\" . SYMB_SEND . "NWRK. Pour joindre ce réseau,"
		. " commence toujours ton SMS par \\" . SYMB_SEND . " suivi du" 
		. " nom du réseau auquel tu veux texter, par exemple  \\". SYMB_SEND . "NWRK.",
		$n => $fran_id}
			
);

@MSG_INVLD_CMND = ({$m => "I think you made a mistake. To join a network," 
 		. " begin your SMS with an \\" . SYMB_SEND . "followed by the name of the network"
		. " you wish to text e.g. \\" . SYMB_SEND ."DFLT. For further help text \\!HELP-BASIC" 
		. " or \\!HELP-ADVANCED", 
		$n => $eng_id},
                
		{$m => "Cometeu um erro. Para aderir a uma rede ou escrever uma mensagem," 
		. " começando o seu SMS com \\" . SYMB_SEND . ", seguido pelo nome"
		. " da rede para onde deseja escrever and da sua mensagem. Ex.\\" . SYMB_SEND . "DFLT" 
		. " aderir. Para mais informações escreve \\!HELP-BASIC ou \\!HELP-ADVANCED",
		$n => $portu_id}, 

		{$m => "Yo creo que ha cometido un error. Para suscribirse a una red o enviar un mensaje,"
		. "  iniciando su SMS con el símbolo \\" . SYMB_SEND . "seguido por el"
		. "  nombre de la red en la cual usted desea enviar mensajes y a continuación el cuerpo de su" 
		. "  mensaje. Por ejemplo:\\" . SYMB_SEND ."DFLT. Si necesita más ayuda digite" 
		. " \\!HELP-BASIC o \\!HELP-ADVANCED",
		$n => $span_id},
		
		{$m => "Myślę, zrobiłeś/łaś pomyłkę. Aby dołączyć do sieci lub wysłać wiadomość," 
		. " wpisując „małpa”, a następnie nazwę sieci, do której chciałbyś napisać"
		. " oraz swoją wiadomość, np. \\" . SYMB_SEND ."DFLT dołącz. Aby uzyskać dalsze informacje wyślij"
		. " SMS o treści: !HELP-BASIC lub !HELP-ADVANCED.",
		$n => $pol_id},

		{$m => "Je crois que tu as fait une erreur. Pour joindre un réseau ou lui envoyé un message,"
		. " en commençant ton SMS par \\" . SYMB_SEND ." suivi du nom du réseau"
		. " auquel du veux texter, puis ton message, par exemple \\" . SYMB_SEND ."DFLT joindre.  Pour"
		. " plus d’aide, texte !AIDE-BASIC ou !AIDE-SUP",
		$n => $fran_id}
 );


@MSG_HLP_BASIC = ({$m => "To join a network, text \\" . SYMB_SEND . "followed by the name of the network,"
		. " then a space and ‘join’. e.g. \\" . SYMB_SEND . "DFLT.  To send a network a" 
		. " message once you are a member, do the same, but instead of ‘join’ write your message."  
		. " To leave a network, text  \\" . SYMB_RMV . "followed by the network’s name" 
		. " e.g. \\". SYMB_RMV . $df_list,
		$n => $eng_id},

		{$m => "Para aderir a uma rede, escreva \\" . SYMB_SEND . "seguido do nome da rede," 
		. " de espaço, e da palavra ‘aderir’. Ex. \\" . SYMB_SEND . "DFLT aderir. Uma vez membro," 
		. " para enviar uma mensagem à rede faça o mesmo mas escreva a sua mensagem em vez da"
		. " palavra ‘aderir’. Para deixar uma rede, escreva \\" . SYMB_RMV . "seguido do  nome da" 
		. " rede. Ex.\\" . SYMB_RMV . $df_list,
		 $n => $portu_id}, 

		{$m => "Para unirse a una red, digite \\" . SYMB_SEND . "seguido por el nombre de la red,"
		. " despees un espacio y la palabra ‘Join”. Ejemplo:\\" . SYMB_SEND . "DFLT join.  Si desea"
		. " enviar mensajes una vez se ha vuelto miembro de una red, repita las instrucciones anteriores,"
		. " reemplazando la palabra “join” por el cuerpo de su mensaje. Para salir de una red, envíe"
		. " un mensaje con el símbolo & seguido por el nombre de la red de la cual desea darse de alta." 
		. " Por ejemplo:\\" . SYMB_RMV . $df_list,
		$n => $span_id},

		{$m => "Aby dołączyć do sieci, wpisz w treści wiadomości “małpa”, następnie nazwę sieci, spację" 
		. "oraz słowo „join”, np. \\" . SYMB_SEND . "DFLT join. Aby wysłać SMS-a do sieci, będąc jej"
		. " członkiem, zrób to samo, tylko zamiast słowa „join” wpisz swoją wiadomość. Aby opuścić sieć"
		. " wyślij SMS z nazwą sieci poprzedzoną \\" . SYMB_RMV . "np. \\" . SYMB_RMV . "$df_list.",
		$n => $pol_id},

		{$m => "Pour joindre un réseau, texte  \\" . SYMB_SEND . "suivi du nom du réseau, puis un espace" 
		. " et ‘joindre’. Par exemple,  \\" . SYMB_SEND . "DFLT joindre. Pour envoyer un message a un réseau"
		. " une fois que tu es un membre, fais la même chose, mais écris ton message a la place de ‘joindre’."
		. " Pour quitter un réseau, texte & suivi du nom du réseau, par exemple  \\" . SYMB_RMV . "$df_list.", 
		$n => $fran_id}
);
  
@MSG_HLP_ADV = ({$m => "To change a network’s language, send an SMS with an \\" . SYMB_SEND . "and the" 
		. "networks name followed by the native name of the language you wish to use e.g."
		. "\\" . SYMB_SEND . "DFLT \\" . SYMB_LANG . "$dfl. To change your own default language,"
		. " text \\" . SYMB_LANG . "followed by the language name e.g. \\" . SYMB_LANG . "$dfl",
		$n => $eng_id},
 
		{$m => "Para mudar o idioma da rede, envie um SMS com \\" . SYMB_SEND . " seguido pelo" 
		. " nome da rede e do idioma que deseja utilizar. Ex. \\" . SYMB_SEND . "DFLT" 
		. "\\" . SYMB_LANG . "$dfl. Para mudar o seu idioma padrão, text \\" . SYMB_LANG . "seguido" 
		. " do nome do idioma. Ex.\\" . SYMB_LANG . "$dfl",
		 $n => $portu_id}, 

		{$m => "Para cambiar el lenguaje de una red, envíe un SMS iniciando con el símbolo \\"
		. SYMB_SEND . " seguido por el nombre de la red y el lenguaje ue usted desea utilizar." 
		. " Por ejemplo:\\" . SYMB_SEND . "DFLT \\" . SYMB_LANG ."$dfl. Para cambiar el lenguaje" 
		. " de su interfaz, envíe un mensaje iniciando con el símbolo \\" . SYMB_LANG . "seguido" 
		. " por el language ue desea utilizar. Ejemplo:\\" . SYMB_LANG . "$dfl",
		 $n => $span_id},

		{$m => "Aby zmienić język sieci, wyślij SMS o treści: małpa, nazwa sieci oraz nazwa języka,"
		. " którego chciałbyś używać, np. \\" . SYMB_SEND . "DFLT \\" . SYMB_LANG ."$dfl."
		. " Aby zmienić domyślne ustawienia języka wyślij SMS z nazwą języka poprzedzoną kratką,"
		. " np. \\" . SYMB_LANG . "$dfl",
		$n => $pol_id},

		{$m => "Pour changer la langue d’utilisation d’un réseau, envoie un SMS avec \\" . SYMB_SEND . "et"
		. " le nom du réseau suivi de \\" . SYMB_LANG ." et du nom de la langue que tu veux utiliser. Par" 
		. "exemple, \\" . SYMB_SEND . "DFLT \\" . SYMB_LANG ."$dfl. Pour changer ta propre langue d’utilisation,"
		. " texte \\" . SYMB_LANG ." suivi du nom de la langue, par exemple \\" . SYMB_LANG ."$dfl",
		$n => $fran_id}
		);

@MSG_SYS_ERR=( {$m => "The system ran into a problem with your last message.  Please try again later", 
		$n => $eng_id},	
	
		{$m => "O sistema detectou um problema com a sua última mensagem. Por favor tente" 
			."  novamente mais tarde.",
		 $n => $portu_id},

		{$m => "El sistema encontró un problema con el ultimo mensaje. "
		. "Intenta otra vez mas tarde, por favor",
		$n => $span_id},

		{$m => "Problem z dostarczeniem Twojej ostatniej wiadomości. Prosimy spróbować później.",
		$n => $pol_id},

		{$m => "Le système a recentré un problème avec votre denier message. " 
		. "Réessayez plus tard, s'il vous plaît.",
		$n => $fran_id}

		);


@MSG_REFRESH=( {$m => "Your memberships have been renewed. Thanks!", $n => $eng_id},

		{$m => "A sua assinatura foi renovada. Obrigado!", $n => $portu_id},

		{$m => "Su membresía ha sido renovado. Gracias!", $n => $span_id},

		{$m => "Twoje członkostwo zostało odnowione. Dzięki!", $n => $pol_id},

		{$m => "Votre adhésion a été renouvelée. Merci!", $n => $fran_id}

		);


@MSG_EXP_WARN1=( {$m => "Your membership of the SMS network is about to expire. " 
		. "Please reply, starting your message with the symbol \\" . SYMB_RFSH . " within " 
		. WARN_DAYS_1 . " days if you wish to stay on the network.  Your "
		. "membership is renewed every time you send"
		. " a message on the network.", $n => $eng_id},

		{$m => "A sua assinatura da rede SMS está prestes a expirar. " 
		. "Se desejar manter-se na rede, por favor responda a esta mensagem dentro de "
		 .  WARN_DAYS_1 . " dias, começando a sua mensagem com o símbolo \\" . SYMB_RFSH . 
		" A sua assinatura é renovada sempre que envia uma mensagem dentro da rede.",
		 $n => $portu_id},

		{$m => "Su membresía de la red SMS está acabandose. "
		. "Si usted quiere quedarse en la red, responde por favor, empezando el mensaje "
		. "con \\" . SYMB_RFSH . " antes de " . WARN_DAYS_1 . " días. Su membresía sera "
		. "renovado cada vez que manda un mensaje a la red.",
		$n => $span_id},
		
		{$m => "Twoje członkostwo w sieci SMS niebawem wygaśnie. "
		. "Jeśli zamierzasz pozostać w sieci, odpowiedz na tę wiadomość rozpoczynając "
		. "swoją odpowiedź od symbolu \\" . SYMB_RFSH . " w ciągu kolejnych " . WARN_DAYS_1 
		. " dni. Twoje członkostwo jest wznawiane za kaźdym razem gdy wysyłasz wiadomość "
		. "do sieci.",
		$n => $pol_id},

		{$m => "Votre adhésion au réseau SMS est sur le point d'expirer. "
		. "Si vous voudriez rester au réseau, répondriez-vous bien en commençant "
		. "le message avec le symbole \\" . SYMB_RFSH . " avant " . WARN_DAYS_1
		. " jours. Votre adhésion sera renouvelée chaque fois que vous envoyez "
		. "un message au réseau.",
		$n => $fran_id}

		);


@MSG_EXP_WARN2=( {$m => "Your membership of the SMS network is about to expire. " 
		      . "Please reply to this message with \\" . SYMB_RFSH . " within " 
			. WARN_DAYS_2 . " days if you wish to stay" 
		      . " on the network.", $n => $eng_id},

		{$m => "A sua assinatura da rede SMS está prestes a expirar. " 
			. "Se desejar manter-se na rede, por favor responda a esta mensagem dentro de "
			 .  WARN_DAYS_2 . " dias, começando a sua mensagem com o símbolo \\" . SYMB_RFSH,
		 $n => $portu_id},
		
		{$m => "Su membresía de la red SMS esta acabandose. Si usted quiere quedar "
		. "en la red, responde por favor, empezando el mensaje con \\" . SYMB_RFSH,
		$n => $span_id}.

		{$m => "Twoje członkostwo w sieci SMS niebawem wygaśnie. "
		. "Jeśli zamierzasz pozostać w sieci, odpowiedz na tę wiadomość rozpoczynając "
		. "swoją odpowiedź od symbolu \\" . SYMB_RFSH,
		$n => $pol_id},

		{$m => "Votre adhésion au réseau SMS est sur le point d'expirer. "
		. "Si vous voudriez rester au réseau, répondriez-vous bien en commençant "
		. "le message avec le symbole \\" . SYMB_RFSH,
		$n => $fran_id}
	
		);

@MSG_EXP_RMV=( {$m => "You membership of the SMS network has expired. "
		 	. "You can rejoin at any time by texting \\" . SYMB_SEND . "followed by the name of the network,"
                 	. " then a space and \\‘join\\’. e.g. \\" . SYMB_SEND . "DFLT.", 
		$n => $eng_id},

		{$m => "A sua assinatura da rede SMS expirou. Pode voltar aderir à rede a qualquer momento escrevendo \\"
		 	 . SYMB_SEND . "seguido do nome da rede Ex. \\" . SYMB_SEND . "DFLT.", 
		$n => $portu_id},

		{$m => "Su membresía de la red SMS ha sido acabado. Usted puede volver en cualquier "
		. "momento escribiendo \\" . SYMB_SEND . " seguido por el nombre de la red e.g. \\"
		. SYMB_SEND . "DFLT",
		$n => $span_id},
	
		{$m => "Twoje członkostwo w sieci SMS wygasło. Możesz wrócić w każdej chwili wysyłając "
		. "tekst o treści: \\" . SYMB_SEND . " imię sieci przerwa ‘dołącz', np.: \\" . SYMB_SEND . "DFLT dołącz",
		$n => $pol_id},
			
		{$m => "Votre adhésion au réseau SMS a expirée. Vous pouvez rejoindrez à tout "
		. "moment par envoyer \\" . SYMB_SEND . " suivant par le nombre du réseau e.g. \\"
		. SYMB_SEND . "DFLT",
		$n => $fran_id}

		);

