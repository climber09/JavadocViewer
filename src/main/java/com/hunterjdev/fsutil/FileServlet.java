package com.hunterjdev.fsutil;

/*
 * This work is licensed under the Common Public Attribution License
 * Version 1.0 (CPAL-1.0). To view a copy of this license, visit
 * http://opensource.org/licenses/CPAL-1.0.
 *
 */

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

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
public class FileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    public static final String ABS_FILE_PATH = "absolute.file.path";
    public static final String FILE_SERVE_URI = "/file";

    /**
     * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
     */
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String filePath = (String)request.getAttribute(ABS_FILE_PATH);
        if (filePath != null) {
            File file = new File(filePath);
            if (file.exists() && file.canRead()) {
                this.serveFile(request, response, file);
            }
        }
    }

    /**
     * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
     */
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        this.doGet(request, response);
    }

    protected void serveFile(HttpServletRequest request, HttpServletResponse response, File file) throws IOException {
        String fileName = file.getName();
        String fileExt = fileName.substring(fileName.lastIndexOf('.') + 1);

        switch (fileExt) {
            case "gif": case "png": case "jpg": case "jpeg": case "bmp":
                response.setContentType("image/".concat(fileExt));
                break;
            case "zip":
                response.setContentType("application/zip");
                break;
            case "woff":
                response.setContentType("font/woff");
                break;
            case "woff2":
                response.setContentType("font/woff2");
                break;
            case "css":
                response.setContentType("text/css;charset=utf-8");
                break;
            case "js":
                response.setContentType("text/javascript;charset=utf-8");
                break;
            case "txt":
                response.setContentType("text/plain;charset=utf-8");
                break;
            default:
                response.setContentType("text/html;charset=utf-8");
        }

        int length = -1;
        int bufferSize = 1024 * 2;
        byte[] buffer = new byte[bufferSize];

        try( BufferedInputStream in = new BufferedInputStream( new FileInputStream(file) );
             ServletOutputStream out = response.getOutputStream(); ) {
            while ((length = in.read(buffer)) != -1) {
                out.write(buffer, 0, length);
            }
            in.close();
            out.close();
        }
    }

}
