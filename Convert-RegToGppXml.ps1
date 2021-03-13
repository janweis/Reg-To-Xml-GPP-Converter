#requires -Version 3.0

<#
		Author: Jan Weis
		Homepage: www.it-explorations.de
		Mail: jan.weis@it-explorations.de
        
		# >
		# > Wandelt Reg-Dateien in XML-Dateien für die GroupPolicyPreferences um.
		# > Converts Reg-Files to XML-Files for GroupPolicyPreferences
		# >

		[v1.3.1] - 10.2019
		+ Bessere Fehlerbehandlung für Reg Typenerkennung
		+ Skriptoptimierungen
		+ Kommentare werden nun nicht mehr als Warnung angezeigt

		[v1.3] - 10.2019
		+ Paramenter umbenannt
		+ Paramenterprüfung verbessert
		+ Powershellcommands durch schnellere Net.Framework-Klassen ersetzt
		+ Codebasis umgeschrieben
		+ Fehlerbehebung in der Verarbeitung von REG_QWORD
		+ Verbesserung der Datenerkennung
		+ XML-Eintrag für Default verbessert
		+ ü 100.000 RegKey-Tests fehlerfrei
#>


Param
(
	[Parameter(Mandatory, Position = 0, HelpMessage = 'Add help message for user')]
	[string[]]
	$FilePath,

	[Parameter(Position = 1)]
	[ValidateSet('Create', 'Update', 'Delete', 'Replace')]
	[string]
	$ActionType = 'Update'
)

