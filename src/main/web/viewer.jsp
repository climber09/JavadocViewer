<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
<%@ page import="net.sourceforge.hunterj.javadocViewer.JavadocViewerServlet.JVConst" %>
<%
/*
 * This work is licensed under the Common Public Attribution License 
 * Version 1.0 (CPAL-1.0). To view a copy of this license, visit 
 * http://opensource.org/licenses/CPAL-1.0.
 * 
 */
 
final String context = request.getContextPath();
final String searchBoxTxt = "Class or Package";
String currentDochome = (String)request.getAttribute(JVConst.DOCHOME_ATTR.value);
if(currentDochome == null){
    currentDochome = "";
}
String docHomeOpts = (String)request.getAttribute(JVConst.DOCHOME_OPTS.value);
// if(docHomeOpts == null || docHomeOpts.length() == 0){
//     docHomeOpts = "[]";
// }
Throwable t = (Throwable)request.getAttribute(JVConst.DOCHOME_ERROR.value);
String errorType = "";
String errorMsg = "";
if(t != null) {
    errorType = t.getClass().getName();
    errorMsg = t.getMessage().replace("\\", "\\\\");
}
String viewUrl = response.encodeUrl("/view");
%>
<!DOCTYPE html>
<html>
<head>
<title>Javadoc Viewer</title>
<link rel="stylesheet" href="<%=context%>/dijit/themes/claro/claro.css">
<style type="text/css">
*{margin:0;padding:0}
html, body {
    width: 100%;
    height: 100%;
}
form{
  display: inline;
}
.claro .dijitMenuItem, .javadoc_box, .search_pane, .text_box{
  font: normal 11px tahoma;  
}
.claro .dijitMenuItem:hover{
  background-color: #ddf;
}
.text_box{
  width: 275px;
  color: #e6e6e6;
  background-color: #666;
}
.nav_pane{
  padding: 0; margin: 0; overflow: hidden;
}
span.dijitTabCloseButton:hover {
  background-position: -14px;
}
span.dijitTabCloseButton:active {
  background-position: -28px;
}
.claro .dijitDialogTitleBar{
  background-color: #e30
}
.claro .dijitDialogTitle{
  color: #fff;
  font: bold 11px monospace
}
/*
#fld_browser_box .dijitDialogTitleBar{
    background-color: #99f;
}
*/
#fld_browser_box .dijitDialogPaneContent{
/*    width: 325px !important;*/
    height: 250px !important;
    border: none;
}
button, .button{
  font: normal 11px tahoma;
}
</style>
<script type="text/javascript">
var javadoc_home = window.location.pathname + '/javadoc_home';
//var javadoc_const = "package-frame.html";
dojoConfig = {parseOnLoad: true}
</script>
<script type="text/javascript" src='<%=context%>/util/util.js'></script>
<script type="text/javascript" src='<%=context%>/dojo/dojo.js'></script>
<script type="text/javascript" src="<%=context%>/jquery/jquery-1.6.2.min.js"></script>
<script type="text/javascript">
if (self != top.window){
    top.window = self;
}
require([
    "dojo/ready",
    "dojo/parser",
    "dojo/store/Memory",
    "dijit/layout/AccordionContainer",
    "dijit/layout/AccordionPane",
    "dijit/layout/BorderContainer",
    "dijit/layout/ContentPane",
    "dijit/layout/TabContainer",
    "dijit/Dialog",
    "dijit/form/Button",
    "dijit/form/Form",
    "dijit/form/ComboBox",
    "dijit/form/TextBox"
]);

