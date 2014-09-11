MarkLogic Geonames
==========
The MarkLogic geonames project is a simple location extractor and enrichment service that uses MarkLogic and the [geonames](www.geonames.org) gazetteer.  

### Prerequisites
--------
1. [MarkLogic](http://developer.marklogic.com/products)
2. [JDK 1.7](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html) 
3. [Gradle 2.0](http://www.gradle.org/downloads)
4. [MarkLogic Content Pump](http://developer.marklogic.com/products)
5. ml-java project (the dependency is indicated in build.gradle)
6. Linux (tested with CentOS 6)

### Instructions
1. ./geonames/gradle mlInstallApp
2. ./geonames/gradle mlConfigureApp
3. Remove any CPF domains from the geonames-content database

### Downloading Geonames

The geonames data is downloaded into a directory called data/.  The geonames metadata needs to be downloaded and loaded first before downloading any of the country data.  There is a script called headers.sh that is used to put the the tab delimited header on the country files that are downloaded.  

<i>./load-geonames-meta.sh</i>
 * This will download and load all the geonames metadata into MarkLogic: countryCodes, admin codes, feature codes

<i>./download-geonames.sh [2 character ISO Country Code | all]</i>

> ./download-geonames.sh SC  
 * Downloads the geonames for Seychelles (a small data set)

> ./download-geonames.sh FR
 * Downloads and Loads the geonames for France

> ./download-geonames.sh all
 * Downloads every country

### Loading Geonames into MarkLogic

<i>./load-geonames.sh [2 character ISO Country Code | all]</i>

> ./load-geonames.sh SC 
 * Loads the Seychellles geonames dataset into MarkLogic via mlcp

> ./load-geonames.sh all
 * Loads all countries into MarkLogic

### API
* Geonames API - http://<HOST>:8010/v1/resources/api
* geo-enrich - http://<host>:8010/v1/resources/geo-enrich
  * http://<host>:8010/v1/resources/geo-enrich?rs:text=I%20live%20in%20Paris%20and%20Normandy&rs:country-code=FR

### User Interface
To run the front-end, install nodejs and npm then run the following:

npm install –g bower
npm install –g gulp

Then change to the <project_dir>/node directory and execute the following:

gulp 
gulp server

FYI - “gulp” and “gulp server” do not exit, so I execute “gulp &” wait a few seconds for it to stop outputting text, then I hit <enter> to get a prompt again and type “gulp server"

* Troubleshooting
 * After running "gulp", if you get errors then try the following commands
 * sudo rm -rf ~/.npm
 * sudo npm install -g npm@1.4.14