begin {
	Write-Output -InputObject $(("`n[ Registry-To-XML Converter 1.3.1 von Jan Weis ]").ToUpper())
	Write-Output -InputObject "[ Web: www.it-explorations.de; Mail: jan.weis@it-explorations.de ]`n"
    

	# #
	# Funcions / Funktionen
	#

	function Convert-HexToString {
		<#
				.SYNOPSIS
				Describe purpose of "Convert-HexToString" in 1-2 sentences.

				.DESCRIPTION
				Add a more complete description of what the function does.

				.PARAMETER HexData
				Describe parameter -HexData.

				.EXAMPLE
				Convert-HexToString -HexData Value
				Describe what this call does

				.NOTES
				Place additional notes here.

				.LINK
				URLs to related sites
				The first link is opened by Get-Help -Online Convert-HexToString

				.INPUTS
				List of input types that are accepted by this function.

				.OUTPUTS
				List of output types produced by this function.
		#>


		param (
			[Parameter(Mandatory, HelpMessage = 'Add help message for user')]
			[string]
			$HexData
		)
    
		try {
			[string[]]$HexDataArray = $HexData.Split(',')

			[Byte[]]$ByteArray = ForEach ($HexItem in $HexDataArray) {
				[byte]::Parse($HexItem , [Globalization.NumberStyles]::HexNumber)
			}

			Return ([Text.Encoding]::Unicode.GetString($ByteArray))
		}
		catch {
			Write-Warning -Message ('[Convert-HexToString] {0}' -f $_)
			Write-Debug -Message ('[Convert-HexToString DEBUG] {0}' -f $HexData)
			Return $null
		}
	}
  
	function New-XmlWriter {
		<#
				.SYNOPSIS
				Describe purpose of "New-XmlWriter" in 1-2 sentences.

				.DESCRIPTION
				Add a more complete description of what the function does.

				.PARAMETER FileOutPath
				Describe parameter -FileOutPath.

				.EXAMPLE
				New-XmlWriter -FileOutPath Value
				Describe what this call does

				.NOTES
				Place additional notes here.

				.LINK
				URLs to related sites
				The first link is opened by Get-Help -Online New-XmlWriter

				.INPUTS
				List of input types that are accepted by this function.

				.OUTPUTS
				List of output types produced by this function.
		#>


		param
		(
			[Parameter(Mandatory, HelpMessage = 'Add help message for user')]
			[string]
			$FileOutPath
		)
    
		try {
			# XML-WRITER-SETTINGS
			$objXmlWriterSettings = [Xml.XmlWriterSettings]::new()
			$objXmlWriterSettings.Indent = $True
			$objXmlWriterSettings.Encoding = [Text.Encoding]::Unicode
			$objXmlWriterSettings.OmitXmlDeclaration = $True
      
			# XML-WRITER
			$objXmlWriter = [Xml.XmlWriter]::Create($FileOutPath, $objXmlWriterSettings)
			$objXmlWriter.WriteStartDocument()
			$objXmlWriter.WriteStartElement('RegistrySettings')
			$objXmlWriter.WriteAttributeString('clsid', '{A3CCFC41-DFDB-43a5-8D26-0FE8B954DA51}')

			Return $objXmlWriter
		}
		catch {
			Write-Warning -Message ('[New-XmlWriter] {0}' -f $_)
			Return $null
		}
	}

	function New-XmlEntry {
		<#
				.SYNOPSIS
				Describe purpose of "New-XmlEntry" in 1-2 sentences.

				.DESCRIPTION
				Add a more complete description of what the function does.

				.PARAMETER MainXmlWriter
				Describe parameter -MainXmlWriter.

				.PARAMETER Eintrag
				Describe parameter -Eintrag.

				.PARAMETER Wert
				Describe parameter -Wert.

				.PARAMETER Art
				Describe parameter -Art.

				.PARAMETER ActionType
				Describe parameter -ActionType.

				.PARAMETER Hive
				Describe parameter -Hive.

				.PARAMETER Key
				Describe parameter -Key.

				.PARAMETER SetDefaultEntry
				Describe parameter -SetDefaultEntry.

				.PARAMETER ExtendedValue
				Describe parameter -ExtendedValue.

				.EXAMPLE
				New-XmlEntry -MainXmlWriter Value -Eintrag Value -Wert Value -Art Value -ActionType Value -Hive Value -Key Value -SetDefaultEntry Value -ExtendedValue Value
				Describe what this call does

				.NOTES
				Place additional notes here.

				.LINK
				URLs to related sites
				The first link is opened by Get-Help -Online New-XmlEntry

				.INPUTS
				List of input types that are accepted by this function.

				.OUTPUTS
				List of output types produced by this function.
		#>


		param
		(
			[Parameter(Mandatory, HelpMessage = 'Add help message for user')]
			[Xml.XmlWriter]
			$MainXmlWriter,

			[string]
			$Eintrag = '',
			
			[string]$Wert = '',

			[Parameter(Mandatory, HelpMessage = 'Add help message for user')]
			[ValidateSet('REG_SZ', 'REG_DWORD', 'REG_EXPAND_SZ', 'REG_MULTI_SZ', 'REG_QWORD', 'REG_BINARY', 'REG_NONE')]
			[String]
			$Art, 

			[Parameter(ValueFromPipeline)]
			[ValidateSet('Create', 'Update', 'Delete', 'Replace')]
			[String]
			$ActionType = 'Update',

			[Parameter(Mandatory, HelpMessage = 'Add help message for user')]
			[String]
			$Hive, # HKEY_LOCAL_MACHINE

			[Parameter(Mandatory, HelpMessage = 'Add help message for user')]
			[String]
			$Key, # SOFTWARE\Intel\Display\igfxcui

			[bool]
			$SetDefaultEntry = $false,

			[string[]]
			$ExtendedValue = $null
		)
		
		[Int]$intDefault = 0 # INIT
		
		If ($Art -like 'REG_NONE') {
			Write-Warning -Message '[*] REG_NONE wird nicht unterstützt!'
			Return $True
		}
		
		If ($SetDefaultEntry) {
			[Int]$intDefault = 1
		}
		
		if ($Art -eq 'REG_SZ' -or $Art -eq 'REG_EXPAND_SZ' -or $Art -eq 'REG_MULTI_SZ') {
			Switch ($ActionType) {
				'Create' {
					$Type = 'C'
					$intImage = 5
				}
				'Delete' {
					$Type = 'D'
					$intImage = 8
				}
				'Replace' {
					$Type = 'R'
					$intImage = 6
				}
				'Update' {
					$Type = 'U'
					$intImage = 7
				}
			}
		}
		Else {
			Switch ($ActionType) {
				'Create' {
					$Type = 'C'
					$intImage = 10
				}
				'Delete' {
					$Type = 'D'
					$intImage = 13
				}
				'Replace' {
					$Type = 'R'
					$intImage = 11
				}
				'Update' {
					$Type = 'U'
					$intImage = 15
				}
			}
		}
    
		try {
			# DEFAULT Registry
			$MainXmlWriter.WriteStartElement('Registry') # Open Registry
			$MainXmlWriter.WriteAttributeString('clsid', '{9CD4B2F4-923D-47f5-A062-E897DD1DAD50}')

			# SETTINGS Registry
			If ($SetDefaultEntry) {
				# Standard-Eintrag
				$MainXmlWriter.WriteAttributeString('name', 'Hive')
				$MainXmlWriter.WriteAttributeString('status', '(Default)')
			}
			else {
				# Daten-Eintrag
				$MainXmlWriter.WriteAttributeString('name', $Eintrag)
				$MainXmlWriter.WriteAttributeString('status', $Eintrag)
			}
			
			$MainXmlWriter.WriteAttributeString('image', $intImage)
			$MainXmlWriter.WriteAttributeString('descr', 'Imported with RegToGppXML-Converter (it-explorations.de)')
    
			# SETTINGS Properties
			$MainXmlWriter.WriteStartElement('Properties') # Open Properties
			$MainXmlWriter.WriteAttributeString('action', $Type)
			$MainXmlWriter.WriteAttributeString('hive', $Hive)
			$MainXmlWriter.WriteAttributeString('key', $Key)
			$MainXmlWriter.WriteattributeString('name', $Eintrag)
			$MainXmlWriter.WriteattributeString('type', $Art)
			$MainXmlWriter.WriteAttributeString('displayDecimal', 0)
			$MainXmlWriter.WriteAttributeString('value', $Wert)
			$MainXmlWriter.WriteAttributeString('default', $intDefault)
			#$objWriter.WriteAttributeString('bitfield','')
    
			# SPEZIAL FÜR REG_MULTI_SZ
			if ($ExtendedValue) {
				$MainXmlWriter.WriteStartElement('Values')
				
				ForEach ($ExtendedItem in $ExtendedValue) {
					$MainXmlWriter.WriteStartElement('Value')
					$MainXmlWriter.WriteString($ExtendedItem)
					$null = Close-XmlEntry -XmlWriter $MainXmlWriter # Value
				
				}

				$null = Close-XmlEntry -XmlWriter $MainXmlWriter # Values
			}

			# CLOSE WRITER
			$null = Close-XmlEntry -XmlWriter $MainXmlWriter # Properties
			$null = Close-XmlEntry -XmlWriter $MainXmlWriter # Registry

			Write-Verbose -Message '[New-XmlEntry] Eintrag erfolgreich geschrieben!'
			Return $True 
		}
		catch {
			Write-Warning -Message ('[New-XmlEntry] {0}' -f $_)
			Write-Warning -Message ("[New-XmlEntry DEBUG] Typ:'{0}'; Hive:'{1}'; Key:'{2}'; Eintrag:'{3}'; Wert:'{4}'" -f $Art, $Hive, $Key, $Eintrag, $Wert)
			Return $false
		}
	}

	function Close-XmlEntry {
		<#
				.SYNOPSIS
				Describe purpose of "Close-XmlEntry" in 1-2 sentences.

				.DESCRIPTION
				Add a more complete description of what the function does.

				.PARAMETER XmlWriter
				Describe parameter -XmlWriter.

				.EXAMPLE
				Close-XmlEntry -XmlWriter Value
				Describe what this call does

				.NOTES
				Place additional notes here.

				.LINK
				URLs to related sites
				The first link is opened by Get-Help -Online Close-XmlEntry

				.INPUTS
				List of input types that are accepted by this function.

				.OUTPUTS
				List of output types produced by this function.
		#>


		param
		(
			[Parameter(Mandatory, HelpMessage = 'Add help message for user')]
			[Xml.XmlWriter]
			$XmlWriter
		)
    
		try {
			# Schließe Eintrag
			$XmlWriter.WriteEndElement()
			$XmlWriter.Flush()

			Write-Verbose -Message '[Close-XmlEntry] XML-Eintrag wurde erfolgreich geschlossen!'
			return $True
		}
		catch {
			Write-Warning -Message ('[Close-XmlEntry] {0}' -f $_)
			return $false
		}
	}
 
	function New-XmlCollection {
		<#
				.SYNOPSIS
				Describe purpose of "New-XmlCollection" in 1-2 sentences.

				.DESCRIPTION
				Add a more complete description of what the function does.

				.PARAMETER Value
				Describe parameter -Value.

				.PARAMETER objWriter
				Describe parameter -objWriter.

				.EXAMPLE
				New-XmlCollection -Value Value -objWriter Value
				Describe what this call does

				.NOTES
				Place additional notes here.

				.LINK
				URLs to related sites
				The first link is opened by Get-Help -Online New-XmlCollection

				.INPUTS
				List of input types that are accepted by this function.

				.OUTPUTS
				List of output types produced by this function.
		#>


		param
		(
			[Parameter(Mandatory, HelpMessage = 'Add help message for user', ValueFromPipeline)]
			[string]
			$Value,

			[Parameter(Mandatory, HelpMessage = 'Add help message for user')]
			[Xml.XmlWriter]
			$objWriter
		)
    
		try {
			$objWriter.WriteStartElement('Collection')
			$objWriter.WriteAttributeString('clsid', '{53B533F5-224C-47e3-B01B-CA3B3F3FF4BF}')
			$objWriter.WriteAttributeString('name', $Value)
    
			Write-Verbose -Message '[New-XmlCollection] Neue Collection wurde erfolgreich angelegt!'
			Return $True
		}
		catch {
			Write-Warning -Message ('[New-XmlCollection] {0}' -f $_)
			Return $false
		}
	}
}

