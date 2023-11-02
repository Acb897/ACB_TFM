# ACB_TFM
This repo contains an algorithm that automatically explores triplestore endpoints (public and private with the right permissions), creating an index of their contents in a privacy-preserving way, composed of SHACL shapes. The purpose of this index is to be used to match SPARQL queries with the triplestores that contain the data that can answer them, which is done by creating mock data that matches the clauses of the query, and using the validation features of SHACL to match said data with the shapes index of all endpoints. 

## Instructions
After cloning the repository, go to the [Demo](/Demo) directory. Inside, you will find [main.rb](/Demo/main.rb), the script you have to configure. It has three sections, explained below:
#### First section: Indexing
Here, you can change the endpoints to be automatically explored and indexed, by adding or removing them from the "endpoints" array.
#### Second section: Querying
Here you can change the query you are interested in finding endpoints that can answer it. Simply change the query to any SPARQL query, but **DO NOT** remove the first line (<<END) and the last line (END) of the query. 
#### Third section: Source Selection
There is not much to customise here.

## Folder structure
This repo contains the modules for the matching algorithm, which will be explained below:
* [Demo](/Demo): contains the main components of the algorithm: exploration, indexing and query matching.
* [DemoDatabaseBuilder](/DemoDatabaseBuilder): contains a script that generates private databases (without a public SPARQL endpoint) to demonstrate the capabilities of the exploration algorithm with private triplestores.
* [DoorKnocker](/DoorKnocker): Code that allows data stewards to approve requests for queries to be resolved using their data.
* [MiscellaneousScripts](/MiscellaneousScripts): contains [sparql_parser.rb](/MiscellaneousScripts/sparql_parser.rb) the script that parse the SPARQL query to be matched against the index, and [transform.rb](/MiscellaneousScripts/transform.rb), the script that transforms the SPARQL query into mock RDF data.
* [SPARQL_Client](/SPARQL_Client): contains the client for the SPARQL gem.
* [doc](/doc): contains the documentation
