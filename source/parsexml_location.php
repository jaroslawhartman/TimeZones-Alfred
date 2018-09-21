<?php

$api_response = $argv[1];

$parsed = new SimpleXMLElement($api_response);

echo $parsed->status;
echo "\t";
echo $parsed->result->address_component->long_name;
echo "\t";
echo $parsed->result->geometry->location->lat;
echo "\t";
echo $parsed->result->geometry->location->lng;
echo "\t";
foreach ($parsed->result->address_component as $location) {
	if ($location->type == "country")
	  echo $location->long_name;
}



?>