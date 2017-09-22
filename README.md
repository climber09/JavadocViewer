----------------
### JavadocViewer

An enhanced Web UI for viewing Javadoc pages more efficiently and
productively.

##### Features:
* Multiple tab-style display of pages within the class frame.
* Multiple accordion-style display of pages within the package frame.
* Loading of Javadocs from local and remote sources.
* Quick location of package and class pages without the usual search and scroll.
* Runs as a standard JEE Web application on any JEE Web server

Check out the [live demo](http://demo-javadoc-viewer.a3c1.starter-us-west-1.openshiftapps.com/JavadocViewer).

##### Build:
Simply run the Ant build script to build JavadocViewer.war, wherever
you unzip and store the distribution files. Then deploy the war to your
JEE Web server.

> `$ cd /../<YOUR-JAVADOCVIEWER-HOME>/`
> `$ ant`

Optionally, you can specify a `server.deploy.dir` value in
build.properties and run the Ant deploy task, which will build
JavadocViewer.war and copy it to the deployment directory specified
in build.properties.

> `$ ant deploy`

##### Usage:
When you first open the JavadocViewer application in a web browser you
will need to enter the location of the Javadoc sources you want to view
in the location widget in the top left corner. Click the "Browse"
button to open the folder browser and locate the local folder containing
the main index.html, or manually enter the file path into the location
box. To load Javadocs from a remote source, enter the complete URL in
the location box (e.g., `http://junit.sourceforge.net/javadoc/`).

In the top right corner you will see another location widget, which can
be used to quickly open any package or class page within the class
frame. The fully qualified java class name or package must be entered
accurately (e.g., `java.lang.String` or `javax.xml.parsers`).


Copyright &copy; 2014 James P Hunter
