import java.io.File;

public class Main {
    public static void theMethod() throws Exception {
        delete("classes/test/ATest.class");
        delete("classes/test/BTest.class");
        delete("test/ATest.java");
        delete("test/BTest.java");
    }
    private static void delete(String path) {
        if (!new File(path).delete()) {
            throw new RuntimeException("Failed to delete " + path);
        }
    }
}
