def cli = new CliBuilder(
  usage: 'downloadGeonames -c ISO-2-char-country-code',
  header: '\nAvailable options (use -h for help):\n',
  footer: '\nInformation provided via above options is used to generate printed string.\n')

cli.with
{
  h(longOpt: 'help', 'Usage Information', required: false)
  c(longOpt: 'country-code', 'ISO 2 char country code', args: 1, required: true)
}
def opt = cli.parse(args)
 
if (!opt) return
if (opt.h) cli.usage()
 
def countryCode = opt.c
def printOptions = opt.o

def geonamesFileName = "src/main/resources/geonames/data/${countryCode}/${countryCode}.txt"

if (new File(geonamesFileName).exists()) {
	println "${countryCode}.txt already exists."
} else {
	def url = "http://download.geonames.org/export/dump/${countryCode}.zip\n"
	print "Downloading ${url}"
	def fileZip = new File("src/main/resources/geonames/data/${countryCode}/${countryCode}.zip")
	new File("src/main/resources/geonames/data").mkdir()
	new File("src/main/resources/geonames/data/${countryCode}").mkdir()

	def file = new FileOutputStream("src/main/resources/geonames/data/${countryCode}/${countryCode}.zip")
	def out = new BufferedOutputStream(file)
	out << new URL(url).openStream()
	out.close()

	def ant = new AntBuilder()   // create an antbuilder

	ant.unzip(  src:"src/main/resources/geonames/data/${countryCode}/${countryCode}.zip",
			dest:"src/main/resources/geonames/data/${countryCode}/",
			overwrite:"true" )

	fileZip.delete()

	//insert geonames header
	def geonamesFile = new File(geonamesFileName)
	def geonamesFileTemp = new File("src/main/resources/geonames/data/${countryCode}/${countryCode}_temp.txt")
	geonamesFileTemp << "geonameid\tname\tasciiname\talternatenames\tlatitude\tlongitude\tfeature-class\tfeature-code\tcountry-code\tcc2\tadmin1-code\tadmin2-code\tadmin3-code\tadmin4-code\tpopulation\televation\tdem\ttimezone\tmodification-date\n"
	geonamesFileTemp.append(geonamesFile.getText())
	geonamesFile.delete()
	geonamesFileTemp.renameTo(geonamesFileName)
}


