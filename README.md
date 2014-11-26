MarkLogic Geonames
==========
The MarkLogic geonames project is a simple location extractor and enrichment service that uses MarkLogic and the [geonames](www.geonames.org) gazetteer.  

### Prerequisites
--------
1. [MarkLogic](http://developer.marklogic.com/products)
2. [JDK 1.7](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html) 
3. [Gradle 2.0](http://www.gradle.org/downloads)

### Instructions
1. gradle mlDeploy
2. gradle -Pgeonames=true ingestGeonamesLookups
3. gradle -Pgeonames=true -Pcountry=<ISO 2 character code> ingestGeonames

### API
* Geonames API - http://<HOST>:8010/v1/resources/api
* geo-enrich - http://<host>:8010/v1/resources/geo-enrich
  * http://<host>:8010/v1/resources/geo-enrich?rs:text=I%20live%20in%20Paris%20and%20Normandy&rs:country-code=FR

### User Interface
To run the front-end, install nodejs and npm then run the following:

- npm install –g bower
- npm install –g gulp

Then change to the <project_dir>/node directory and execute the following:

- gulp 
- gulp server

FYI - “gulp” and “gulp server” do not exit, so I execute “gulp &” wait a few seconds for it to stop outputting text, then I hit <enter> to get a prompt again and type “gulp server"

* Troubleshooting
 * After running "gulp", if you get errors then try the following commands
 * sudo rm -rf ~/.npm
 * sudo npm install -g npm@1.4.14
