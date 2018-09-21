<?php

$api_response = $argv[1];

$parsed = new SimpleXMLElement($api_response);

echo $parsed->status;
echo "\t";
echo $parsed->raw_offset;
echo "\t";
echo $parsed->dst_offset;
echo "\t";
echo $parsed->time_zone_id;
echo "\t";
echo $parsed->time_zone_name;


?>