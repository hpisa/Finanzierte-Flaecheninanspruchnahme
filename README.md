# Finanzierte-Flaecheninanspruchnahme
Aufbereitung des Grundstücksverzeichnisses des BEV, Berechnung des Flächenindikators aller Grundstücke ("EMZ_plus") zum Vergleich der Auswirkung von Bodenversiegelung unterschiedlicher Bauprojekte

Link zum Abschlussbericht des Projekts (weiterführende Informationen): https://startclim.at/fileadmin/user_upload/StartClim2023/StCl23.G._Final.pdf

----------

Datenquelle:

https://data.bev.gv.at/geonetwork/srv/ger/catalog.search#/search?resultType=details&sortBy=relevance&fast=index&_content_type=json&from=1&to=100&any=kataster%20grundst%C3%BCcksverzeichnis%20csv

Bzw.

Stichtag 01.04.2023: https://data.bev.gv.at/geonetwork/srv/ger/catalog.search#/metadata/5a56bef7-7b60-4822-9da7-1d118f312a4d

Stichtag 01.04.2022: https://data.bev.gv.at/geonetwork/srv/ger/catalog.search#/metadata/c1151b87-389f-4459-a961-fdd3c2d41019

Stichtag 01.04.2021: https://data.bev.gv.at/geonetwork/srv/ger/catalog.search#/metadata/bbe25b67-e0ae-41cc-a3af-99f350af1c9b

----------

Code ist nicht jahresspezifisch

=> Entsprechende Datenquelle entpackt im Ordner ./data/bundeslaender/ abspeichern

- Alle Bundesländer in jeweils eigenen Subordner
- pro Code-Ausführung nur einen Stichtag als Input in /bundeslaender
- .gitkeep vor Ausführung des Codes aus dem Ordner /bundeslaender löschen
