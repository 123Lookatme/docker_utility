# Docker utility:
Download automake file: [Newenv](https://github.com/123Lookatme/docker_utility/raw/master/newenv.sh) file
```bash
cd /path_to_file_location  
./newenv.sh
```
 **MAKE SURE USER HAVE PERMISSIONS TO INSTALL WHEN RUNNING AUTOMAKE SCRIPT** 
 
After execute :  
 -[Docker](https://www.docker.com/h) will be installed  
 -[Dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) will be installed  

 After execute complete you will be able using commands: 
 ```bash 
 newenv add [INSTANCE] [OPTIONS] [ARGS]
 newenv conf [value]
 newenv --help
 ```
 >**Note:** Every step supports -h or --help  
 
 ___
## `newenv add:`
```bash
[INSTANCE] - specifies image name you want to install
```
When you running first time and not have builded instances yet - The first place where Dockerfile expected is library.  
Default Dockerfile's library will be instaled to */var/lib/newenv/lib/[instance]*  
Second place to check is `$HOME` dirrectory( */[instance]/Dockerfile*), if your own library not included.  
Otherwise `$HOME` dirrectory will be ignored and first place to search will be your own library while default library will be second one
> **Note:** To see how include your own library check `newenv conf` block below 

```code
[OPTIONS] - specifies additional options:
```
* **-a** - making container starting with system startup. More info check [here](https://docs.docker.com/engine/reference/run/#/restart-policies---restart)  
* **-c=value** -  replacing default container entrypoint ( -c=/bin/bash ).For more information check 'docker run --help' where [COMMAND] equal -c.
* **-i** - Ignore local Dockerfiles.  
With this option Dockerfile will be searched from [Dockerhub](https://hub.docker.com/) repository.  
**Note:** If image allready exists - local image will be used
* **-h=value** - adding container alias to host file. Where [value] = alias.  
For example: -h=lan.test.com. New container will be accessed from host by this alias.  
* **-m=value** - Path where mounted folders apperars(Default: dirrectory from you running).  
By default: after container will be builded - you will see `/newenv` dirrectory with mounted folders inisde.Parent dirrectory for `/newenv`  will be dirrectory from which you execute command.  
```
For example: If you run `newenv add mysql` command from `/myproject` - you will see dirrectories:
/myproject/newenv/mysql/  
                       config/  
                       log/
                       data/
                       
```
> **Note:** Also container name will be `myproject_mysql` and network name: `myproject`  
  

* **-g=value** - Overriding container's group name && network name

```bash
[ARGS] - Additional docker commands
```
You can run container with additional options provided by docker run [OPTIONS]
For example -p 8080:80. For more information see 'docker run --help'
___
## `newenv conf:`
* **-i** - check included liubrary path
* **-i=full_path** - spesifies your own library with Dockerfile's
 
 
