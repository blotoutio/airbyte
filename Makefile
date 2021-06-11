build:
	sudo apt-get -y update
	sudo apt -y install openjdk-14-jdk
	sudo apt-get -y install jq
	sudo apt-get -y install cmake
	sudo apt-get -y install unzip
	sudo apt-get -y install wget
	sudo apt-get -y install python3-pip
	sudo apt-get -y install curl
	sudo curl -ssL https://get.docker.com | bash
	sudo curl -L https://github.com/docker/compose/releases/download/1.29.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	sudo curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
	sudo apt -y install nodejs
	export TZ=UTC
	sudo wget https://services.gradle.org/distributions/gradle-6.7.1-bin.zip -P /tmp
	unzip -d /opt/gradle /tmp/gradle-*.zip
	export GRADLE_HOME=/opt/gradle/gradle-6.7.1
	export PATH=${GRADLE_HOME}/bin:${PATH}
	export JAVA_HOME=/usr/lib/jvm/java-14-openjdk-amd64
	export PATH=$JAVA_HOME/bin:$PATH
	CORE_ONLY=1 ./gradlew build
	docker tag airbyte/webapp:dev blotout/airbyte-webapp:${image_tag}
	docker tag airbyte/server:dev blotout/airbyte-server:${image_tag}
	docker tag airbyte/db:dev blotout/airbyte-db:${image_tag}
	docker push blotout/airbyte-webapp:${image_tag}
	docker push blotout/airbyte-server:${image_tag}
	docker push blotout/airbyte-db:${image_tag}
