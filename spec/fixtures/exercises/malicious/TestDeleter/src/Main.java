import java.io.File;

public class Main {
    public static void theMethod() throws Exception {
        delete("build/test/classes/ATest.class");
        delete("build/test/classes/BTest.class");
        delete("test/ATest.java");
        delete("test/BTest.java");
    }
    private static void delete(String path) {
        if (!new File(path).delete()) {
            throw new RuntimeException("Failed to delete " + path);
        }
    }
}
