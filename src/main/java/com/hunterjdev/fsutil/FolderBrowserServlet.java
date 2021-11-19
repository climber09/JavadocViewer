package com.hunterjdev.fsutil;

/*
 * This work is licensed under the Common Public Attribution License 
 * Version 1.0 (CPAL-1.0). To view a copy of this license, visit 
 * http://opensource.org/licenses/CPAL-1.0.
 * 
 */

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

//import weblogic.servlet.annotation.WLServlet;

/**
 * Used to support the functionality of a typical "Browse for Folder" widget.
 * 
 * @author James Hunter
 * 
 */
@WebServlet(name="FolderBrowserServlet", urlPatterns={"/files"})
//@WLServlet(name="FolderBrowserServlet", mapping={"/files"})
public class FolderBrowserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    public enum FBConst {
        
        VIEW_DIR_CHOOSER("/dirChooser.jsp"),
        VIEW_DIR_CONTENTS("/dirContents.jsp"),
        DIR_CONTENTS("directory.contents");
        
        public final String value;
        
        FBConst(String value) {
            this.value = value;
        }
    }
//    public static final String DIR_CONTENTS = "directory.contents";

    /**
     * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
     */
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        String pathParam = request.getParameter("path");

        if (pathParam == null) {
            RequestDispatcher dispatch = 
                request.getRequestDispatcher( response.encodeURL(FBConst.VIEW_DIR_CHOOSER.value) );
            dispatch.forward(request, response);
            return;
        }
        pathParam = pathParam.trim();
        List<Path> pathList = new ArrayList<>();

        if (pathParam.equals("root")) {
            List<Path> drives = getDrives();
            if (drives.size() > 0) {
                for (Path aPath : drives) {
                    pathList.add(aPath);
                }
                Collections.sort(pathList);
                request.setAttribute(FBConst.DIR_CONTENTS.value, pathList);
                RequestDispatcher dispatch = 
                    request.getRequestDispatcher( response.encodeURL(FBConst.VIEW_DIR_CONTENTS.value) );
                dispatch.forward(request, response);
                return;
            }
            else {
                pathParam = "/";
            }
        }
        try (DirectoryStream<Path> dir = Files.newDirectoryStream(Paths.get(pathParam))) {
            for (Path pathEntry : dir) {
                if (Files.isDirectory(pathEntry)) {
                    pathList.add(pathEntry);
                }
            }
            Collections.sort(pathList);
        }
        request.setAttribute(FBConst.DIR_CONTENTS.value, pathList);
        RequestDispatcher dispatch = 
            request.getRequestDispatcher( response.encodeURL(FBConst.VIEW_DIR_CONTENTS.value) );
        dispatch.forward(request, response);
    }

    /**
     * Find drives by letter; for Windows, only.
     * @return
     * @throws ServletException
     */
    List<Path> getDrives() throws ServletException {
        List<Path> drives = new ArrayList<>();

        for (int i = 65; i < 91; i++) {
            char current = (char) i;
            String filePath = new StringBuilder().append(current).append(":\\").toString();
            Path currentPath = Paths.get(filePath);
            if (Files.exists(currentPath)) {
                drives.add(currentPath);
            }
        }
        return drives;
    }

    /**
     * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
     */
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    	this.doGet(request, response);
    }
    
}
