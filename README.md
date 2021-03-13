# RegToXML Converter v1.3 (Update 10.2019)

Über die Group Policy Preferences (GPP) kann man unter anderem Registry-Einträge per Gruppenrichtlinie an Client-Rechner verteilen. Was bei einem einzelnen Eintrag manuell noch machbar ist, wird zu einer aufwändigen und fehlerträchtigen Aufgabe, wenn es um mehrere Registry-Werte geht, die man parallel verteilen muss.

Hierfür bieten die GPP einen Import-Mechanismus über XML-Dateien. Damit ist jedoch noch nicht viel gewonnen, denn eine XML-Datei ist noch viel weniger einfach “per Hand” zu generieren. Muss man aber auch gar nicht: Es ist mit einem PowerShell-Skript möglich, einen Registry-Export in eine XML-Datei umzuwandeln. Nun muss man also nur noch auf einem Muster-Client die nötigen Registry-Einstellungen vornehmen, um diese dann in eine .reg-Datei zu exportieren. Das Skript erledigt den Rest.

Das Skript wandelt/konvertiert Registry-Dateien (sog. *.reg-Files) in XML-Dateien für die Managementkonsole. (GroupPolicyPreferences Registry). 

Es bedient alle gängigen Registry-Formate: REG_SZ, REG_EXPAND_SZ, REG_MULTI_SZ, REG_BINARY, REG_DWORD, REG_QWORD

## Voraussetzungen / Prerequisites
Powershell Version 3

## Parameter v1.3
- FilePath (erforderlich) – Hier geben Sie den Pfad zur Reg-Datei an
- ActionType (nicht erforderlich) – Der Wert kann ( Create, Delete, Update, Replace ) betragen. Der „Default Parameter“ ist Update

## Beispiele / Examples v1.3
- Convert-RegToGppXml.ps1 -FilePath C:\MyTestRegFile.reg
- Convert-RegToGppXml.ps1 -FilePath "C:\Sub Folder\MyTestRegFile.reg"
- Convert-RegToGppXml.ps1 -FilePath C:\MyTestRegFile.reg -ActionType Create
- Convert-RegToGppXml.ps1 -FilePath "C:\Sub Folder\MyTestRegFile.reg" -ActionType Replace
