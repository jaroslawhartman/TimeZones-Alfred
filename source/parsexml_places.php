<?php

$api_response = $argv[1];

$xml = new SimpleXMLElement($api_response);

echo $xml->status;
echo "\n";

foreach( $xml->{'prediction'} as $prediction ) {
    echo $prediction->description. "\n";
}

?>