var Viewer = (function(){return{ 
    Pane : {
        Properties : function(iframe, type){
            this.href    = iframe.contentWindow.location.href;
            this.label   = iframe.contentWindow.document.title.replace(/\(.*\)/, '');
            this.tabId   =  type + '_' + $.trim(this.label);
            this.content = '<iframe src="'+this.href+'" style="width:100%;height:100%;margin:0;padding:0" marginwidth="0" marginheight="0"></iframe>';
        },
        doCloseButton : function(paneId){
            return '<span style="float:right" class="dijitInline dijitTabCloseButton dijitTabCloseIcon" data-dojo-attach-point="closeNode" role="presentation" title="Close" onclick="Viewer.closePkgPane(\''+paneId+'\')"><span data-dojo-attach-point="closeText" class="dijitTabCloseText">[x]</span></span>';
        },
        doTitlePane : function(title, paneId){
            return title+Viewer.Pane.doCloseButton(paneId);
        }
    },

    handleSelectedTabLoadEvent : function(){
        var iframe = this;    
        var tab = dijit.byNode(iframe.parentNode);
        with(Viewer.classContainer){
            var type = id.split('_')[0];
            var props = new Viewer.Pane.Properties(iframe, type);
            var index = getIndexOfChild(tab);
            removeChild(tab);
            tab.destroy();
            try{
                var newTab =  new dijit.layout.ContentPane({ 
                    title : props.label,
                    content : props.content,
                    closable : true
                });
                addChild(newTab, index);
                selectChild(newTab);
                newIframe = newTab.domNode.childNodes[0];
                $(newIframe).bind('load', Viewer.setSelectedTabLoadEvent);
            }
            catch(e){
                //DEBUG
                //alert(e.message)
            }
        }
    },
    
    setSelectedTabLoadEvent : function(){
        var iFrame = this;
        var targetDoc = iFrame.contentDocument || iFrame.contentWindow.document;
        $(targetDoc).ready(function(){
            $(iFrame).bind('load', Viewer.handleSelectedTabLoadEvent);
        });
    },
    
    handleNewContentPane : function(iframeSrc, container){
        var type = container.id.split('_')[0];
        var props = new Viewer.Pane.Properties(iframeSrc, type);
        var contentPane = null;
        try{
            // attempts to create duplicate tabs throw an exception
            contentPane = new dijit.layout.ContentPane({ 
                id : props.tabId,
                title : props.label,
                content : props.content,
                closable : true,
                'style' : 'margin:0;padding:0;overflow:hidden'
            });
//            contentPane.set('style', 'margin:0;padding:0;overflow:hidden');
            container.addChild(contentPane);
        }
        catch(e){ //prevents duplicate content panes.
            //DEBUG ONLY
            //alert(e.message);
        }
        // using tab id matches existing tab or new tab
        container.selectChild(props.tabId);
        return contentPane;
    },

    /**
     * Looks for a class or package page, in that order, matching 
     * the user input, e.g., 'java.io' or 'java.io.File'
     */
    ezOpen : function(fqName, isPkg){
        if (fqName && fqName != '<%=searchBoxTxt%>') {
            fqName = fqName.replace(/^\W+|\W+$/g , '');
            var pageUrl = javadoc_home+'/'+fqName.replace(/\./g, '/');
            pageUrl += (isPkg)? '/package-summary.html': '.html';
            $.ajax({
                url: pageUrl,
                type: "head"
            }).done(function(data, status, jqXhr){
                $('#classFrame').attr('src', pageUrl);
            }).fail(function(jqXhr, textStatus, error) {
                if(isPkg){
                    // already, tried to find a matching package
                    $('#error_message').html('<p>A resource for "' + fqName + '" was not found</p>');
                    error_alert.show();
                    return;
                }
                // otherwise, look for a matching package
                Viewer.ezOpen(fqName, true);
            });
        }
        return false;
    },

    closePkgPane : function(paneId){
        var pane = dijit.byId(paneId);
        with(Viewer.pkgContainer){
            var paneIndex = getIndexOfChild(pane);
            var paneIsSelected = (selectedChildWidget == pane);
            removeChild(pane);
            pane.destroy();
            var panes = getChildren();
            if(paneIsSelected){
                 selectChild(panes[paneIndex -1]);
            }
        }
    },

    openFolderBrowser : function(){
        $('#fld_browser').attr('src', '<%=context%>/files');
        fld_browser_box.show();
    },
     
    init : function(){        
        this.topContainer = new dijit.layout.BorderContainer({
            'style': 'width:100%;height:100%;padding:0;margin:0'
        });
        this.leftFrame = new dijit.layout.BorderContainer({
            region: 'leading', 
            splitter: true, 
            'style': 'width:25%'
        });
        this.pkgContainer = new dijit.layout.AccordionContainer({
            region: 'center',
            'style': 'width:100%;font:10px tahoma'
        });
        this.classContainer = new dijit.layout.TabContainer({
            id: 'class_container',
            region: 'center',
            'style': 'font-size:10px;padding:0;margin:0'
        });
        this.topPaneContent = new dijit.layout.ContentPane({
            region: 'top',
            'style': 'padding:0;margin:0;padding-left:10px;padding-right:10px;background-color:#eee',
            content : ''
        });
        this.topPaneContent.addChild(new dijit.form.Form(null, $('#javadoc_home_form')[0]));
        this.topPaneContent.addChild(new dijit.form.Form(null, $('#ezopen_form')[0]));
        this.topContainer.addChild(this.topPaneContent);
        this.leftFrame.addChild(new dijit.layout.ContentPane({
            region: 'top', 
            splitter: true,
            'style': 'height:30%;margin:0;padding:0;overflow:hidden',
            content: '<iframe src="" name="packageListFrame" id="packageListFrame" style="width:100%;height:100%;padding:0;margin:0"></iframe>'
        }));
        this.pkgContainer.addChild(new dijit.layout.AccordionPane({
            id: 'pkg_All Classes',
            title: 'All Classes',
            'style': 'padding:0;margin:0;overflow:hidden',
            content: '<iframe src="" name="packageFrame_0" id="packageFrame_0" style="width:100%;height:100%;margin:0;padding:0" marginwidth="0" marginheight="0"></iframe>'
        }));
        this.leftFrame.addChild(this.pkgContainer);
        this.topContainer.addChild(this.leftFrame);
        this.classContainer.addChild(new dijit.layout.ContentPane({
            id: 'classTab_0',
            closable: true,
            title: 'Overview', 
            'style': 'padding:0;margin:0;overflow:hidden',
            content: '<iframe src="" name="classFrame_0" id="classFrame_0" style="width:100%;height:100%;margin:0;padding:0" marginwidth="0" marginheight="0"></iframe>'
        }));
        this.topContainer.addChild(this.classContainer);
        document.body.appendChild(this.topContainer.domNode);
        this.topContainer.startup();    
    },
    
    setJavadocHome : function(){
    	var docHome = //*$('#fld_browser')[0]
    		   window.frames['fld_browser'].window.frames['viewPane'].pathViewer.selectedPath;
        if(docHome){
            document.forms['dochome_form'].elements['<%=JVConst.DOCHOME_PARAM.value%>'].value = docHome;
         //dijit.registry.byId('<%=JVConst.DOCHOME_PARAM.value%>').setValue(docHome);
        }
    },
    
    currentDochome : '<%=currentDochome%>',
    
    removeDochomeOption : function(optId) {
        var dochomeObj = dijit.byId('dochome');
        dochomeObj.store.remove(optId);
        if(optId == this.currentDochome) {
        	dochomeObj.set('displayedValue', '');
        }else{
            dochomeObj.set('displayedValue', this.currentDochome);
        }
        $.get("<%=context%>/view?<%=JVConst.DOCHOME_OPTS_REMOVE.value%>=" + encodeURIComponent(optId))        
    }
    
};})(); //End Viewer

