<?php

define("VDSN", "DRIVER={SQL Server};SERVER=152.18.68.222;DATABASE=NEMAC_Master");
define("USER", "sde");
define("PW", "foxinabox");

class clsNEMACMapViewerPHP {
	public function __construct() {
	 //this function is needed, is the constructor of class!!
	}

    public function validateUserLogin($userName,$userPassword,$portalID) {
		VDSN;
		$conn = odbc_connect(VDSN, USER, PW)
			or die('ODBC Error:: '.odbc_error().' :: '.odbc_errormsg().' :: '.VDSN);
	
		//test for user name
		if($conn){
			$sql="SELECT '1' outputFlag FROM Portal_User WHERE User_Name = '".$userName."' AND Portal_ID = '".$portalID."'";
			$rs=odbc_exec($conn, $sql);
			$row=odbc_fetch_row($rs);
			if ($row == null) {
				odbc_close($conn);
				return "You have entered an invalid user name; please try again." ; 
			}
		}
	
		//test for password
		if($conn){
			$sql="SELECT '1' FROM Users WHERE User_Name = '".$userName."' AND User_Password = '".$userPassword."'";
			$rs=odbc_exec($conn, $sql);
			$row=odbc_fetch_row($rs);
			if ($row == null) {
				odbc_close($conn);
				return "You have entered an invalid password for your account; please try again." ; 
			}
		}
	
		//save login info
		if($conn){
			$sql="INSERT INTO Portal_User_Login (Portal_ID, User_Name, Login_Date) VALUES ('".$portalID."', '".$userName."', GetDate())";
			$rs=odbc_exec($conn, $sql);
		}
		return "OK";
    }
    
    public function guestLogin($portalID) {
		VDSN;
		$conn = odbc_connect(VDSN, USER, PW)
			or die('ODBC Error:: '.odbc_error().' :: '.odbc_errormsg().' :: '.VDSN);
	
		//save login info
		if($conn){
			$sql="INSERT INTO Portal_User_Login (Portal_ID, User_Name, Login_Date) VALUES ('".$portalID."', 'guest', GetDate())";
			$rs=odbc_exec($conn, $sql);
		}
		return "OK";
    }
    
    public function changeUserPassword($userName,$userOldPassword,$userNewPassword,$portalID) {
    	VDSN;
		$conn = odbc_connect(VDSN, USER, PW)
			or die('ODBC Error:: '.odbc_error().' :: '.odbc_errormsg().' :: '.VDSN);
		
    	//test for user name
		if($conn){
			$sql="SELECT '1' outputFlag FROM Portal_User WHERE User_Name = '".$userName."' AND Portal_ID = '".$portalID."'";
			$rs=odbc_exec($conn, $sql);
			$row=odbc_fetch_row($rs);
			if ($row == null) {
				odbc_close($conn);
				return "You have entered an invalid user name; please try again." ; 
			}
		}
	
		//test for password
		if($conn){
			$sql="SELECT '1' FROM Users WHERE User_Name = '".$userName."' AND User_Password = '".$userOldPassword."'";
			$rs=odbc_exec($conn, $sql);
			$row=odbc_fetch_row($rs);
			if ($row == null) {
				odbc_close($conn);
				return "You have entered an invalid password for your account; please try again." ; 
			}
		}
		
		//save new password
		if($conn){
			$sql="UPDATE Users SET User_Password = '".$userNewPassword."' WHERE User_Name = '".$userName."'";
			$rs=odbc_exec($conn, $sql);
		}
		return "OK";
    }
}

?>
