package net.sourceforge.hunterj.javadocViewer;

/*
 * This work is licensed under the Common Public Attribution License 
 * Version 1.0 (CPAL-1.0). To view a copy of this license, visit 
 * http://opensource.org/licenses/CPAL-1.0.
 * 
 */
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.BufferedInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.net.URL;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.regex.Pattern;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import net.sourceforge.hunterj.fsutil.FileServlet;

import org.apache.commons.lang.StringUtils;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

//import weblogic.servlet.annotation.WLServlet;

/**
 * Servlet implementation class JavadocViewerServlet
 */
@WebServlet(name="JavadocViewerServlet", urlPatterns={"/view/*"})
//@WLServlet (name="JavadocServlet", mapping={"/view/*"})
public class JavadocViewerServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    // This will be the same every time;
    private String saveFilePathStr;
    
    /**
     * String constants used throughout the application.
     * @author jim
     */
    public enum JVConst{
        DOCHOME_PARAM("dochome"), 
        DOCHOME_ATTR("javadoc.home"), 
        DOCHOME_URL_PART("javadoc_home"), 
        DOCHOME_ERROR("javadoc.home.error"),
        DOCHOME_SAVE_FILENAME(".dochome.json"),
        /** 
         * A JSON string, like, [{id:'1',name:'D:\\java\\docs\\jdk1.7\\api'},{id:'2',name:'D:\\java\\docs\\jee1.6'}] 
         */
        DOCHOME_OPTS("javadoc.home.options"),
        DOCHOME_OPTS_REMOVE("remove"),
        
        JAVADOC_OVERVIEW_PAGE("overview-frame.html"),
        JAVADOC_CLASSES_PAGE("allclasses-frame.html"),
        JAVADOC_SUMMARY_PAGE("overview-summary.html"),
        
        MAIN_JSP("/viewer.jsp"),
        ERROR_PAGE("/errorHandler.jsp");

        public final String value;
        JVConst(String value){
            this.value = value;
        }
        
        @Override public String toString(){
            return this.value;
        }
    }
    
    /**
     * 
     * @param value
     * @param id
     * @param json
     * @return
     * @throws JSONException
     */
    private int indexOfValue(String value, String id, JSONArray json) throws JSONException {
        for(int i = 0; i < json.length(); i++) {
            JSONObject jo = json.getJSONObject(i);
            if ( value.equals(jo.getString(id)) ) {
                return i;
            }
        }
        return -1;
    }
    
    /**
     * 
     * @param docHome
     * @param json
     */
    private void addNewJavadocHome(String docHome, JSONArray json) {
        JSONObject jo = new JSONObject();
        jo.put("id", docHome);
        jo.put("name", docHome);
        json.put(jo);
    }
    
    /**
     * 
     * @param session
     * @param docHome
     * @throws IOException
     */
    private void checkJavadocHome(HttpSession session, String docHome) throws IOException{
        /*
         * Condition 1: First time page loads, no saved options
         * Condition 2: Saved options exist; new option is not there
         * Condition 3: Saved options exist; new option is there;
         */
        String docHomeOpts = (String)session.getAttribute(JVConst.DOCHOME_OPTS.value);
        if (docHomeOpts == null) {
            docHomeOpts = this.getJavadocHomeOpts(Paths.get(this.saveFilePathStr));
        }
        if (docHomeOpts == null) {
            JSONArray json2save = new JSONArray();
            addNewJavadocHome(docHome, json2save);
            this.saveJavadocHomeOpts(json2save, session);
        }
        else{
            JSONArray json = new JSONArray(docHomeOpts);
            if (indexOfValue(docHome, "id", json) == -1) {
                JSONArray json2save = new JSONArray();
                addNewJavadocHome(docHome, json2save);
                for (int i = 0; i < json.length(); i++) {
                    json2save.put(json.get(i));
                }
                this.saveJavadocHomeOpts(json2save, session);
            }
            //otherwise, the option is in the list and nothing need be done.
        } 
    }
    
    /**
     * 
     * @param session
     * @param docHome
     * @throws IOException
     */
    private void removeJavadocHome(HttpSession session, String docHome) throws IOException {
        String docHomeOpts = (String)session.getAttribute(JVConst.DOCHOME_OPTS.value);
        if (docHomeOpts == null) {
            docHomeOpts = this.getJavadocHomeOpts(Paths.get(this.saveFilePathStr));
        }
        if (docHomeOpts != null) {
            try {
                JSONArray json = new JSONArray(docHomeOpts);
                int index = indexOfValue(docHome, "id", json);
                if (index != -1) {
                    json.remove(index);
                    session.setAttribute(JVConst.DOCHOME_ATTR.value, null);
                    this.saveJavadocHomeOpts(json, session);
                }
            } 
            catch (JSONException e) {
                throw new IOException(e);
            }
        }
    }
    
    /**
     * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
     */
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String toRemove = request.getParameter(JVConst.DOCHOME_OPTS_REMOVE.value);
        String realJavadocHome = request.getParameter(JVConst.DOCHOME_PARAM.value);

        if (StringUtils.isNotEmpty(toRemove)){
            this.removeJavadocHome(request.getSession(), toRemove);
            return;
        }
        if (StringUtils.isEmpty(realJavadocHome)) {
            realJavadocHome = (String)request.getSession().getAttribute(JVConst.DOCHOME_ATTR.value);
            if(StringUtils.isEmpty(realJavadocHome)) {
                request.setAttribute(JVConst.DOCHOME_ERROR.value, 
                        new FileNotFoundException("No javadoc home is selected."));
                this.dispatchToView(request, response);
                return;
            }
        } 
        // Check to see if the local file path is valid.
        if(! isRemoteResource(realJavadocHome) && Files.notExists(Paths.get(realJavadocHome) ) ) {
            request.setAttribute(JVConst.DOCHOME_ERROR.value, 
                    new FileNotFoundException("\"".concat(realJavadocHome).concat("\" is not a valid file path.")));
            this.dispatchToView(request, response);
            return;
        }
        
        // handle sub-requests by iframes for files, not under the servlet context
        String[] urlParts = request.getRequestURI().split(JVConst.DOCHOME_URL_PART.value);
        if (urlParts.length == 2 && realJavadocHome != null) {
            String filePath = realJavadocHome.concat(urlParts[1]);

            // Handle requests to remote servers
            if ( this.isRemoteResource(realJavadocHome) ) {
                this.doGetRemoteResource(response, filePath);
                return;
            }
            request.setAttribute(FileServlet.ABS_FILE_PATH, filePath);
            RequestDispatcher dispatch = 
                request.getRequestDispatcher( response.encodeURL( FileServlet.FILE_SERVE_URI ) );
            dispatch.forward(request, response);
            return;
        }
        // At this point the request is for the main viewer page and is probably correct/valid.
        this.checkJavadocHome(request.getSession(), realJavadocHome);
        request.getSession().setAttribute(JVConst.DOCHOME_ATTR.value, realJavadocHome);
        this.dispatchToView(request, response);
    }
    
    /**
     * 
     * @param response
     * @param url
     * @throws IOException
     */
    private void doGetRemoteResource(HttpServletResponse response, String url) throws IOException {
        URL remoteResource = new URL(url);
        try( BufferedInputStream in = 
                new BufferedInputStream( remoteResource.openStream() )){
            int length = -1;
            int bufferSize = 1024 * 2;
            byte[] buffer = new byte[bufferSize];
            
            ServletOutputStream out = response.getOutputStream();
            while ((length = in.read(buffer)) != -1) {
                out.write(buffer, 0, length);
            }
            in.close();
            out.close();
        }
    }
    
    /**
     * 
     * @param request
     * @param response
     * @throws IOException 
     * @throws ServletException 
     */
    private void dispatchToView(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        request.setAttribute(JVConst.DOCHOME_ATTR.value, 
                session.getAttribute(JVConst.DOCHOME_ATTR.value));
        String docHomeOpts = (String)request.getSession().getAttribute(JVConst.DOCHOME_OPTS.value);
        if (docHomeOpts == null) {
            docHomeOpts = this.getJavadocHomeOpts(Paths.get(this.saveFilePathStr));
            session.setAttribute(JVConst.DOCHOME_OPTS.value, docHomeOpts);
        }
        request.setAttribute(JVConst.DOCHOME_OPTS.value, docHomeOpts);
        RequestDispatcher dispatch = 
            request.getRequestDispatcher( response.encodeURL(JVConst.MAIN_JSP.value) );
        dispatch.forward(request, response);
    }

    /**
     * 
     * @param path
     * @return
     * @throws IOException
     */
    private synchronized String getJavadocHomeOpts(Path path) throws IOException{
//        String savedDochomeOpts = null;
//        if (Files.exists(path)) {
//            try(
//                  BufferedReader reader = new BufferedReader(new FileReader(path.toFile() ));
//                 /*BufferedReader reader = Files.newBufferedReader(path, Charset.defaultCharset())*/
//                ) {
//                savedDochomeOpts = reader.readLine();
//                reader.close();
//            }
//        }
//        return savedDochomeOpts;
//      This hack is just for the online demo
        return "[{\"name\":\"http://junit.org/junit4/javadoc/latest/\",\"id\":\"http://junit.org/junit4/javadoc/latest/\"},{\"name\":\"https://docs.oracle.com/javaee/6/api/\",\"id\":\"https://docs.oracle.com/javaee/6/api/\"},{\"name\":\"https://docs.oracle.com/javase/7/docs/api/\",\"id\":\"https://docs.oracle.com/javase/7/docs/api/\"},{\"name\":\"https://docs.oracle.com/javaee/7/api/\",\"id\":\"https://docs.oracle.com/javaee/7/api/\"},{\"name\":\"https://docs.oracle.com/javase/8/docs/api/\",\"id\":\"https://docs.oracle.com/javase/8/docs/api/\"}]";
    }
    
    /**
     * 
     * @param json
     * @param session
     * @throws IOException
     */
    private void saveJavadocHomeOpts(JSONArray json, HttpSession session) throws IOException {
        String jsonStr = json.toString();
        this.writeJavadocHomeOpts(jsonStr);
        session.setAttribute(JVConst.DOCHOME_OPTS.value, jsonStr);
    }
    
    /**
     * 
     * @param options
     * @throws IOException
     */
    private synchronized void writeJavadocHomeOpts(String options) throws IOException {
//  Disabled for online demo        
//        try (BufferedWriter writer = Files.newBufferedWriter(
//                Paths.get(this.saveFilePathStr), Charset.defaultCharset())) {
//            writer.write(options);
//            writer.close();
//        }
    }
    
    /**
     * 
     */
    private final static Pattern urlPattern = Pattern.compile("^http[s]?://.*");
    
    /**
     * Tests for the presence of 'http://' or 'https://' at the beginning 
     * of a string.
     * @param path the string to be tested
     * @return 
     */
    private boolean isRemoteResource(String path) {
        return urlPattern.matcher(path).matches();
    }
    
    /**
     * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
     */
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        doGet(request, response);
    }

    @Override
    public void init() throws ServletException {
        this.saveFilePathStr = System.getProperty("user.home")
                .concat(System.getProperty("file.separator"))
                .concat(JVConst.DOCHOME_SAVE_FILENAME.value);
    }

}
