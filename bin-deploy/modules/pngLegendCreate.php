<?php
if (isset($GLOBALS["HTTP_RAW_POST_DATA"])) {
$data = $GLOBALS["HTTP_RAW_POST_DATA"];
$fileName = $_GET["name"];
//$file = fopen($fileName, "wb");
//fwrite($file, $data);
//fclose($file);

//header( 'Location: '.$fileName );
header('Content-Type: image/jpeg');
header("Content-Disposition: attachment; filename=".$fileName);
echo $data;

}
?>
