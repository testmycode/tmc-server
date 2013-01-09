
import fi.helsinki.cs.tmc.edutestutils.Points;
import org.junit.Test;
import static org.junit.Assert.*;
import sun.tools.native2ascii.Main; // Requires tools.jar

@Points("toolsjar")
public class SimpleTest {
    @Test
    public void testToolsJar() throws Exception {
        Main native2AsciiMain = new Main();
    }
}
