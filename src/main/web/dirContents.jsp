<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<%@ page import="net.sourceforge.hunterj.fsutil.FolderBrowserServlet.FBConst, java.util.List,java.nio.file.Path" %>
<%
/*
 * This work is licensed under the Common Public Attribution License 
 * Version 1.0 (CPAL-1.0). To view a copy of this license, visit 
 * http://opensource.org/licenses/CPAL-1.0.
 * 
 */
String context = request.getContextPath();
List<Path> pathList = (List<Path>) request.getAttribute(FBConst.DIR_CONTENTS.value);
%>
<!DOCTYPE html>
<html>
<head>
<title>Directory Contents</title>
<link rel="stylesheet" href="<%=context%>/dijit/themes/claro/claro.css">
<style>
body,html{
  padding: 4px;
}
ul{
  list-style-type:none;
  padding: 0;
  margin: 0;
}
ul li{
  background-image: url(img/folder01.gif);
  background-repeat: no-repeat;
  background-position: 0 0; 
  padding-left: 15px;
  cursor: default;
}
.path_entry{
  display: block;
  padding: 3px;
  padding-left: 4px;
  font: normal 11px arial;
}
.path_entry:hover{
  background-color: #ddf;
  background-image: url("dijit/themes/claro/images/standardGradient.png");
  background-repeat: repeat-x;
  background-image: -moz-linear-gradient(rgba(255, 255, 255, 0.7) 0%, rgba(255, 255, 255, 0) 100%);
  background-image: -webkit-linear-gradient(rgba(255, 255, 255, 0.7) 0%, rgba(255, 255, 255, 0) 100%);
  background-image: -o-linear-gradient(rgba(255, 255, 255, 0.7) 0%, rgba(255, 255, 255, 0) 100%);
  background-image: linear-gradient(rgba(255, 255, 255, 0.7) 0%, rgba(255, 255, 255, 0) 100%);
  _background-image: none;
  border: solid 1px #759dc0;
  padding: 2px;
  padding-left: 3px;
}
</style>
<script type="text/javascript" src="<%=context%>/jquery/jquery-1.6.2.min.js"></script>
<script type="text/javascript">

var pathViewer = (function() {
    return {
        color : {
            bgNormal: '#fff',
            bgOver: '#ddf',
            bgSelected: '#36f',
            txtSelected: '#fff',
            txtNormal: '#000'
        },
        selectPathEntry: function(entry, path){
            $('.path_entry').css('background-color', pathViewer.color.bgNormal)
                .css('color', pathViewer.color.txtNormal)
                .hover(
                    function(){/*mouseover*/ 
                        $(this).css('background-color', pathViewer.color.bgOver)
                    }, 
                    function(){/*mouseout*/
                        $(this).css('background-color', pathViewer.color.bgNormal);
                    } 
                );
            $(entry).css('background-color', pathViewer.color.bgSelected)
                .css('color', pathViewer.color.txtSelected)
                .css('background-image', 'none')
                .hover(
                    function(){
                        $(this).css('background-color', pathViewer.color.bgSelected);
                    },
                    function(){
                        $(this).css('background-color', pathViewer.color.bgSelected);
                    }
                );
            pathViewer.selectedPath = path;
        }
    }
})();
</script>
</head>
<body>
<ul>
<%
if(pathList != null) {
for(Path path : pathList){
    String entryPath = path.toString();
    String entryName = (path.getFileName() != null) ? path.getFileName().toString() : entryPath;
    String escapedEntryPath = entryPath.replace("\\","\\\\");
    String entryUrl = new StringBuilder().append(context).append("/files?path=").append(escapedEntryPath).toString();
%>
<li><span class="path_entry" onclick="pathViewer.selectPathEntry(this,'<%=escapedEntryPath%>')" ondblclick="window.location.href='<%=entryUrl%>'"><%=entryName%></span></li>  
<%}
}
%>
</ul>
</body>
</html>
