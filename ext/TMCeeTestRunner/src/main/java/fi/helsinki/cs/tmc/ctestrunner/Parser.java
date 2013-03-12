package fi.helsinki.cs.tmc.ctestrunner;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Scanner;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;
import org.xml.sax.SAXException;





/**
 * 
 * @author rase
 */
public class Parser {
    private File testOutput;
    private File testPoints;
    private File valgrindTraces;
    private HashMap<String, Test> tests = new HashMap<String, Test>();
    private HashMap<String, TestSuite> testSuites = new HashMap<String, TestSuite>();
    
    public Parser(File testOutput, File testPoints, File valgrindTraces) {
        this.testOutput = testOutput;
        this.testPoints = testPoints;
        this.valgrindTraces = valgrindTraces;
    }
    
    public TestList getTests() {
        TestList testList = new TestList();
        for (Test test : tests.values()) {
            testList.add(test);
        }
        return testList;
    }
    
    public void parse() {
        try {
            tests = parseTests(testOutput);
            testSuites = parseTestSuites(testOutput);
            addPoints(testPoints, tests, testSuites);
            addValgrindOutput(valgrindTraces, new ArrayList<Test>(tests.values()));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    private HashMap<String, TestSuite> parseTestSuites(File testOutput) throws ParserConfigurationException, SAXException, IOException {
        DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
        DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
        Document doc = dBuilder.parse(testOutput);

        doc.getDocumentElement().normalize();
        
        NodeList nodeList = doc.getElementsByTagName("suite");
        HashMap<String, TestSuite> suites = new HashMap<String, TestSuite>();
        for (int i = 0; i < nodeList.getLength(); i++) {
            Element node = (Element) nodeList.item(i);
            String name = node.getElementsByTagName("title").item(0).getTextContent();
            suites.put(name, new TestSuite(name));
        }
        return suites;
    }
    
    private HashMap<String, Test> parseTests(File testOutput) throws ParserConfigurationException, SAXException, IOException {
        DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
        DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
        Document doc = dBuilder.parse(testOutput);

        doc.getDocumentElement().normalize();

        NodeList nodeList = doc.getElementsByTagName("test");
        HashMap<String, Test> tests = new HashMap<String, Test>();
        for (int i = 0; i < nodeList.getLength(); i++) {
            Element node = (Element) nodeList.item(i);
            String result = node.getAttribute("result");
            String name = node.getElementsByTagName("description").item(0).getTextContent();
            String message = node.getElementsByTagName("message").item(0).getTextContent();
            tests.put(name, new Test(name, result, message));
        }

        return tests;
    }

    private void addPoints(File testPoints, HashMap<String, Test> tests, HashMap<String, TestSuite> testSuites) throws FileNotFoundException {
        Scanner scanner = new Scanner(testPoints, "UTF-8");
        while (scanner.hasNextLine()) {
            String[] splitLine = scanner.nextLine().split(" ");
            if (splitLine[0].equals("[test]")) {
                String name = splitLine[1];
                Test associatedTest = tests.get(name);
                if (associatedTest != null) {
                    String[] pointsArray = new String[splitLine.length - 2];
                    System.arraycopy(splitLine, 2, pointsArray, 0, pointsArray.length);                    
                    associatedTest.setPoints(pointsArray);
                }
            } else if (splitLine[0].equals("[suite]")) {
                String name = splitLine[1];
                String[] pointsArray = new String[splitLine.length - 2];
                System.arraycopy(splitLine, 2, pointsArray, 0, pointsArray.length); 
                TestSuite associatedSuite = testSuites.get(name);
                if (associatedSuite != null) {
                    associatedSuite.setPoints(pointsArray);
                }
            } else {
                // Do nothing at least of for now
            }

        }
        scanner.close();
    }

    private void addValgrindOutput(File outputFile, ArrayList<Test> tests) throws FileNotFoundException {
        Scanner scanner = new Scanner(outputFile, "UTF-8");
        String parentOutput = ""; // Contains total amount of memory used and such things. Useful if we later want to add support for testing memory usage
        String[] outputs = new String[tests.size()];
        int[] pids = new int[tests.size()];
        for (int i = 0; i < outputs.length; i++) {
            outputs[i] = "";
        }

        String line = scanner.nextLine();
        int firstPID = parsePID(line);
        parentOutput += "\n" + line;
        while (scanner.hasNextLine()) {
            line = scanner.nextLine();
            int pid = parsePID(line);
            if (pid == -1) {
                continue;
            }
            if (pid == firstPID) {
                parentOutput += "\n" + line;
            } else {
                outputs[findIndex(pid, pids)] += "\n" + line;
            }
        }
        scanner.close();

        for (int i = 0; i < outputs.length; i++) {
            tests.get(i).setValgrindTrace(outputs[i]);
        }
    }
    
    private int findIndex(int pid, int[] pids) {
        for (int i = 0; i < pids.length; i++) {
            if (pids[i] == pid) return i;
            if (pids[i] == 0) {
                pids[i] = pid;
                return i;
            }
        }
        return 0;
    }

    private int parsePID(String line) {
        try {
            return Integer.parseInt(line.split(" ")[0].replaceAll("(==|--)", ""));
        } catch (Exception e) {
            return -1;
        }
    }
}