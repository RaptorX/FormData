﻿#Requires Autohotkey v2.0-

/**
 * ============================================================================ *
 * @Author   : RaptorX                                                          *
 * @Homepage :                                                                  *
 *                                                                              *
 * @Created  : July 20, 2024                                                    *
 * @Modified : July 20, 2024                                                    *
 * ============================================================================ *
 */

/**
 * @version v1.0.0
 * @description Represents form data to be sent via HTTP.
 *
 * This class allows for the construction of multipart/form-data bodies,\
 * commonly used for file uploads and submitting forms with complex data.
 *
 * ---
 * ### Instance Properties
 *
 * @prop {String}      contentType - The Content-Type header for the form data.
 * @prop {String}      boundary    - The boundary string used to separate the parts of the form data.
 * @prop {ComObjArray} data        - The binary representation of the form data to be sent via the body of an HTTP request.
 *
 * ---
 * ### Methods
 * @method __New(data) - Creates a new FormData object handling binary files for HTTP requests.
 * 
 * ---
 * ### Example
 * 
 * ```
	parts := {
		token: '3c2e0e0119165134127ca631e551c5f8',
		upload_session: A_Now,
		numfiles: 1,
		gallery: false,
		adult: false,
		ui: false,
		optsize: false,
		upload_referer: 'https://postimages.org',
		mode: false,
		lang: false,
		content: false,
		forumurl: false,
		file: ['D:\Cloud\RaptorX\OneDrive\Pictures\Anime\37.jpg']
	}

	form := FormData(parts)

	http := ComObject('WinHttp.WinHttpRequest.5.1')

	http.Open('POST', 'https://postimg.cc/json?q=a')
	http.SetRequestHeader('Content-Type', form.contentType)
	http.Option(EnableRedirects:=6)

	http.Send(form.body)
	OutputDebug http.Status '`n'
	OutputDebug http.GetAllResponseHeaders() '`n'
	OutputDebug http.ResponseText '`n'

 * ```
 *
 */
class FormData {
	contentType := ''
	boundary := ''
	body := ''

