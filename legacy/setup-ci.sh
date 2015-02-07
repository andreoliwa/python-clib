#!/bin/bash

# http://erichogue.ca/2011/05/php/continuous-integration-in-php/
sudo apt-get install php5-curl php-pear php5-dev jenkins postfix
sudo pear upgrade PEAR

sudo pear channel-discover pear.phpunit.de
sudo pear channel-discover components.ez.no
sudo pear channel-discover pear.symfony-project.com
sudo pear channel-discover pear.pdepend.org
sudo pear channel-discover pear.phpmd.org

sudo pear install phpunit/PHPUnit
sudo pear install pdepend/PHP_Depend-beta
sudo pear install --alldeps phpmd/PHP_PMD
sudo pear install phpunit/phpcpd
sudo pear install phpunit/phpdcd-beta

# http://jenkins-php.org/
sudo pear config-set auto_discover 1
sudo pear install pear.phpqatools.org/phpqatools pear.netpirates.net/phpDox
cd $G_DOWNLOAD_DIR
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
# @todo atualizar o jenkins.war antes disso
java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin checkstyle cloverphp dry htmlpublisher jdepend plot pmd violations xunit
java -jar jenkins-cli.jar -s http://localhost:8080 safe-restart
