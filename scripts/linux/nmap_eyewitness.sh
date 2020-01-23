#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
white='\033[1;37m'
blue='\033[0;34m'
yellow='\033[1;33m'


printf "\033c"
echo -e ${blue}
cat << "EOF"

   __   __    __  __  _____
  |  \ |  \  /  |/  \|  __ \
  |   \|   \/   / /\ |  ___/
  | |\   |\  /|   ___  |
  |_| \__| \/ |__/   | |
                     |.|
                  ..,,;;;;;;,,,,
       .,;'';;,..,;;;,,,,,.''';;,..
    ,,''                    '';;;;,;''
   ;'    ,;@@;'  ,@@;, @@, ';;;@@;,;';.
  ''  ,;@@@@@'  ;@@@@; ''    ;;@@@@@;;;;
     ;;@@@@@;    '''     .,,;;;@@@@@@@;;;
    ;;@@@@@@;           , ';;;@@@@@@@@;;;.
     '';@@@@@,.  ,   .   ',;;;@@@@@@;;;;;;
        .   '';;;;;;;;;,;;;;@@@@@;;' ,__;___   _ ___________  _____  _
          ''..,,     '''' '; ; | |_|_   _   \ | | ____/  ___|/  ___|| |
               ''''''::'''| |  | | | | | |   \| |  __|\___  \\___  \| |
                          | |/\| | | | | | |\   | |___ __/  /___/  /| |____
                          |__/\__|_| |_| |_| \________/____//_____/ |______|


EOF

#####################################################################################################
#                                     Question 1 What are we scanning                               #
#####################################################################################################

echo -e ${green} "[+]" ${white} "What is the Hostname, IP, IP-Range or IP/Subnet, please?"
  read answer1

#####################################################################################################
#                                     Create folder on Desktop for scans                            #
#####################################################################################################

date=$(date +%F_%T)
cd /root/Desktop/
mkdir $date
cd $date
mkdir nmap
cd nmap

#####################################################################################################
#                                     Initial ping scan                                             #
#####################################################################################################


echo -e ${green} "[+]" ${white} "Do you want to do an initial ping scan to see what hosts are up? [Y/N]"
read answer5

if [[ $answer5 =~ ^(yes|Yes|y|Y) ]]
  then
    echo -e ${green} "[+]" ${white} "Checking now, please wait."
    nmap -T4 -sP -PS -n $answer1 -oG - | grep -E '(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])' |cut -d' ' -f2 | awk 'NR != 1' > live-hosts.txt
    cat live-hosts.txt
    echo -e ${green} "[+]" ${white} "Would you like to continue with only 'LIVE' hosts or treat 'ALL' hosts as up? [L/A]>"
    read answer6
if [[ $answer6 =~ ^(live|l|Live|L|y|Y|yes|Yes) ]]
      then
        echo -e ${green} "[+]" ${white} "Live it is then."
	file=-iL
      else
        echo -e ${green} "[+]" ${white} "Everyones a target hey."
    fi
fi

#####################################################################################################
#                                     Question 2 Number of Ports                                    #
#####################################################################################################

echo -e ${green} "[+]" ${white} "How many top ports would you like to scan 1-65535? More will take longer."
  read answer2
    tcp=--top-ports

#####################################################################################################
#                                     Question 3 Include UDP                                        #
#####################################################################################################
echo -e ${green} "[+]" ${white} "Would you like to include UDP? [Y/N]"
  read answer3

if [[ $answer3 =~ ^(yes|Yes|y|Y) ]]
  then
    echo -e ${green} "[+]" ${white} "OK UDP included."
    udp=-sU
  else
    echo -e ${green} "[+]" ${white} "UDP is out!"
fi


#####################################################################################################
#                                     Question 4 Include version detection                          #
#####################################################################################################

echo -e ${green} "[+]" ${white} "Do you want to include service version detection? This will take much longer! [Y/N]"
  read answer4

if [[ $answer4 =~ ^(yes|Yes|y|Y) ]]
  then 
    echo -e ${green} "[+]" ${white} "OK, you asked for it! Might want to get a cup of tea."
    ver_detect=-sV
  else
    echo -e ${green} "[+]" ${white} "Sit back and relax!"
fi


#####################################################################################################
#                                       Question 5 Include SSL scan                                 #
#####################################################################################################

echo -e ${green} "[+]" ${white} "Do you want to run ssl tests as well? [Y/N]"
  read answer7
if [[ $answer7 =~ ^(yes|Yes|y|Y) ]]
  then 
    echo -e ${green} "[+]" ${white} "OK, lets start, firefox will open with the results when finished."
  else
    echo -e ${green} "[+]" ${white} "No worries, lets begin, firefox will open with the results when finished."
fi


#####################################################################################################
#                                     Run nmap scan                                                 #
#####################################################################################################


if [[ $answer6 =~ ^(live|l|Live|L|y|Y|yes|Yes) ]]
  then
    nmap -T4 -sS $udp $tcp $answer2 $udp_ports $ver_detect $file ./live-hosts.txt --open --reason -oA $date --webxml > /dev/null
  else
    nmap -T4 -sS $udp $tcp $answer2 $udp_ports $ver_detect $answer1 --open --reason -oA $date --webxml > /dev/null
fi

  xsltproc -o $date.html /opt/intelligence-gathering/nmap-bootstrap-xsl/nmap-bootstrap.xsl $date.xml

  firefox $date.html&

#####################################################################################################
#                                     Run eyewitness and open in firefox                            #
#####################################################################################################

/opt/intelligence-gathering/eyewitness/EyeWitness.py -x /root/Desktop/$date/nmap/$date.xml --timeout 90 --threads 10 --no-prompt --web --max-retries 1 -d /root/Desktop/$date/eyewitness > /dev/null

cd ../eyewitness/
firefox report.html& 

#####################################################################################################
#                                     Run additional nmap ssl scan (Optional)                       #
#####################################################################################################

if [[ $answer7 =~ ^(yes|Yes|y|Y) ]]
  then
    cd ../nmap/
    grep -P "open/tcp//https" $date.gnmap | awk '{print $2}' > 443-hosts.txt
    nmap -p443 --script=ssl-enum-ciphers -iL ./443-hosts.txt -oA $date-ssl --webxml > /dev/null

    xsltproc -o $date-ssl.html /opt/intelligence-gathering/nmap-bootstrap-xsl/nmap-bootstrap.xsl $date-ssl.xml

    firefox $date-ssl.html&
  else
    echo -e ${green} "[+]" ${white} "All done"
fi
