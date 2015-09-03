
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.io.File" %>
<%
/*
 * This work is licensed under the Common Public Attribution License 
 * Version 1.0 (CPAL-1.0). To view a copy of this license, visit 
 * http://opensource.org/licenses/CPAL-1.0.
 * 
 */
final String context = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
<!--meta http-equiv="Content-Type" content="text/html; charset=UTF-8"-->
<title>Folder Browser</title>
<style type="text/css">
*{margin:0;padding:0}
html, body {
    width: 100%;
    height: 100%;
    border: none;
}
</style>
<script type="text/javascript" src="<%=context%>/jquery/jquery-1.6.2.min.js"></script>
<script type="text/javascript">
//?
function setJavadocHome(path){
    window.parent.document.forms[0].elements.dochome.value = path;
    return false;
}
</script>
</head>
<body class="claro">
<div id="bread_crumbs" style="font:bold 11px tahoma"></div>
<iframe id="viewPane" name="viewPane" src="<%=context%>/files?path=root" style="width:99%;height:75%;margin:0;padding:0;border:1px solid #999" marginwidth="0" marginheight="0" frameborder="0"></iframe>
 <script type="text/javascript">
(function(){
    var separator = '<%=File.separator.replace("\\", "\\\\")%>';
    $('#viewPane').bind('load', function(){
        var content = "<a href='<%=context%>/files'>File System:</a>";
        var path = this.contentWindow.location.href.split("path=")[1];
        if(path && path != "root") {
            var parts = path.split(separator);
            for(var i=0; i<parts.length; i++){
                if(parts[i].length > 0){
                    content += '<span>&nbsp;&rang;&nbsp;</span>' 
                    + '<a target="viewPane" href="<%=context%>/files?path='; 
                    for(var j=0; j<i+1; j++) {
                        content += parts[j] + separator;
                    }
                    content += '">' + parts[i] + '</a>';
                }
            }
        }
        $('#bread_crumbs').html(content);
    }); 
})()
</script>
</body>
</html>