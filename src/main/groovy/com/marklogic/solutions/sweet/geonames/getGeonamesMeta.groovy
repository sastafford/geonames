import groovyx.net.http.HTTPBuilder
import static groovyx.net.http.Method.GET
import static groovyx.net.http.ContentType.ANY

new File("src/main/resources").mkdir()
def geonames_dir = new File("src/main/resources/geonames")
if ( geonames_dir.exists() ) {
	geonames_dir.deleteDir()
}
geonames_dir.mkdir()

//admin1Codes
def admin1CodeFile = new FileWriter("src/main/resources/geonames/admin1CodesASCII.txt")
admin1CodeFile << "admin1_code\tname\tasciiname\tgeonamesid\n"	

def http = new HTTPBuilder('http://download.geonames.org/export/dump/admin1CodesASCII.txt')
http.request( GET, ANY ) { req ->

  // executed for all successful responses:
  response.success = { resp, reader ->
	  reader.each {
		  admin1CodeFile << it + '\n'
	  }
  }
	
  // executed only if the response status code is 401:
  response.'404' = { resp ->
	  println 'not found!'
  }
}

//admin2Codes
def admin2CodeFile = new FileWriter("src/main/resources/geonames/admin2Codes.txt")
admin2CodeFile << "admin2-code\tname\tasciiname\tgeonamesid\n"

http = new HTTPBuilder('http://download.geonames.org/export/dump/admin2Codes.txt')
http.request( GET, ANY ) { req ->

  // executed for all successful responses:
  response.success = { resp, reader ->
	  reader.each {
		  admin2CodeFile << it + '\n'
	  }
  }
	
  // executed only if the response status code is 401:
  response.'404' = { resp ->
	  println 'not found!'
  }
}

//featureCodes
def featureCodeFile = new FileWriter("src/main/resources/geonames/featureCodes_en.txt")
featureCodeFile << "feature-code\tname\tdescription\n"

http = new HTTPBuilder('http://download.geonames.org/export/dump/featureCodes_en.txt')
http.request( GET, ANY ) { req ->

  // executed for all successful responses:
  response.success = { resp, reader ->
	  reader.each {
		  featureCodeFile << it + '\n'
	  }
  }
	
  // executed only if the response status code is 401:
  response.'404' = { resp ->
	  println 'not found!'
  }
}

//countryInfo
def countryInfoTempFile = new File("src/main/resources/geonames/temp.txt")
http = new HTTPBuilder('http://download.geonames.org/export/dump/countryInfo.txt')
http.request( GET, ANY ) { req ->
	
	  // executed for all successful responses:
	  response.success = { resp, reader ->
		  reader.each {
			  countryInfoTempFile << it + '\n'
		  }
	  }
		
	  // executed only if the response status code is 401:
	  response.'404' = { resp ->
		  println 'not found!'
	  }
	}
//now remove the first 50 lines from countryInfo.txt
def countryInfoFile = new File("src/main/resources/geonames/countryInfo.txt")
countryInfoTempFile.eachLine { line, lineNumber ->
	if ( lineNumber == 51 ) {
		countryInfoFile << line.replaceAll('#', '') + '\n'
	} else if ( lineNumber > 50) {
		countryInfoFile << line + '\n'
	}
}
countryInfoTempFile.delete()


