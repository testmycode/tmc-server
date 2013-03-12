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
    private String name;
    private String result;
    private String message;
    private String[] points;
    private String valgrindTrace;

    public Test(String name, String result, String message, String[] points, String valgrindTrace) {
        this(name);
        this.result = result;
        this.message = message;
        this.points = points;
        this.valgrindTrace = valgrindTrace;
    }

    public Test(String name, String result, String message) {
        this(name, result, message, null, null);
    }

    public Test(Test t) {
        this(t.name, t.result, t.message, t.points.clone(), t.valgrindTrace);
    }
    
    public Test(String name) {
        this.name = name;
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

    public String getResult() {
        return result;
    }

    public void setResult(String result) {
        this.result = result;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String[] getPoints() {
        return this.points;
    }

    public void setPoints(String[] points) {
        this.points = points;
    }

    public String getValgrindTrace() {
        return valgrindTrace;
    }

    public void setValgrindTrace(String valgrindTrace) {
        this.valgrindTrace = valgrindTrace;
    }
}