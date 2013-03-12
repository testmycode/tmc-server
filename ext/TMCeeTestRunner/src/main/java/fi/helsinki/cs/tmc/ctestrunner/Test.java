/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package fi.helsinki.cs.tmc.ctestrunner;

/**
 *
 * @author rase
 */
public class Test {
    public enum Status {
        PASSED, FAILED, RUNNING, NOT_STARTED
    }
    
    private String name;
    private Status status;
    private String message;
    private String[] pointNames;
    private String valgrindTrace;
    
    public Test(String name, Status status, String message, String[] points, String valgrindTrace) {
        this(name);
        this.status = status;
        this.message = message;
        this.pointNames = points;
        this.valgrindTrace = valgrindTrace;
    }

    public Test(String name, Status status, String message) {
        this(name, status, message, null, null);
    }

    public Test(Test t) {
        this(t.name, t.status, t.message, t.pointNames.clone(), t.valgrindTrace);
    }
    
    public Test(String name) {
        this.name = name;
        this.status = Status.NOT_STARTED;
    }

    public String serialize() {
        return "";
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Status getStatus() {
        return status;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String[] getPoints() {
        return this.pointNames;
    }

    public void setPoints(String[] points) {
        this.pointNames = points;
    }

    public String getValgrindTrace() {
        return valgrindTrace;
    }

    public void setValgrindTrace(String valgrindTrace) {
        this.valgrindTrace = valgrindTrace;
    }
}