dojo.ready(function(){
	    Viewer.init();
    if('<%=errorType%>'.length){
        $('#error_message').html('<p><%=errorMsg%></p>');
        error_alert.show();
        return;
    }
    with(document.getElementsByTagName('iframe')) {
        packageListFrame.src = javadoc_home + '/overview-frame.html';
        packageFrame_0.src = javadoc_home + '/allclasses-frame.html';
        classFrame_0.src = javadoc_home + '/overview-summary.html'; 
        
        $(classFrame).bind('load', function(){
            var tab = Viewer.handleNewContentPane(this, Viewer.classContainer);
            if(tab){
                var iframe = tab.domNode.childNodes[0];
                $(iframe).bind('load', Viewer.setSelectedTabLoadEvent);
            }
        });

        $(classFrame_0).bind('load', Viewer.setSelectedTabLoadEvent);

        $(packageFrame).bind('load', function(){
            var pane = Viewer.handleNewContentPane(this, Viewer.pkgContainer);
            if(pane){
                pane.set('title', Viewer.Pane.doTitlePane(pane.title, pane.id) );
            }
        }); 
    }
});
</script>
</head>
<body class="claro">
<iframe name="packageFrame" id="packageFrame" style="display:none"></iframe>
<iframe name="classFrame" id="classFrame" style="display:none"></iframe>
<!-- Top Pane Content -->
<div style="display:none" id="javadoc_home_form">
   <form name="dochome_form" id="dochome_form" style="padding:1px;margin:0" class="javadoc_box" method="GET" action="<%=context%><%=viewUrl%>"> 
     <label for="<%=JVConst.DOCHOME_PARAM.value%>">Javadoc Home:</label>
     <!--input type="text" name="dochome" id="dochome" value="" class="text_box" /-->
     
     <div style="display:none" data-dojo-type="dojo/store/Memory" data-dojo-id="dochome_opt" 
       <%if(docHomeOpts != null){%>data-dojo-props='data:<%=docHomeOpts%>'<%}%>></div>
     
     <input id="<%=JVConst.DOCHOME_PARAM.value%>" name="<%=JVConst.DOCHOME_PARAM.value%>" value="<%=currentDochome%>" data-dojo-type="dijit/form/ComboBox" 
        data-dojo-props="placeholder:'path/to/javadoc/home',store:dochome_opt,searchAttr:'name'" class="text_box" style="width:35%;min-width:350px"/>
     <button type="submit">&nbsp;Load&nbsp;&raquo;&nbsp;</button>
     <button type="button" onclick="Viewer.openFolderBrowser()">Browse</button>
     <!--select multiple="multiple" id="<%=JVConst.DOCHOME_OPTS_REMOVE%>" name="<%=JVConst.DOCHOME_OPTS_REMOVE%>" style="display:none"></select-->
   </form>
