
import fi.helsinki.cs.tmc.testrunner.Points;
import org.junit.Test;
import static org.junit.Assert.*;

public class ATest {
    @Test
    @Points("test1")
    public void test1() throws Exception {
        Main.theMethod();
    }
}
