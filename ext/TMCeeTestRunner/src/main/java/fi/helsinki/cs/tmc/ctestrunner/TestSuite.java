/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package fi.helsinki.cs.tmc.ctestrunner;

/**
 *
 * @author rase
 */
public class TestSuite {
    private String name;
    private String[] points;
    
    public TestSuite(String name) {
        this.name = name;
    }
    
    public TestSuite(String name, String[] points) {
        this(name);
        this.points = points;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String[] getPoints() {
        return points;
    }

    public void setPoints(String[] points) {
        this.points = points;
    }
    
}