</div>
<div style="display:none" id="ezopen_form">
   <form style="padding:1px;margin:0;float:right" class="search_pane" onsubmit="return Viewer.ezOpen(this.elements[0].value);">
     <label for="ezopen">Open:</label>
     <!--input id="ezopen" type="search" value="<%=searchBoxTxt%>" onfocus="{if(this.value=='<%=searchBoxTxt%>'){this.value=''}}" class="text_box"/-->
     <input id="ezopen" name="ezopen" data-dojo-type="dijit/form/TextBox" data-dojo-props="placeholder:'<%=searchBoxTxt%>'" class="text_box" />
     <input class="button" type="submit" value="&nbsp;Load&nbsp;&raquo;&nbsp;" />
   </form>
</div>
<!-- Error Box -->
<div data-dojo-type="dijit/Dialog" data-dojo-id="error_alert" title="Alert" style="background-color:#fff;font:12px arial">
  <div style="padding:10px" id="error_message"></div>
  <div style="float:right;font-size:11px;margin:5px">
    <button data-dojo-type="dijit/form/Button" type="button" data-dojo-props="onClick:function(){error_alert.hide();}" id="cancel">OK</button>
  </div>
</div>
<!-- Folder Browser Box -->
<div id="fld_browser_box" data-dojo-type="dijit/Dialog" data-dojo-id="fld_browser_box" title="Select Javadoc Home" style="background-color:#fff;font:12px arial">
  <iframe id="fld_browser" name="fld_browser" 
    style="border:none;width:100%;height:100%;margin:0;padding:0" marginwidth="0" marginheight="0" frameborder="0"></iframe>
  <div style="float:right">
    <button data-dojo-type="dijit/form/Button" type="button" id="fld_browse_ok" 
        data-dojo-props="onClick:function(){Viewer.setJavadocHome();fld_browser_box.hide();}">OK</button>
    <button data-dojo-type="dijit/form/Button" type="button" data-dojo-props="onClick:function(){fld_browser_box.hide();}" id="fld_browse_close">Close</button>
  </div>
</div>
</body>
<!-- #####  dijitReset dijitMenu dijitComboBoxMenu  ##### -->
<script type="text/javascript">
dojo.ready(function(){
	//Add the remove buttons to each option
    dojo.require("dojo.aspect");
    var dochomeObj = dijit.byId('dochome');
    dojo.aspect.after(dochomeObj, "openDropDown", function() {
        var opts = dochomeObj.dropDown.domNode.childNodes;
        for (var i=1; i<opts.length-1; i++) {
            var docUri = opts[i].innerHTML;
            opts[i].innerHTML = '<div style="display:table-cell;text-align:left">' + docUri + 
              '</div><div style="display:table-cell;text-align:right;width:100%;padding-right:5px;"><span class="dijitInline dijitTabCloseButton dijitTabCloseIcon" title="Remove" id="'+docUri+'" onclick="Viewer.removeDochomeOption(this.id)"><span class="dijitTabCloseText">[x]</span></span></div>'
        }
    });
});
//});
</script>
</html>