	/**
	 * @description Creates a new FormData object handling binary files for HTTP requests.
	 *
	 * ---
	 * #### Parameters
	 * @param {Object}  data Parts that will be used to create the form data.
	 *
	 * ---
	 * #### Error Handling
	 * @throws {TypeError} when `data` is not an object
	 * @throws {TypeError} when `file` or `files` property is not an array of file paths
	 *
	 * ----
	 * #### Returns
	 * @returns {FormData} form data object with properties for the http request
	 *
	 * ---
	 */
	__New(data)
	{
		static adTypeBinary := 1
		static abc := '0|1|2|3|4|5|6|7|8|9'
		           .  '|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z'
		           .  '|A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z'

		boundary := '------------------------------' SubStr(StrReplace(Sort(abc, 'D| Random'), '|'), 1, 12)
		stream := ComObject('ADODB.Stream')
		stream.Open()
		stream.Charset := "utf-8"
		stream.Type := adTypeBinary

		if !IsObject(data)
			throw TypeError('data must be an object', A_ThisFunc, 'Got: ' Type(data))

		for prop, value in data.OwnProps()
		{
			switch prop, false
			{
			case 'File', 'Files':
				static file_part :=
				(Join`r`n
					'{}
					Content-Disposition: form-data; name="{}"; filename="{}"
					Content-Type: {}

					'
				)

				if Type(value) != 'Array'
					throw TypeError('Files must be an array', A_ThisFunc, 'Got: ' Type(value))

				for file in value
				{
					SplitPath file, &fileName
					StreamWrite(stream, Format(file_part, boundary, prop, fileName, GetMimeType(file)))
					StreamWrite(stream, FileRead(file, 'Raw'))
					StreamWrite(stream, '`r`n')
				}
			default:
				static form_part :=
				(Join`r`n
					'{}
					Content-Disposition: form-data; name="{}"

					{}
					'
				)

				StreamWrite(stream, Format(form_part, boundary, prop, value))
			}
		}
		StreamWrite(stream, Format("{}--`r`n", boundary))

		stream.Position := 0

		this.boundary      := boundary
		this.body          := stream.Read()
		this.contentType   := 'multipart/form-data; boundary=' SubStr(boundary, 3)
		stream.Close()
		return

		static StreamWrite(stream, value)
		{
			static VT_UI1 := 0x11

			switch Type(value)
			{
			case 'Buffer':
				varArray := ComObjArray(VT_UI1, value.size)
				loop value.Size
					varArray[A_Index - 1] := NumGet(value, A_Index - 1, "UChar")
			case 'String':
				varArray := ComObjArray(VT_UI1, StrLen(value))
				loop parse, value
					varArray[A_Index-1] := Ord(A_LoopField)
			}

			stream.Write(varArray)
		}

		static GetMimeType(filePath)
		{
			static magic_numbers := Map(
				"123", {
					signs: ["0,00001A00051004"],
					mime: "application/vnd.lotus-1-2-3"
				},
				"cpl", {
					signs: [
					"0,4D5A",
					"0,DCDC"
					],
					mime: "application/cpl+xml"
				},
				"epub", {
					signs: ["0,504B03040A000200"],
					mime: "application/epub+zip"
				},
				"ttf", {
					signs: ["0,0001000000"],
					mime: "application/font-sfnt"
				},
				"gz", {
					signs: ["0,1F8B08"],
					mime: "application/gzip"
				},
				"tgz", {
					signs: ["0,1F8B08"],
					mime: "application/gzip"
				},
				"hqx", {
					signs: ["0,28546869732066696C65206D75737420626520636F6E76657274656420776974682042696E48657820"],
					mime: "application/mac-binhex40"
				},
				"doc", {
					signs: [
					"0,0D444F43",
					"0,CF11E0A1B11AE100",
					"0,D0CF11E0A1B11AE1",
					"0,DBA52D00",
					"512,ECA5C100"
					],
					mime: "application/msword"
				},
				"mxf", {
					signs: [
					"0,060E2B34020501010D0102010102",
					"0,3C435472616E7354696D656C696E653E"
					],
					mime: "application/mxf"
				},
				"lha", {
					signs: ["2,2D6C68"],
					mime: "application/octet-stream"
				},
				"lzh", {
					signs: ["2,2D6C68"],
					mime: "application/octet-stream"
				},
				"exe", {
					signs: ["0,4D5A"],
					mime: "application/octet-stream"
				},
				"class", {
					signs: ["0,CAFEBABE"],
					mime: "application/octet-stream"
				},
				"dll", {
					signs: ["0,4D5A"],
					mime: "application/octet-stream"
				},
				"img", {
					signs: [
					"0,000100005374616E64617264204A6574204442",
					"0,504943540008",
					"0,514649FB",
					"0,53434D49",
					"0,7E742C015070024D52010000000800000001000031000000310000004301FF0001000800010000007e742c01",
					"0,EB3C902A"
					],
					mime: "application/octet-stream"
				},
				"iso", {
					signs: [
					"32769,4344303031",
					"34817,4344303031",
					"36865,4344303031"
					],
					mime: "application/octet-stream"
				},
				"ogx", {
					signs: ["0,4F67675300020000000000000000"],
					mime: "application/ogg"
				},
				"oxps", {
					signs: ["0,504B0304"],
					mime: "application/oxps"
				},
				"pdf", {
					signs: ["0,25504446"],
					mime: "application/pdf"
				},
				"p10", {
					signs: ["0,64000000"],
					mime: "application/pkcs10"
				},
				"pls", {
					signs: ["0,5B706C61796C6973745D"],
					mime: "application/pls+xml"
				},
				"eps", {
					signs: [
					"0,252150532D41646F62652D332E3020455053462D332030",
					"0,C5D0D3C6"
					],
					mime: "application/postscript"
				},
				"ai", {
					signs: ["0,25504446"],
					mime: "application/postscript"
				},
				"rtf", {
					signs: ["0,7B5C72746631"],
					mime: "application/rtf"
				},
				"tsa", {
					signs: ["0,47"],
					mime: "application/tamp-sequence-adjust"
				},
				"msf", {
					signs: ["0,2F2F203C212D2D203C6D64623A6D6F726B3A7A"],
					mime: "application/vnd.epson.msf"
				},
				"fdf", {
					signs: ["0,25504446"],
					mime: "application/vnd.fdf"
				},
				"fm", {
					signs: ["0,3C4D616B657246696C6520"],
					mime: "application/vnd.framemaker"
				},
				"kmz", {
					signs: ["0,504B0304"],
					mime: "application/vnd.google-earth.kmz"
				},
				"tpl", {
					signs: [
					"0,0020AF30",
					"0,6D7346696C7465724C697374"
					],
					mime: "application/vnd.groove-tool-template"
				},
				"kwd", {
					signs: ["0,504B0304"],
					mime: "application/vnd.kde.kword"
				},
				"wk4", {
					signs: ["0,00001A000210040000000000"],
					mime: "application/vnd.lotus-1-2-3"
				},
				"wk3", {
					signs: ["0,00001A000010040000000000"],
					mime: "application/vnd.lotus-1-2-3"
				},
				"wk1", {
					signs: ["0,0000020006040600080000000000"],
					mime: "application/vnd.lotus-1-2-3"
				},
				"apr", {
					signs: ["0,D0CF11E0A1B11AE1"],
					mime: "application/vnd.lotus-approach"
				},
				"nsf", {
					signs: [
					"0,1A0000040000",
					"0,4E45534D1A01"
					],
					mime: "application/vnd.lotus-notes"
				},
				"ntf", {
					signs: [
					"0,1A0000",
					"0,30314F52444E414E43452053555256455920202020202020",
					"0,4E49544630"
					],
					mime: "application/vnd.lotus-notes"
				},
				"org", {
					signs: ["0,414F4C564D313030"],
					mime: "application/vnd.lotus-organizer"
				},
				"lwp", {
					signs: ["0,576F726450726F"],
					mime: "application/vnd.lotus-wordpro"
				},
				"sam", {
					signs: ["0,5B50686F6E655D"],
					mime: "application/vnd.lotus-wordpro"
				},
				"mif", {
					signs: [
					"0,3C4D616B657246696C6520",
					"0,56657273696F6E20"
					],
					mime: "application/vnd.mif"
				},
				"xul", {
					signs: ["0,3C3F786D6C2076657273696F6E3D22312E30223F3E"],
					mime: "application/vnd.mozilla.xul+xml"
				},
				"asf", {
					signs: ["0,3026B2758E66CF11A6D900AA0062CE6C"],
					mime: "application/vnd.ms-asf"
				},
				"cab", {
					signs: [
					"0,49536328",
					"0,4D534346"
					],
					mime: "application/vnd.ms-cab-compressed"
				},
				"xls", {
					signs: [
					"512,0908100000060500",
					"0,D0CF11E0A1B11AE1",
					"512,FDFFFFFF04",
					"512,FDFFFFFF20000000"
					],
					mime: "application/vnd.ms-excel"
				},
				"xla", {
					signs: ["0,D0CF11E0A1B11AE1"],
					mime: "application/vnd.ms-excel"
				},
				"chm", {
					signs: ["0,49545346"],
					mime: "application/vnd.ms-htmlhelp"
				},
				"ppt", {
					signs: [
					"512,006E1EF0",
					"512,0F00E803",
					"512,A0461DF0",
					"0,D0CF11E0A1B11AE1",
					"512,FDFFFFFF04"
					],
					mime: "application/vnd.ms-powerpoint"
				},
				"pps", {
					signs: ["0,D0CF11E0A1B11AE1"],
					mime: "application/vnd.ms-powerpoint"
				},
				"wks", {
					signs: [
					"0,0E574B53",
					"0,FF000200040405540200"
					],
					mime: "application/vnd.ms-works"
				},
				"wpl", {
					signs: ["84,4D6963726F736F66742057696E646F7773204D6564696120506C61796572202D2D20"],
					mime: "application/vnd.ms-wpl"
				},
				"xps", {
					signs: ["0,504B0304"],
					mime: "application/vnd.ms-xpsdocument"
				},
				"cif", {
					signs: ["2,5B56657273696F6E"],
					mime: "application/vnd.multiad.creator.cif"
				},
				"odp", {
					signs: ["0,504B0304"],
					mime: "application/vnd.oasis.opendocument.presentation"
				},
				"odt", {
					signs: ["0,504B0304"],
					mime: "application/vnd.oasis.opendocument.text"
				},
				"ott", {
					signs: ["0,504B0304"],
					mime: "application/vnd.oasis.opendocument.text-template"
				},
				"pptx", {
					signs: ["0,504B030414000600"],
					mime: "application/vnd.openxmlformats-officedocument.presentationml.presentation"
				},
				"xlsx", {
					signs: ["0,504B030414000600"],
					mime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
				},
				"docx", {
					signs: ["0,504B030414000600"],
					mime: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
				},
				"prc", {
					signs: [
					"0,424F4F4B4D4F4249",
					"60,74424D504B6E5772"
					],
					mime: "application/vnd.palm"
				},
				"pdb", {
					signs: [
					"11,000000000000000000000000000000000000000000000000",
					"0,4D2D5720506F636B6574204469637469",
					"0,4D6963726F736F667420432F432B2B20",
					"0,736D5F",
					"0,737A657A",
					"0,ACED0005737200126267626C69747A2E"
					],
					mime: "application/vnd.palm"
				},
				"qxd", {
					signs: ["0,00004D4D585052"],
					mime: "application/vnd.Quark.QuarkXPress"
				},
				"rar", {
					signs: [
					"0,526172211A0700",
					"0,526172211A070100"
					],
					mime: "application/vnd.rar"
				},
				"mmf", {
					signs: ["0,4D4D4D440000"],
					mime: "application/vnd.smaf"
				},
				"cap", {
					signs: [
					"0,52545353",
					"0,58435000"
					],
					mime: "application/vnd.tcpdump.pcap"
				},
				"dmp", {
					signs: [
					"0,4D444D5093A7",
					"0,5041474544553634",
					"0,5041474544554D50"
					],
					mime: "application/vnd.tcpdump.pcap"
				},
				"wpd", {
					signs: ["0,FF575043"],
					mime: "application/vnd.wordperfect"
				},
				"xar", {
					signs: ["0,78617221"],
					mime: "application/vnd.xara"
				},
				"spf", {
					signs: ["0,5350464900"],
					mime: "application/vnd.yamaha.smaf-phrase"
				},
				"dtd", {
					signs: ["0,0764743264647464"],
					mime: "application/xml-dtd"
				},
				"zip", {
					signs: [
					"0,504B0304",
					"0,504B0304",
					"0,504B030414000100630000000000",
					"0,504B0708",
					"30,504B4C495445",
					"526,504B537058",
					"29152,57696E5A6970"
					],
					mime: "application/zip"
				},
				"amr", {
					signs: ["0,2321414D52"],
					mime: "audio/AMR"
				},
				"au", {
					signs: [
					"0,2E736E64",
					"0,646E732E"
					],
					mime: "audio/basic"
				},
				"m4a", {
					signs: [
					"0,00000020667479704D344120",
					"4,667479704D344120"
					],
					mime: "audio/mp4"
				},
				"mp3", {
					signs: [
					"0,494433",
					"0,FFFB"
					],
					mime: "audio/mpeg"
				},
				"oga", {
					signs: ["0,4F67675300020000000000000000"],
					mime: "audio/ogg"
				},
				"ogg", {
					signs: ["0,4F67675300020000000000000000"],
					mime: "audio/ogg"
				},
				"qcp", {
					signs: ["0,52494646"],
					mime: "audio/qcelp"
				},
				"koz", {
					signs: ["0,49443303000000"],
					mime: "audio/vnd.audikoz"
				},
				"bmp", {
					signs: ["0,424D"],
					mime: "image/bmp"
				},
				"dib", {
					signs: ["0,424D"],
					mime: "image/bmp"
				},
				"emf", {
					signs: ["0,01000000"],
					mime: "image/emf"
				},
				"fits", {
					signs: ["0,53494D504C4520203D202020202020202020202020202020202020202054"],
					mime: "image/fits"
				},
				"gif", {
					signs: ["0,474946383961"],
					mime: "image/gif"
				},
				"jp2", {
					signs: ["0,0000000C6A5020200D0A"],
					mime: "image/jp2"
				},
				"jpg", {
					signs: ["0,FFD8"],
					mime: "image/jpeg"
				},
				"jpeg", {
					signs: ["0,FFD8"],
					mime: "image/jpeg"
				},
				"jpe", {
					signs: ["0,FFD8"],
					mime: "image/jpeg"
				},
				"jfif", {
					signs: ["0,FFD8"],
					mime: "image/jpeg"
				},
				"png", {
					signs: ["0,89504E470D0A1A0A"],
					mime: "image/png"
				},
				"tiff", {
					signs: [
					"0,492049",
					"0,49492A00",
					"0,4D4D002A",
					"0,4D4D002B"
					],
					mime: "image/tiff"
				},
				"tif", {
					signs: [
					"0,492049",
					"0,49492A00",
					"0,4D4D002A",
					"0,4D4D002B"
					],
					mime: "image/tiff"
				},
				"psd", {
					signs: ["0,38425053"],
					mime: "image/vnd.adobe.photoshop"
				},
				"dwg", {
					signs: ["0,41433130"],
					mime: "image/vnd.dwg"
				},
				"ico", {
					signs: ["0,00000100"],
					mime: "image/vnd.microsoft.icon"
				},
				"mdi", {
					signs: ["0,4550"],
					mime: "image/vnd.ms-modi"
				},
				"hdr", {
					signs: [
					"0,233F52414449414E43450A",
					"0,49536328"
					],
					mime: "image/vnd.radiance"
				},
				"pcx", {
					signs: ["512,0908100000060500"],
					mime: "image/vnd.zbrush.pcx"
				},
				"wmf", {
					signs: [
					"0,010009000003",
					"0,D7CDC69A"
					],
					mime: "image/wmf"
				},
				"eml", {
					signs: [
					"0,46726F6D3A20",
					"0,52657475726E2D506174683A20",
					"0,582D"
					],
					mime: "message/rfc822"
				},
				"art", {
					signs: ["0,4A47040E"],
					mime: "message/rfc822"
				},
				"manifest", {
					signs: ["0,3C3F786D6C2076657273696F6E3D"],
					mime: "text/cache-manifest"
				},
				"log", {
					signs: ["0,2A2A2A2020496E7374616C6C6174696F6E205374617274656420"],
					mime: "text/plain"
				},
				"tsv", {
					signs: ["0,47"],
					mime: "text/tab-separated-values"
				},
				"vcf", {
					signs: ["0,424547494E3A56434152440D0A"],
					mime: "text/vcard"
				},
				"dms", {
					signs: ["0,444D5321"],
					mime: "text/vnd.DMClientScript"
				},
				"dot", {
					signs: ["0,D0CF11E0A1B11AE1"],
					mime: "text/vnd.graphviz"
				},
				"ts", {
					signs: ["0,47"],
					mime: "text/vnd.trolltech.linguist"
				},
				"3gp", {
					signs: [
					"0,0000001466747970336770",
					"0,0000002066747970336770"
					],
					mime: "video/3gpp"
				},
				"3g2", {
					signs: [
					"0,0000001466747970336770",
					"0,0000002066747970336770"
					],
					mime: "video/3gpp2"
				},
				"mp4", {
					signs: [
					"0,000000146674797069736F6D",
					"0,000000186674797033677035",
					"0,0000001C667479704D534E56012900464D534E566D703432",
					"4,6674797033677035",
					"4,667479704D534E56",
					"4,6674797069736F6D"
					],
					mime: "video/mp4"
				},
				"m4v", {
					signs: [
					"0,00000018667479706D703432",
					"0,00000020667479704D345620",
					"4,667479706D703432"
					],
					mime: "video/mp4"
				},
				"mpeg", {
					signs: [
					"0,00000100",
					"0,FFD8"
					],
					mime: "video/mpeg"
				},
				"mpg", {
					signs: [
					"0,00000100",
					"0,000001BA",
					"0,FFD8"
					],
					mime: "video/mpeg"
				},
				"ogv", {
					signs: ["0,4F67675300020000000000000000"],
					mime: "video/ogg"
				},
				"mov", {
					signs: [
					"0,00",
					"0,000000146674797071742020",
					"4,6674797071742020",
					"4,6D6F6F76"
					],
					mime: "video/quicktime"
				},
				"cpt", {
					signs: [
					"0,4350543746494C45",
					"0,43505446494C45"
					],
					mime: "application/mac-compactpro"
				},
				"sxc", {
					signs: [
					"0,504B0304",
					"0,504B0304"
					],
					mime: "application/vnd.sun.xml.calc"
				},
				"sxd", {
					signs: ["0,504B0304"],
					mime: "application/vnd.sun.xml.draw"
				},
				"sxi", {
					signs: ["0,504B0304"],
					mime: "application/vnd.sun.xml.impress"
				},
				"sxw", {
					signs: ["0,504B0304"],
					mime: "application/vnd.sun.xml.writer"
				},
				"bz2", {
					signs: ["0,425A68"],
					mime: "application/x-bzip2"
				},
				"vcd", {
					signs: ["0,454E5452595643440200000102001858"],
					mime: "application/x-cdlink"
				},
				"csh", {
					signs: ["0,6375736800000002000000"],
					mime: "application/x-csh"
				},
				"spl", {
					signs: ["0,00000100"],
					mime: "application/x-futuresplash"
				},
				"jar", {
					signs: [
					"0,4A4152435300",
					"0,504B0304",
					"0,504B0304140008000800",
					"0,5F27A889"
					],
					mime: "application/x-java-archive"
				},
				"rpm", {
					signs: ["0,EDABEEDB"],
					mime: "application/x-rpm"
				},
				"swf", {
					signs: [
					"0,435753",
					"0,465753",
					"0,5A5753"
					],
					mime: "application/x-shockwave-flash"
				},
				"sit", {
					signs: [
					"0,5349542100",
					"0,5374756666497420286329313939372D"
					],
					mime: "application/x-stuffit"
				},
				"tar", {
					signs: ["257,7573746172"],
					mime: "application/x-tar"
				},
				"xpi", {
					signs: ["0,504B0304"],
					mime: "application/x-xpinstall"
				},
				"xz", {
					signs: ["0,FD377A585A00"],
					mime: "application/x-xz"
				},
				"mid", {
					signs: ["0,4D546864"],
					mime: "audio/midi"
				},
				"midi", {
					signs: ["0,4D546864"],
					mime: "audio/midi"
				},
				"aiff", {
					signs: ["0,464F524D00"],
					mime: "audio/x-aiff"
				},
				"flac", {
					signs: ["0,664C614300000022"],
					mime: "audio/x-flac"
				},
				"wma", {
					signs: ["0,3026B2758E66CF11A6D900AA0062CE6C"],
					mime: "audio/x-ms-wma"
				},
				"ram", {
					signs: ["0,727473703A2F2F"],
					mime: "audio/x-pn-realaudio"
				},
				"rm", {
					signs: ["0,2E524D46"],
					mime: "audio/x-pn-realaudio"
				},
				"ra", {
					signs: [
					"0,2E524D460000001200",
					"0,2E7261FD00"
					],
					mime: "audio/x-realaudio"
				},
				"wav", {
					signs: ["0,52494646"],
					mime: "audio/x-wav"
				},
				"webp", {
					signs: ["0,52494646"],
					mime: "image/webp"
				},
				"pgm", {
					signs: ["0,50350A"],
					mime: "image/x-portable-graymap"
				},
				"rgb", {
					signs: ["0,01DA01010003"],
					mime: "image/x-rgb"
				},
				"webm", {
					signs: ["0,1A45DFA3"],
					mime: "video/webm"
				},
				"flv", {
					signs: [
					"0,00000020667479704D345620",
					"0,464C5601"
					],
					mime: "video/x-flv"
				},
				"mkv", {
					signs: ["0,1A45DFA3"],
					mime: "video/x-matroska"
				},
				"asx", {
					signs: ["0,3C"],
					mime: "video/x-ms-asf"
				},
				"wmv", {
					signs: ["0,3026B2758E66CF11A6D900AA0062CE6C"],
					mime: "video/x-ms-wmv"
				},
				"avi", {
					signs: ["0,52494646"],
					mime: "video/x-msvideo"
				}
			)

			SplitPath filePath,,, &ext
			ext := StrLower(ext)

			try {
				; Check for magic numbers
				try {
					file := FileOpen(filePath, "r")

					if magic_numbers.Has(ext)
					{
						for sign in magic_numbers[ext].signs
						{
							offset := StrSplit(sign, ",")[1]
							signature := StrSplit(sign, ",")[2]
							file.Seek(offset)

							loop StrLen(signature) // 2
								bytes .= Format('{:02X}', file.ReadUChar())

							if bytes == signature
								return magic_numbers[ext].mime
						}
					}
				}
				catch Error as e
					throw e
				finally
					file.Close()

				; If no match, check for text files
				try {
					file := FileOpen(filePath, "r")
					isText := true
					loop 16 {
						int64 .= file.ReadInt64()
						if !(int64 ~= '00') ; doesnt contain null byte
							continue
						isText := false
						break
					}

					if isText
						return "text/plain"
				}
				catch Error as e
					throw e
				finally
					file.Close()
			}
			catch as err {
				; If there's an error reading the file, default to octet-stream
				return "application/octet-stream"
			}

			; Use file extension as a backup if magic numbers don't match
			switch ext
			{
			case 'aac'   : return 'audio/aac'
			case 'abw'   : return 'application/x-abiword'
			case 'apng'  : return 'image/apng'
			case 'arc'   : return 'application/x-freearc'
			case 'avif'  : return 'image/avif'
			case 'avi'   : return 'video/x-msvideo'
			case 'azw'   : return 'application/vnd.amazon.ebook'
			case 'bin'   : return 'application/octet-stream'
			case 'bmp'   : return 'image/bmp'
			case 'bz'    : return 'application/x-bzip'
			case 'bz2'   : return 'application/x-bzip2'
			case 'cda'   : return 'application/x-cdf'
			case 'csh'   : return 'application/x-csh'
			case 'css'   : return 'text/css'
			case 'csv'   : return 'text/csv'
			case 'doc'   : return 'application/msword'
			case 'docx'  : return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
			case 'eot'   : return 'application/vnd.ms-fontobject'
			case 'epub'  : return 'application/epub+zip'
			case 'gz'    : return 'application/gzip'
			case 'gif'   : return 'image/gif'
			case 'html'  : return 'text/html'
			case 'htm'   : return 'text/html'
			case 'ico'   : return 'image/vnd.microsoft.icon'
			case 'ics'   : return 'text/calendar'
			case 'jar'   : return 'application/java-archive'
			case 'jpeg'  : return 'image/jpeg'
			case 'jpg'   : return 'image/jpeg'
			case 'js'    : return 'text/javascript'
			case 'json'  : return 'application/json'
			case 'jsonld': return 'application/ld+json'
			case 'mid'   : return 'audio/midi, audio/x-midi'
			case 'midi'  : return 'audio/midi, audio/x-midi'
			case 'mjs'   : return 'text/javascript'
			case 'mp3'   : return 'audio/mpeg'
			case 'mp4'   : return 'video/mp4'
			case 'mpeg'  : return 'video/mpeg'
			case 'mpkg'  : return 'application/vnd.apple.installer+xml'
			case 'odp'   : return 'application/vnd.oasis.opendocument.presentation'
			case 'ods'   : return 'application/vnd.oasis.opendocument.spreadsheet'
			case 'odt'   : return 'application/vnd.oasis.opendocument.text'
			case 'oga'   : return 'audio/ogg'
			case 'ogv'   : return 'video/ogg'
			case 'ogx'   : return 'application/ogg'
			case 'opus'  : return 'audio/ogg'
			case 'otf'   : return 'font/otf'
			case 'png'   : return 'image/png'
			case 'pdf'   : return 'application/pdf'
			case 'php'   : return 'application/x-httpd-php'
			case 'ppt'   : return 'application/vnd.ms-powerpoint'
			case 'pptx'  : return 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
			case 'rar'   : return 'application/vnd.rar'
			case 'rtf'   : return 'application/rtf'
			case 'sh'    : return 'application/x-sh'
			case 'svg'   : return 'image/svg+xml'
			case 'tar'   : return 'application/x-tar'
			case 'tif'   : return 'image/tiff'
			case 'tiff'  : return 'image/tiff'
			case 'ts'    : return 'video/mp2t'
			case 'ttf'   : return 'font/ttf'
			case 'txt'   : return 'text/plain'
			case 'vsd'   : return 'application/vnd.visio'
			case 'wav'   : return 'audio/wav'
			case 'weba'  : return 'audio/webm'
			case 'webm'  : return 'video/webm'
			case 'webp'  : return 'image/webp'
			case 'woff'  : return 'font/woff'
			case 'woff2' : return 'font/woff2'
			case 'xhtml' : return 'application/xhtml+xml'
			case 'xls'   : return 'application/vnd.ms-excel'
			case 'xlsx'  : return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
			case 'xml'   : return 'application/xml'
			case 'xul'   : return 'application/vnd.mozilla.xul+xml'
			case 'zip'   : return 'application/zip'
			case '3gp'   : return 'video/3gpp'
			case '3g2'   : return 'video/3gpp2'
			case '7z'    : return 'application/x-7z-compressed'
			default      : return "application/octet-stream"
			}
		}
	}
}