process {
	# #
	# Script / Skript
	#

	Write-Progress -Activity 'Registry To XML Converter' -Status 'REG-Datei wird eingelesen'
    
	ForEach ($FileItemPath in $FilePath) {
		[string]$Wert = '' # INIT
		[string]$strHive = '' # INIT
		[string]$strKey = '' # INIT
		[string]$straHeader = '' # INIT
		[String[]]$straHeaderBefore = '' # INIT
		$CurrentLineNumber = 0 # INIT


		#
		# Prerequisites / Checks / Voraussetzungen
		#

		# Valid String
		$FileItemPath = $FileItemPath.replace('"', '').trim()
        
		# Valid Path
		If ((Test-Path -Path $FileItemPath) -eq $false) {
			Write-Warning -Message ('File not exist. FilePath:{0}' -f $FileItemPath)
			Continue
		}
     
		# Valid Filetype
		If ((Get-Item -Path $FileItemPath).Extension -notlike '.reg') {
			Write-Error -Message 'Wrong Filetype! Only REG acceppted.'
			Continue
		} 


		#
		# Let´s go to Work! / Auf gehts :)
		#

		[IO.StreamReader]$StreamReader = [IO.File]::OpenText($FileItemPath)
        
		If ($null -eq $StreamReader) {
			Write-Warning -Message '[*] Fehler: Datei kann nicht gelesen werden!'
			Continue
		}
        
		[string]$FileItemOutputPath = ('{0}.xml' -f $FileItemPath)
		[Xml.XmlWriter]$XmlWriter = New-XmlWriter -FileOutPath $FileItemOutputPath
        
		If ($null -eq $XmlWriter) {
			Write-Warning -Message '[*] Fehler: Kein XML-Writer vorhanden!'
			Continue
		}
        
		[long]$CurrentLineNumber = 0
        
		while ($StreamReader.EndOfStream.Equals($false) -and ($XmlWriter.WriteState -ne 5)) {
			[string]$RegItemData = '' # INIT
			[string]$RegItemName = '' # INIT
			[string]$RegItemDataType = '' # INIT
			[bool]$RegItemDefaultEntry = $false # INIT
			
			# Lese neue Zeile ein
			[string]$CurrentLineContent = $StreamReader.ReadLine()
			Write-Progress -Activity 'Registry To XML Converter' -CurrentOperation 'Verarbeite REG-Datei' -Status $CurrentLineNumber
			$CurrentLineNumber++
			
			switch ($CurrentLineContent[0]) {
				'[' { # Header
					# DEFINIERE AKTUELLEN HEADER
					[String[]]$straHeader = $CurrentLineContent.Replace('[', '').Replace(']', '').Split('\')

					# VERGLEICHE ALTEN UND NEUEN HEADER
					$objRegHeaderCompareList = Compare-Object -ReferenceObject $straHeaderBefore -DifferenceObject $straHeader -PassThru | Where-Object -FilterScript {
						$_ -ne ''
					}

					# Close old Header and open new Header
					$objRegHeaderCompareList |`
						Where-Object -FilterScript { $_.SideIndicator -eq '<=' } |`
						ForEach-Object -Process { $null = Close-XmlEntry -XmlWriter $XmlWriter }
							
					$objRegHeaderCompareList |`
						Where-Object -FilterScript { $_.SideIndicator -eq '=>' } |`
						ForEach-Object -Process { $null = New-XmlCollection -Value $_ -objWriter $XmlWriter }
      
					# SETZE HIVE & KEY & ALTEN HEADER
					[String[]]$straHeaderBefore = $straHeader
					[String]$strHive = $straHeader[0]
					[String]$strKey = $straHeader[1..($straHeader.Count - 1)] -join '\'
                
					break
				}
                
				{ ($_ -like '"') -or ($_ -like '@') } { # Information
					# Debug
					#Write-Debug -Message "[DEBUG] DATA:$FileItemContentLine"
					
					If ($_ -like '@') {
						# Standardeintrag @
						$RegItemDefaultEntry = $True
						[string]$RegItemName = '' # Standardeintrag @
						[string]$NextKeyIdent = $CurrentLineContent.Substring(2, 1) # Reg-Typen Erkennung
					}
					else {
						# Dateneintrag "
						[string]$RegItemName = $CurrentLineContent.Substring(0, $CurrentLineContent.IndexOf('"=')).Trim('"') # Dateneintrag
						[string]$NextKeyIdent = $CurrentLineContent.Substring($CurrentLineContent.IndexOf('"=') + 2, 1) # Reg-Typen Erkennung
					}
					
					# Reg-Typen Erkennung
					If ($NextKeyIdent -like '"') {
						# STRING
						[string]$RegItemDataType = 'string'
					}
					else {
						# DWORD oder HEX
						
						try {
							If ($_ -like '@') {
								[int]$StringStartPos = 1 # Standardeintrag @
							}
							else {
								[int]$StringStartPos = $CurrentLineContent.IndexOf('"=') + 1 # Dateneintrag
							}
						
							[int]$StringEndePos = $CurrentLineContent.IndexOf(':')
							[int]$StringLength = $StringEndePos - $StringStartPos
							[string]$RegItemDataType = $CurrentLineContent.Substring($StringStartPos, $StringLength)
						}
						catch {
							Write-Warning -Message ('[*] RegDaten Zeile:{0} können nicht verarbeitet werden. RegTypen-Erkennung ist fehlgeschlagen!' -f $CurrentLineNumber)
							Continue
						}
					}
                    
					# Reg-Daten Verarbeitung
					switch -Wildcard ($RegItemDataType) {
						'string' { # REG_SZ
							[string]$RegItemType = 'REG_SZ'
							[int]$StringStartPos = $CurrentLineContent.IndexOf('="') + 2
							[string]$RegItemData = $CurrentLineContent.Substring($StringStartPos).Trim('"')
							break
						}

						'=dword' { # REG_DWORD
							[string]$RegItemType = 'REG_DWORD'
							[int]$StringStartPos = $CurrentLineContent.IndexOf('=dword:') + 7
							[string]$RegItemData = $CurrentLineContent.Substring($StringStartPos)
							break
						}

						'=hex*' { # REG_EXPAND_SZ, REG_MULTI_SZ, REG_QWORD, REG_BINARY
							#
							# Einlesen und Verarbeiten
							#
                        
							$HexData = @()
							[int]$StringStartPos = $CurrentLineContent.IndexOf(("$RegItemDataType" + ':')) + ($RegItemDataType.Length + 1)
							[string]$tempHexData = $CurrentLineContent.Substring($StringStartPos)
							$HexData += $tempHexData.TrimEnd('\')

							while (($StreamReader.EndOfStream -eq $false) -and ($tempHexData.EndsWith('\') -eq $True)) {
								# Mehrzeilig
								[string]$tempFileItemContentLine = $StreamReader.ReadLine()
								$CurrentLineNumber++ # Current Line
								
								[string]$tempHexData = $tempFileItemContentLine
								$HexData += ($tempFileItemContentLine.Trim(' ').Trim('\'))
							}
                            
							[string]$HexBinaryString = ([string[]]($HexData) -join '')

							#
							# Bearbeiten der einzelenen Hex-Typen
							#

							Switch ($RegItemDataType) {
								'=hex(2)' {
									[string]$RegItemType = 'REG_EXPAND_SZ'
									[string[]]$HexBinaryData = (Convert-HexToString -HexData $HexBinaryString).Split("$([Char]00)")
									$RegItemData = $HexBinaryData -join ' '

									[string[]]$HexBinaryData = $null
									break
								}
                                
								'=hex(7)' {
									[string]$RegItemType = 'REG_MULTI_SZ'
									[string[]]$HexBinaryData = (Convert-HexToString -HexData $HexBinaryString).Split("$([Char]00)")
                                    
									$RegItemData = $HexBinaryData -join ' '
									break
								}
                                
								'=hex(b)' {
									[string]$RegItemType = 'REG_QWORD'
									[string]$Value = ''
                                    
									# Invertiere die Daten
									foreach ($Item in ($HexBinaryString -split ',')) {
										$Value = "$Item$Value"
									}
                                    
									[string]$RegItemData = $Value
									break
								}
                                
								'=hex' {
									[string]$RegItemType = 'REG_BINARY'
									[string]$RegItemData = $HexBinaryString.Trim(',')
                                    
									break
								}
                                
								'=hex(0)' {
									[string]$RegItemType = 'REG_NONE'
									break
								}
                                
								default {
									Write-Warning -Message ('[*] Unbekannter HEX-Typ! RegTyp:{0};RegZeile:{1}' -f $RegItemDataType, $CurrentLineNumber)
									Continue
								}
							}

							break
						}

						default {
							Write-Warning -Message ('[*] Unbekannter Daten-Typ! RegTyp:{0}; RegZeile:{1}' -f $RegItemDataType, $CurrentLineNumber)
							Continue
						}
					}
                    
					# DEBUG INFORMATION
					#Write-Debug -Message "[DEBUG] Name: $RegItemName"
					#Write-Debug -Message "[DEBUG] Typ: $RegItemType"
					#Write-Debug -Message "[DEBUG] Wert: $RegItemData"

					$null = New-XmlEntry -Eintrag $RegItemName -Art $RegItemType -Wert $RegItemData -Hive $strHive -Key $strKey -MainXmlWriter $XmlWriter -ActionType $ActionType -ExtendedValue $HexBinaryData -SetDefaultEntry $RegItemDefaultEntry

					break
				}
                
				'' {
					# Leeres Zeichen, Zeile ignorieren
					#Write-Debug -Message ('[DEBUG] Ignore empty line. RegZeile:{0}' -f $i)
					break
				}
				
				';' {
					# Kommentar, Zeile ignorieren
					#Write-Debug -Message ('[DEBUG] Ignore empty line. RegZeile:{0}' -f $i)
					break
				}
				
				default {
					# Nicht definiertes Zeichen
					Write-Warning -Message ('[*] Nicht erwartetes Zeichen! Die Zeile wird ignoriert. RegTyp:{0}; RegZeile:{1}; ' -f ($CurrentLineContent[0]), $CurrentLineNumber)
					
					Continue
				}
			}
		}


		#
		# Finishing :) / Endverarbeitung
		#

		try {
			Write-Progress -Activity 'Registry To XML Converter' -CurrentOperation 'XML-Datei wird geschrieben...' -Completed
			# Letzten Eintrag schließen
			$null = Close-XmlEntry -XmlWriter $XmlWriter
    
			# ABSCHLUSS
			$XmlWriter.Close()
			$StreamReader.Close()

			Write-Output -InputObject ('[*] File successfully saved under {0}' -f $FileItemOutputPath)
			Write-Output -InputObject '[ END ]'
		}
		catch {
			Write-Warning -Message ('[*] {0}' -f $_)
    
			# Letzten Eintrag schließen
			$null = Close-XmlEntry -XmlWriter $XmlWriter
			$StreamReader.Close()
		}
  
		Write-Progress -Activity 'Registry To XML Converter' -Completed
	}
}

end {}

# ENDE #