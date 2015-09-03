<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<%@ page isErrorPage="true" %>
<%
/*
 * This work is licensed under the Common Public Attribution License 
 * Version 1.0 (CPAL-1.0). To view a copy of this license, visit 
 * http://opensource.org/licenses/CPAL-1.0.
 * 
 */
%>
<!DOCTYPE html>
<html>
<head>
<title>ERROR!</title>
</head>
<body>
<script type="text/javascript">
(function(){
var thisError = '<%=exception.getClass().getName()%>';
var message = '<%=exception%>';
if(thisError.indexOf('NoSuchFileException') != -1 || error.indexOf('FileNotFoundException') != -1){
	message = thisError + ' was thrown; Probably because of an invalid javadoc home.';
	dochomeObj = top.dijit.byId('dochome');
	top.Viewer.removeDochomeOption(top.Viewer.currentDochome);
}
if (! top.Viewer.error) {
    top.Viewer.error = thisError;
    top.$('#error_message').html('<p>'+message+'</p>');
    top.error_alert.show();
}
})();
</script>
</body>
</html>