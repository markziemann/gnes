<?php

function test_input($data) {
  $data = trim($data);
  $data = str_replace(' ', '_', $data);
  $data = preg_replace('/[^A-Za-z0-9\_.\']/', '', $data);
  $data = stripslashes($data);
  $data = htmlspecialchars($data);
  return $data;
}

$uploadFail = "";
$file_result = "";
$mail_result = "";
$filename = "";
$file = "";
$email = "";
$emailErr = "";
$name = "";
$ext = "";
$mime = "";
$type = "";
$output = "";
$report_path = "";

$filename = $_FILES["file"]["name"];
$mime = mime_content_type ( $filename );
$type =$_FILES["file"]["type"];
$email = $_POST["email"];

if ($_FILES["file"]["error"] > 0) {
	echo "No file uploaded or invalid file <br>";
	echo "Error code: " . $_FILES["file"]["error"] . "<br>";
} else {

 // Check file size
if ($_FILES["file"]["size"] > 50000000) {
    echo "Sorry, your file is too large. The upper limit is 50MB. <br>";
    $uploadFail = 1;
}

// Allow certain file formats
$allowed = array('xls','xlsx', 'XLS', 'XLSX');
$name = $_FILES["file"]["name"];
$ext = end((explode(".", $name)));
if( ! in_array($ext,$allowed) ) {
    echo "Sorry, only xls & xlsx files are allowed. <br>";
    $uploadFail = 1;
}

if ($uploadFail == 1) {
    echo "Sorry, your file was not uploaded. <br>";
// if everything is ok, try to upload file
} else {

	$file_result .=
	"Upload: " . $_FILES["file"]["name"] . "<br>" .
	"Type: " . $_FILES["file"]["type"] . "<br>" .
	"Size: " . ($_FILES["file"]["size"] / 1024) . " Kb<br>" .
	"Temp file: " . $_FILES["file"]["tmp_name"] . "<br>" ;

        $name = str_replace(' ', '_', $name);
	$name = test_input($name);

	move_uploaded_file($_FILES["file"]["tmp_name"],
	"/var/www/upload/" . $name  ) ;

	$file_result .= "File upload successful!";

	$file_path = "";
	$file_path .=  "/var/www/upload/" . $name ;

	if ( $email !== "" ) {
	$mail_result .= $_POST["email"];

	if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
	$emailErr = "Invalid email format";
	echo "$emailErr";
	} else {

        $old_path = getcwd();
        chdir('/var/www/code');
        $output = shell_exec("./scan_uploaded_files.sh $file_path $mail_result");
        $report_path .= $file_path . "rep" ;
#        print_r($report_path);
	chdir($old_path);

	}} else {

        $mail_result .= "No email address provided";
        $old_path = getcwd();
        chdir('/var/www/code');
        $output = shell_exec("./scan_uploaded_files.sh $file_path");
        $report_path .= $file_path . "rep" ;
#        print_r($report_path);
        chdir($old_path);
	}

}
}


echo $output;

?>



<html>
<head>
<style>
body { margin:0; padding:0; background:#CCC; font-family:Arial; }

.fileuploadholder {
	width:400px;
	height:auto;
	margin: 20px auto 0px auto;
	background-color:#FFF;
	border:1px solid #CCC;
	padding:6px;
}
  div.section_header {
    padding: 3px 6px 3px 6px;

    background-color: #8E9CB2;

    color: #FFFFFF;
    font-weight: bold;
    font-size: 200%;
    text-align: center;
  }

</style>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title> Gene Name Error Scanner</title>
</head>

<body>

<div class="section_header section_header_red">
<a href="gnes.html"> Gene Name Error Scanner </a>
</div>

<div class="fileuploadholder">
	<form enctype="multipart/form-data" action="gnes.php" method="post">
	Excel autocorrect errors are common in supplementary files of genomics papers*. Upload your files here and it will be scanned for such errors. Optionally, enter your email address and receive a report in PDF format.
	<br><br>
	Select file to upload: <br>
	<input name="file" type="file" id="file" size="80" <br><br><br>
	[Optional] Email address<br>
        <input type="text" name="email" id="email" size="40" value="<?php echo $email ;?>" >  <br><br>
        <input type="submit" id="u_button" value="Upload & scan"> <br><br>
	*<a href="http://genomebiology.biomedcentral.com/articles/10.1186/s13059-016-1044-7"> Ziemann M, Eren Y, El-Osta A. Genome Biol. 2016 Aug 23;17(1):177.</a>
	</form>
</div>
</body>
</html>

