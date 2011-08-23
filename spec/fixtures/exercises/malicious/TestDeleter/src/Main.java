import java.io.File;

public class Main {
    public static void theMethod() throws Exception {
        new File("build/test/classes/ATest.class").delete();
        new File("build/test/classes/BTest.class").delete();
        new File("test/ATest.java").delete();
        new File("test/BTest.java").delete();
    }
    private void delete(String path) {
        if (!new File(path).delete()) {
            throw new RuntimeException("Failed to delete " + path);
        }
    }
}
