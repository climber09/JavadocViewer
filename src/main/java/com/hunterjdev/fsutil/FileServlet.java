package com.hunterjdev.fsutil;

/*
 * This work is licensed under the Common Public Attribution License 
 * Version 1.0 (CPAL-1.0). To view a copy of this license, visit 
 * http://opensource.org/licenses/CPAL-1.0.
 * 
 */

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

//import weblogic.servlet.annotation.WLServlet;

/**
 * Used as a file server for local files that are outside of the application context.
 * 
 * @author James Hunter
 * 
 */
@WebServlet(name="FileServlet", urlPatterns={"/file"})
//@WLServlet(name="/FileServlet", mapping={"/file"})
public class FileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    public static final String ABS_FILE_PATH = "absolute.file.path";
    public static final String FILE_SERVE_URI = "/file";

    /**
     * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
     */
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String filePath = (String)request.getAttribute(ABS_FILE_PATH);
        
        if (filePath != null ) {
            this.serveFile(request, response, filePath);
        }
    }

    /**
     * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
     */
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        this.doGet(request, response);
    }
    
    protected void serveFile(HttpServletRequest request, HttpServletResponse response, String filePath) throws IOException {
        String fileExt = filePath.substring(filePath.lastIndexOf('.') + 1);

        if (fileExt.matches("gif|png|jpg|jpeg|bmp")) {
            response.setContentType("image/".concat(fileExt));

            int length = -1;
            int bufferSize = 1024 * 2;
            byte[] buffer = new byte[bufferSize];

            try(BufferedInputStream in =
                    new BufferedInputStream( new FileInputStream(filePath) )) {
                //                      SeekableByteChannel in = Files.newByteChannel(Paths.get(filePath))) {
                ServletOutputStream out = response.getOutputStream();
                while ((length = in.read(buffer)) != -1) {
                    out.write(buffer, 0, length);
                }
                in.close();
                out.close();
            }
        }
        else {
            if (fileExt.matches("htm|html")) {
                response.setContentType("text/html");
            } else if (fileExt.equals("css")) {
                response.setContentType("text/css");
            } else if (fileExt.equals("js")) {
                response.setContentType("application/x-javascript");
            }
            try(BufferedReader reader =  
                    Files.newBufferedReader(
                            Paths.get(filePath), Charset.defaultCharset())) {
                //                          new BufferedReader( new FileReader(filePath) )){

                PrintWriter writer = response.getWriter();
                String line = null;

                while ((line = reader.readLine()) != null) {
                    writer.println(line);
                }
                reader.close();
                writer.close();
            }
        }
    }

}
